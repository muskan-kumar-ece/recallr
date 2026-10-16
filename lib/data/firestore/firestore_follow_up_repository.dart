import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../repositories/follow_up_repository.dart';

/// Production Firestore-backed repository for Follow-ups & Relationship Commitments.
/// Scoped under `users/{uid}/follow_ups/{followUpId}`.
class FirestoreFollowUpRepository implements FollowUpRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestoreFollowUpRepository({
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

  CollectionReference<Map<String, dynamic>> get _followUpsCollection {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('follow_ups');
  }

  @override
  Stream<List<FollowUpItem>> streamFollowUps({
    String? query,
    FollowUpFilter? filter,
    int limit = 100,
  }) {
    try {
      Query<Map<String, dynamic>> baseQuery = _followUpsCollection;
      if (limit > 0) {
        baseQuery = baseQuery.limit(limit);
      }
      return baseQuery.snapshots().map((snapshot) {
        var followUps = snapshot.docs.map((doc) => FollowUpItem.fromFirestore(doc)).toList();

        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          followUps = followUps.where((f) {
            final matchesTitle = f.title.toLowerCase().contains(q);
            final matchesContext = f.context.toLowerCase().contains(q);
            final matchesPerson = f.personName?.toLowerCase().contains(q) ?? false;
            final matchesCompany = f.companyName?.toLowerCase().contains(q) ?? false;
            return matchesTitle || matchesContext || matchesPerson || matchesCompany;
          }).toList();
        }

        if (filter != null && filter != FollowUpFilter.all) {
          followUps = followUps.where((f) => filter.matches(f)).toList();
        }

        return followUps;
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<FollowUpItem?> getFollowUp(String id) async {
    try {
      final doc = await _followUpsCollection.doc(id).get();
      if (!doc.exists) return null;
      return FollowUpItem.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    try {
      await _followUpsCollection.doc(id).update({
        'isCompleted': isCompleted,
        'status': isCompleted ? FollowUpStatus.completed.name : FollowUpStatus.dueToday.name,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> addFollowUp(FollowUpItem followUp) async {
    try {
      final docRef = followUp.id.isNotEmpty ? _followUpsCollection.doc(followUp.id) : _followUpsCollection.doc();
      final map = followUp.toMap()
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
  Future<void> updateFollowUp(FollowUpItem followUp) async {
    try {
      final map = followUp.toMap()..['updatedAt'] = FieldValue.serverTimestamp();
      await _followUpsCollection.doc(followUp.id).update(map);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> deleteFollowUp(String id) async {
    try {
      await _followUpsCollection.doc(id).delete();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Stream<FollowUpSummaryStats> streamSummaryStats() {
    try {
      return _followUpsCollection.snapshots().map((snapshot) {
        int today = 0;
        int upcoming = 0;
        int waiting = 0;
        int overdue = 0;
        int completed = 0;

        for (final doc in snapshot.docs) {
          final item = FollowUpItem.fromFirestore(doc);
          if (item.isCompleted || item.status == FollowUpStatus.completed) {
            completed++;
          } else if (item.status == FollowUpStatus.dueToday) {
            today++;
          } else if (item.status == FollowUpStatus.upcoming) {
            upcoming++;
          } else if (item.status == FollowUpStatus.waiting) {
            waiting++;
          } else if (item.status == FollowUpStatus.overdue) {
            overdue++;
          }
        }

        return FollowUpSummaryStats(
          todayCount: today,
          upcomingCount: upcoming,
          waitingCount: waiting,
          overdueCount: overdue,
          completedCount: completed,
        );
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}