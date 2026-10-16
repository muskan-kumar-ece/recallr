import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/people/models/person_item.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/person_detail/models/relationship_memory_models.dart';
import '../../repositories/person_detail_repository.dart';

/// Production Firestore-backed repository for Person 360 Dossiers.
/// All queries are scoped under `users/{uid}/people/{personId}`.
class FirestorePersonDetailRepository implements PersonDetailRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestorePersonDetailRepository({
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

  DocumentReference<Map<String, dynamic>> _personDoc(String personId) {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('people').doc(personId);
  }

  @override
  Future<PersonProfile?> getProfile(String personId) async {
    try {
      final doc = await _personDoc(personId).get();
      if (!doc.exists) return null;
      return PersonProfile.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Stream<PersonProfile?> streamProfile(String personId) {
    try {
      return _personDoc(personId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return PersonProfile.fromFirestore(doc);
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<PersonProfile>> getAllProfiles() async {
    try {
      final snapshot = await _firestore.collection('users').doc(_uid).collection('people').get();
      return snapshot.docs.map((doc) => PersonProfile.fromFirestore(doc)).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> saveProfile(PersonProfile profile) async {
    try {
      final map = profile.toMap()
        ..['userId'] = _uid
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _personDoc(profile.id).set(map, SetOptions(merge: true));
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {
    try {
      final existing = await getProfile(personId);
      if (existing != null) {
        final updatedTimeline = [
          item,
          ...existing.timeline.where((t) => t.id != item.id),
        ];
        await _personDoc(personId).set({
          'timeline': updatedTimeline.map((e) => e.toMap()).toList(),
          'lastInteraction': item.date,
          'totalInteractions': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {
    try {
      final existing = await getProfile(personId);
      if (existing != null) {
        final updatedMemories = [
          item,
          ...existing.memories.where((m) => m.id != item.id && m.text != item.text),
        ];
        await _personDoc(personId).set({
          'memories': updatedMemories.map((e) => e.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonProfile> enrichRelationshipMemory({
    required String personId,
    required RelationshipMemoryUpdate update,
  }) async {
    try {
      var existing = await getProfile(personId);
      if (existing == null) {
        existing = PersonProfile(
          id: personId,
          name: 'Contact $personId',
          role: '',
          company: '',
          location: '',
          initials: 'C',
          relationshipType: RelationshipContextType.collaborator,
          relationshipStrength: 'Emerging Connection',
          firstMet: 'Recent Capture',
          lastInteraction: update.lastInteraction ?? 'Today',
          totalInteractions: 1,
          sharedEventsCount: 0,
          aiSummary: 'Profile established via Omni-Capture memory intake.',
        );
      }

      final updatedTimeline = update.timelineItem != null
          ? [update.timelineItem!, ...existing.timeline.where((t) => t.id != update.timelineItem!.id)]
          : existing.timeline;

      final existingMemIds = existing.memories.map((m) => m.id).toSet();
      final existingMemTexts = existing.memories.map((m) => m.text).toSet();
      final newMemories = update.memories
          .where((m) => !existingMemIds.contains(m.id) && !existingMemTexts.contains(m.text))
          .toList();
      final updatedMemories = [...newMemories, ...existing.memories];

      final updatedFollowUps = update.followUpCandidate != null
          ? [
              update.followUpCandidate!,
              ...existing.followUps.where((f) => f.id != update.followUpCandidate!.id)
            ]
          : existing.followUps;

      final updatedCapabilities = {
        ...existing.capabilities,
        ...update.newCapabilities,
      }.toList();

      final totalInt = update.totalInteractions ?? (existing.totalInteractions + 1);
      final lastInt = update.lastInteraction ?? existing.lastInteraction;
      final strength = update.relationshipStrength ?? existing.relationshipStrength;
      final sharedEvents = update.sharedEventsCount != null
          ? existing.sharedEventsCount + update.sharedEventsCount!
          : existing.sharedEventsCount;

      final map = {
        'timeline': updatedTimeline.map((e) => e.toMap()).toList(),
        'memories': updatedMemories.map((e) => e.toMap()).toList(),
        'followUps': updatedFollowUps.map((e) => e.toMap()).toList(),
        'capabilities': updatedCapabilities,
        'totalInteractions': totalInt,
        'lastInteraction': lastInt,
        'relationshipStrength': strength,
        'sharedEventsCount': sharedEvents,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _personDoc(personId).set(map, SetOptions(merge: true));

      final updated = existing.copyWith(
        timeline: updatedTimeline,
        memories: updatedMemories,
        followUps: updatedFollowUps,
        capabilities: updatedCapabilities,
        totalInteractions: totalInt,
        lastInteraction: lastInt,
        relationshipStrength: strength,
        sharedEventsCount: sharedEvents,
        updatedAt: DateTime.now(),
      );

      return updated;
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> updateRelationshipStats(
    String personId, {
    int? totalInteractions,
    String? lastInteraction,
    String? relationshipStrength,
    int? sharedEventsCount,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (totalInteractions != null) updates['totalInteractions'] = totalInteractions;
      if (lastInteraction != null) updates['lastInteraction'] = lastInteraction;
      if (relationshipStrength != null) updates['relationshipStrength'] = relationshipStrength;
      if (sharedEventsCount != null) updates['sharedEventsCount'] = sharedEventsCount;

      await _personDoc(personId).set(updates, SetOptions(merge: true));
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}