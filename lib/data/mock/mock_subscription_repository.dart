import 'dart:async';
import '../../features/subscription/models/subscription_models.dart';
import '../../repositories/subscription_repository.dart';

/// In-memory mock implementation of SubscriptionRepository for tests and offline preview.
class MockSubscriptionRepository implements SubscriptionRepository {
  UserSubscription _current;
  final StreamController<UserSubscription> _controller = StreamController<UserSubscription>.broadcast();
  final List<CreditLedgerEntry> ledger = [];

  MockSubscriptionRepository({UserSubscription? initial})
      : _current = initial ?? UserSubscription.defaultStarter();

  @override
  Stream<UserSubscription> streamSubscription() {
    return _controller.stream.transform(
      StreamTransformer<UserSubscription, UserSubscription>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    ).asBroadcastStream(
      onListen: (sub) {
        _controller.add(_current);
      },
    );
  }

  @override
  Future<UserSubscription> getSubscription() async {
    return _current;
  }

  @override
  Future<void> updateStorageUsage({required int deltaBytes}) async {
    final newBytes = (_current.storageUsedBytes + deltaBytes).clamp(0, 1000000000000);
    _current = _current.copyWith(
      storageUsedBytes: newBytes,
      updatedAt: DateTime.now(),
    );
    _controller.add(_current);
  }

  @override
  Future<bool> consumeCredit({
    required String reason,
    int amount = 1,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return true;
    if (_current.totalAvailableCredits < amount) {
      return false;
    }

    int newMonthlyUsed = _current.monthlyCreditsUsed;
    int newPurchased = _current.purchasedCredits;
    int needed = amount;

    final availableMonthly = _current.remainingMonthlyCredits;
    if (availableMonthly > 0) {
      final consumeMonthly = availableMonthly >= needed ? needed : availableMonthly;
      newMonthlyUsed += consumeMonthly;
      needed -= consumeMonthly;
    }

    if (needed > 0) {
      newPurchased = (newPurchased - needed).clamp(0, 10000000);
    }

    _current = _current.copyWith(
      monthlyCreditsUsed: newMonthlyUsed,
      purchasedCredits: newPurchased,
      updatedAt: DateTime.now(),
    );

    ledger.add(CreditLedgerEntry(
      id: 'mock_tx_${ledger.length + 1}',
      timestamp: DateTime.now(),
      type: 'debit',
      amount: amount,
      reason: reason,
      metadata: metadata,
    ));

    _controller.add(_current);
    return true;
  }

  @override
  Future<void> purchaseCreditPack(CreditPack pack) async {
    _current = _current.copyWith(
      purchasedCredits: _current.purchasedCredits + pack.credits,
      updatedAt: DateTime.now(),
    );

    ledger.add(CreditLedgerEntry(
      id: 'mock_tx_${ledger.length + 1}',
      timestamp: DateTime.now(),
      type: 'credit',
      amount: pack.credits,
      reason: 'pack_purchase',
      metadata: {
        'packId': pack.id,
        'priceInr': pack.priceInr,
        'priceUsd': pack.priceUsd,
      },
    ));

    _controller.add(_current);
  }

  @override
  Future<void> upgradeTier(SubscriptionTier tier, {bool annual = false}) async {
    final now = DateTime.now();
    final periodEnd = annual ? now.add(const Duration(days: 365)) : now.add(const Duration(days: 30));

    _current = _current.copyWith(
      tier: tier,
      status: 'active',
      storageLimitBytes: tier.storageLimitBytes,
      monthlyCreditsTotal: tier.monthlyCreditsTotal,
      monthlyCreditsUsed: 0,
      currentPeriodStart: now,
      currentPeriodEnd: periodEnd,
      productId: '${tier.id}_${annual ? 'annual' : 'monthly'}',
      updatedAt: now,
    );

    _controller.add(_current);
  }

  @override
  Future<void> setCurrency(String currency) async {
    _current = _current.copyWith(
      currency: currency,
      updatedAt: DateTime.now(),
    );
    _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}
