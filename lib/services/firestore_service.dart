import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sync user profile to Firestore
  Future<void> syncUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(appUser.toMap());
    } else {
      await docRef.update({
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      });
    }
  }

  // Stream current user profile
  Stream<AppUser?> getUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  // Stream items for a user
  Stream<List<RecallItem>> streamUserItems(String userId) {
    return _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => RecallItem.fromFirestore(doc))
          .toList();
      // Client-side sort to avoid requiring composite indexes during development
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  // Add new item
  Future<void> addItem({
    required String userId,
    required String title,
    required String description,
  }) async {
    final docRef = _firestore.collection('items').doc();
    final item = RecallItem(
      id: docRef.id,
      userId: userId,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    await docRef.set(item.toMap());
  }

  // Toggle item completion
  Future<void> toggleItemStatus(String itemId, bool currentStatus) async {
    await _firestore.collection('items').doc(itemId).update({
      'isCompleted': !currentStatus,
    });
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
}