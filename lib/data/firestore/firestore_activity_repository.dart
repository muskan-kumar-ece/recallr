import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/activity/models/activity_models.dart';
import '../../repositories/activity_repository.dart';

/// Production Firestore-backed repository for chronological Activity timeline.
/// Scoped under `users/{uid}/activities/{activityId}`.
class FirestoreActivityRepository implements ActivityRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestoreActivityRepository({
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

  CollectionReference<Map<String, dynamic>> get _activityCollection {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('activities');
  }

  @override
  Stream<List<ActivityItem>> streamActivities({
    String? query,
    ActivityFilter? filter,
    int limit = 100,
  }) {
    try {
      Query<Map<String, dynamic>> baseQuery = _activityCollection;
      if (limit > 0) {
        baseQuery = baseQuery.limit(limit);
      }
      return baseQuery.snapshots().map((snapshot) {
        var activities = snapshot.docs.map((doc) => ActivityItem.fromFirestore(doc)).toList();

        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          activities = activities.where((a) {
            final matchesTitle = a.title.toLowerCase().contains(q);
            final matchesSummary = a.summary.toLowerCase().contains(q);
            final matchesPerson = a.personName?.toLowerCase().contains(q) ?? false;
            final matchesCompany = a.companyName?.toLowerCase().contains(q) ?? false;
            return matchesTitle || matchesSummary || matchesPerson || matchesCompany;
          }).toList();
        }

        if (filter != null && filter != ActivityFilter.all) {
          activities = activities.where((a) => filter.matches(a.type)).toList();
        }

        return activities;
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<ActivityItem?> getActivity(String id) async {
    try {
      final doc = await _activityCollection.doc(id).get();
      if (!doc.exists) return null;
      return ActivityItem.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> addActivity(ActivityItem activity) async {
    try {
      final docRef = activity.id.isNotEmpty ? _activityCollection.doc(activity.id) : _activityCollection.doc();
      final map = activity.toMap()
        ..['id'] = docRef.id
        ..['userId'] = _uid
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(map);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> deleteActivity(String id) async {
    try {
      await _activityCollection.doc(id).delete();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}