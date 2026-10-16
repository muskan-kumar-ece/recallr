import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/capture/models/capture_models.dart';
import '../../repositories/capture_repository.dart';

/// Production Firestore-backed repository for Omni-Capture Hub.
/// Scoped under `users/{uid}/captures/{captureId}`.
class FirestoreCaptureRepository implements CaptureRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestoreCaptureRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String get _uid {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw RecallrDataException.unauthenticated();
      }
      return user.uid;
    } on RecallrDataException {
      rethrow;
    } catch (_) {
      throw RecallrDataException.unauthenticated();
    }
  }

  CollectionReference<Map<String, dynamic>> get _captureCollection {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('captures');
  }

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) {
    try {
      return _captureCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => CaptureItem.fromFirestore(doc)).toList());
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async {
    try {
      final docRef = item.id.isNotEmpty ? _captureCollection.doc(item.id) : _captureCollection.doc();
      final map = item.toMap()
        ..['id'] = docRef.id
        ..['userId'] = _uid
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(map);
      return item.copyWith(id: docRef.id, userId: _uid);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<CaptureItem?> getCapture(String id) async {
    try {
      final doc = await _captureCollection.doc(id).get();
      if (!doc.exists) return null;
      return CaptureItem.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> deleteCapture(String id) async {
    try {
      await _captureCollection.doc(id).delete();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}