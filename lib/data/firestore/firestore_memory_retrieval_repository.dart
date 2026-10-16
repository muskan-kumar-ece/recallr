import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/people/models/person_item.dart';
import '../../repositories/memory_retrieval_repository.dart';
import '../../services/retrieval/query_normalizer.dart';

/// Production Firestore-backed repository for multi-source personal memory retrieval.
/// Scoped strictly to `users/{uid}/*` subcollections with internal auth resolution.
class FirestoreMemoryRetrievalRepository implements MemoryRetrievalRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestoreMemoryRetrievalRepository({
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

  CollectionReference<Map<String, dynamic>> _userCollection(String collection) {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection(collection);
  }

  @override
  Future<List<PersonItem>> searchPeople(String query, {int limit = 10}) async {
    try {
      final lower = query.toLowerCase().trim();
      if (lower.isEmpty) return const [];
      final tokens = QueryNormalizer.extractTokens(lower);

      final snapshot = await _userCollection('people').limit(50).get();
      final people = snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();

      return people.where((p) {
        final haystacks = [
          p.name,
          p.role,
          p.company,
          p.email ?? '',
          p.phone ?? '',
          ...p.capabilities,
        ];
        return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
      }).take(limit).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<ActivityItem>> searchActivities(String query, {int limit = 10}) async {
    try {
      final lower = query.toLowerCase().trim();
      if (lower.isEmpty) return const [];
      final tokens = QueryNormalizer.extractTokens(lower);

      final snapshot = await _userCollection('activities').limit(50).get();
      final activities = snapshot.docs.map((doc) => ActivityItem.fromFirestore(doc)).toList();

      return activities.where((a) {
        final haystacks = [
          a.title,
          a.summary,
          a.personName ?? '',
          a.companyName ?? '',
        ];
        return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
      }).take(limit).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<CaptureItem>> searchCaptures(String query, {int limit = 10}) async {
    try {
      final lower = query.toLowerCase().trim();
      if (lower.isEmpty) return const [];
      final tokens = QueryNormalizer.extractTokens(lower);

      final snapshot = await _userCollection('captures').limit(50).get();
      final captures = snapshot.docs.map((doc) => CaptureItem.fromFirestore(doc)).toList();

      return captures.where((c) {
        final haystacks = [
          c.title,
          c.description,
          c.extractedText ?? '',
          c.summary ?? '',
          c.personName ?? '',
          c.companyName ?? '',
        ];
        return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
      }).take(limit).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<FollowUpItem>> searchFollowUps(String query, {int limit = 10}) async {
    try {
      final lower = query.toLowerCase().trim();
      if (lower.isEmpty) return const [];
      final tokens = QueryNormalizer.extractTokens(lower);

      final snapshot = await _userCollection('follow_ups').limit(50).get();
      final followUps = snapshot.docs.map((doc) => FollowUpItem.fromFirestore(doc)).toList();

      return followUps.where((f) {
        final haystacks = [
          f.title,
          f.context,
          f.personName ?? '',
          f.companyName ?? '',
        ];
        return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
      }).take(limit).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<MemoryEvidence>> searchEvidence(MemoryQuery query, {int limit = 30}) async {
    try {
      final queryText = query.rawQuery.toLowerCase().trim();
      final results = <MemoryEvidence>[];

      // 1. Search People
      final people = await searchPeople(queryText, limit: 10);
      for (final p in people) {
        results.add(MemoryEvidence(
          id: 'ev_p_${p.id}',
          sourceType: MemorySourceType.person,
          sourceId: p.id,
          personId: p.id,
          personName: p.name,
          timestamp: p.lastInteraction,
          content: '${p.name} · ${p.role} at ${p.company}. Capabilities: ${p.capabilities.join(", ")}. ${p.contextSnippet ?? ""}',
          relevanceScore: 0.90,
          matchReason: 'Person profile match for "$queryText"',
        ));
      }

      // 2. Search Follow-ups
      final followUps = await searchFollowUps(queryText, limit: 10);
      for (final f in followUps) {
        results.add(MemoryEvidence(
          id: 'ev_fu_${f.id}',
          sourceType: MemorySourceType.followUp,
          sourceId: f.id,
          personId: f.personId,
          personName: f.personName,
          timestamp: f.dueDate,
          content: '${f.commitmentType.badgeText}: ${f.title}. Due: ${f.dueDate}. Context: ${f.context}',
          relevanceScore: 0.88,
          matchReason: 'Follow-up commitment match for "$queryText"',
        ));
      }

      // 3. Search Activities
      final activities = await searchActivities(queryText, limit: 10);
      for (final a in activities) {
        results.add(MemoryEvidence(
          id: 'ev_act_${a.id}',
          sourceType: MemorySourceType.activity,
          sourceId: a.id,
          personId: a.personId,
          personName: a.personName,
          timestamp: a.timestamp,
          content: '${a.title} (${a.timestamp}): ${a.summary}',
          relevanceScore: 0.80,
          matchReason: 'Activity encounter match for "$queryText"',
        ));
      }

      // 4. Search Captures
      final captures = await searchCaptures(queryText, limit: 10);
      for (final c in captures) {
        results.add(MemoryEvidence(
          id: 'ev_cap_${c.id}',
          sourceType: MemorySourceType.capture,
          sourceId: c.id,
          personId: c.personId,
          personName: c.personName,
          timestamp: c.timestamp,
          content: '${c.title} (${c.type.label}): ${c.summary ?? c.description} Extracted: ${c.extractedText ?? ""}',
          relevanceScore: 0.75,
          matchReason: 'Omni-Capture intake match for "$queryText"',
        ));
      }

      return results.take(limit).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<MemoryEvidence>> getRecentInteractions({int limit = 10}) async {
    try {
      final snapshot = await _userCollection('activities')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs.map((doc) => ActivityItem.fromFirestore(doc)).toList();
      final results = <MemoryEvidence>[];

      for (final a in activities) {
        results.add(MemoryEvidence(
          id: 'ev_recent_act_${a.id}',
          sourceType: MemorySourceType.activity,
          sourceId: a.id,
          personId: a.personId,
          personName: a.personName,
          timestamp: a.timestamp,
          content: '${a.title} with ${a.personName ?? "Contact"} (${a.companyName ?? ""}): ${a.summary}',
          relevanceScore: 0.85,
          matchReason: 'Recent encounter on timeline',
        ));
      }

      return results;
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}