import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/subscription/models/subscription_models.dart';
import '../../repositories/subscription_repository.dart';

/// Production Firestore-backed implementation of SubscriptionRepository.
/// Stores subscription state at `/users/{uid}/subscription/current` and
/// credit history in `/users/{uid}/credit_ledger/{ledgerId}`.
class FirestoreSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestoreSubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw RecallrDataException.unauthenticated();
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _subDocRef {
    return _firestore.collection('users').doc(_uid).collection('subscription').doc('current');
  }

  CollectionReference<Map<String, dynamic>> get _ledgerCollectionRef {
    return _firestore.collection('users').doc(_uid).collection('credit_ledger');
  }

  @override
  Stream<UserSubscription> streamSubscription() {
    return _subDocRef.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) {
        // Initialize default starter subscription
        final defaultSub = UserSubscription.defaultStarter();
        await _subDocRef.set(defaultSub.toMap(), SetOptions(merge: true));
        return defaultSub;
      }
      return UserSubscription.fromFirestore(snapshot);
    });
  }

  @override
  Future<UserSubscription> getSubscription() async {
    final snapshot = await _subDocRef.get();
    if (!snapshot.exists) {
      final defaultSub = UserSubscription.defaultStarter();
      await _subDocRef.set(defaultSub.toMap(), SetOptions(merge: true));
      return defaultSub;
    }
    return UserSubscription.fromFirestore(snapshot);
  }

  @override
  Future<void> updateStorageUsage({required int deltaBytes}) async {
    final sub = await getSubscription();
    final newBytes = (sub.storageUsedBytes + deltaBytes).clamp(0, 1000000000000);
    await _subDocRef.update({
      'storageUsedBytes': newBytes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> consumeCredit({
    required String reason,
    int amount = 1,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return true;

    return _firestore.runTransaction<bool>((tx) async {
      final snapshot = await tx.get(_subDocRef);
      UserSubscription sub;
      if (!snapshot.exists) {
        sub = UserSubscription.defaultStarter();
        tx.set(_subDocRef, sub.toMap());
      } else {
        sub = UserSubscription.fromFirestore(snapshot);
      }

      if (sub.totalAvailableCredits < amount) {
        return false;
      }

      int newMonthlyUsed = sub.monthlyCreditsUsed;
      int newPurchased = sub.purchasedCredits;
      int needed = amount;

      // First consume from monthly plan allowance
      final availableMonthly = sub.remainingMonthlyCredits;
      if (availableMonthly > 0) {
        final consumeMonthly = availableMonthly >= needed ? needed : availableMonthly;
        newMonthlyUsed += consumeMonthly;
        needed -= consumeMonthly;
      }

      // Remaining comes from non-expiring purchased credits
      if (needed > 0) {
        newPurchased = (newPurchased - needed).clamp(0, 10000000);
      }

      tx.update(_subDocRef, {
        'monthlyCreditsUsed': newMonthlyUsed,
        'purchasedCredits': newPurchased,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Append to credit ledger
      final ledgerDoc = _ledgerCollectionRef.doc();
      final entry = CreditLedgerEntry(
        id: ledgerDoc.id,
        timestamp: DateTime.now(),
        type: 'debit',
        amount: amount,
        reason: reason,
        metadata: metadata,
      );
      tx.set(ledgerDoc, entry.toMap());

      return true;
    });
  }

  @override
  Future<void> purchaseCreditPack(CreditPack pack) async {
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(_subDocRef);
      UserSubscription sub;
      if (!snapshot.exists) {
        sub = UserSubscription.defaultStarter();
        tx.set(_subDocRef, sub.toMap());
      } else {
        sub = UserSubscription.fromFirestore(snapshot);
      }

      final updatedPurchased = sub.purchasedCredits + pack.credits;
      tx.update(_subDocRef, {
        'purchasedCredits': updatedPurchased,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final ledgerDoc = _ledgerCollectionRef.doc();
      final entry = CreditLedgerEntry(
        id: ledgerDoc.id,
        timestamp: DateTime.now(),
        type: 'credit',
        amount: pack.credits,
        reason: 'pack_purchase',
        metadata: {
          'packId': pack.id,
          'priceInr': pack.priceInr,
          'priceUsd': pack.priceUsd,
        },
      );
      tx.set(ledgerDoc, entry.toMap());
    });
  }

  @override
  Future<void> upgradeTier(SubscriptionTier tier, {bool annual = false}) async {
    final now = DateTime.now();
    final periodEnd = annual ? now.add(const Duration(days: 365)) : now.add(const Duration(days: 30));

    await _subDocRef.set({
      'tier': tier.id,
      'status': 'active',
      'storageLimitBytes': tier.storageLimitBytes,
      'monthlyCreditsTotal': tier.monthlyCreditsTotal,
      'monthlyCreditsUsed': 0, // Reset allowance for new upgraded tier cycle
      'currentPeriodStart': Timestamp.fromDate(now),
      'currentPeriodEnd': Timestamp.fromDate(periodEnd),
      'billingProvider': 'mock',
      'productId': '${tier.id}_${annual ? 'annual' : 'monthly'}',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setCurrency(String currency) async {
    await _subDocRef.set({
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
