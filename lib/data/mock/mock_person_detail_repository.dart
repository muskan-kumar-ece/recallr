import 'dart:async';
import '../../features/people/models/person_item.dart';
import '../../features/person_detail/models/person_profile_mock_data.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/person_detail/models/relationship_memory_models.dart';
import '../../repositories/person_detail_repository.dart';

/// Mock implementation of PersonDetailRepository using deterministic profile data.
class MockPersonDetailRepository implements PersonDetailRepository {
  final Map<String, PersonProfile> _store = {};

  MockPersonDetailRepository({Map<String, PersonProfile>? initialProfiles}) {
    if (initialProfiles != null) {
      _store.addAll(initialProfiles);
    }
  }

  @override
  Future<PersonProfile?> getProfile(String personId) async {
    if (_store.containsKey(personId)) {
      return _store[personId];
    }
    final mock = PersonProfileMockData.getProfile(personId);
    if (mock != null) {
      _store[personId] = mock;
      return mock;
    }
    return null;
  }

  @override
  Stream<PersonProfile?> streamProfile(String personId) {
    return Stream.fromFuture(getProfile(personId));
  }

  @override
  Future<List<PersonProfile>> getAllProfiles() async {
    return _store.values.toList();
  }

  @override
  Future<void> saveProfile(PersonProfile profile) async {
    _store[profile.id] = profile;
  }

  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {
    final existing = await getProfile(personId);
    if (existing != null) {
      final updatedTimeline = [
        item,
        ...existing.timeline.where((t) => t.id != item.id),
      ];
      _store[personId] = existing.copyWith(timeline: updatedTimeline);
    }
  }

  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {
    final existing = await getProfile(personId);
    if (existing != null) {
      final updatedMemories = [
        item,
        ...existing.memories.where((m) => m.id != item.id && m.text != item.text),
      ];
      _store[personId] = existing.copyWith(memories: updatedMemories);
    }
  }

  @override
  Future<PersonProfile> enrichRelationshipMemory({
    required String personId,
    required RelationshipMemoryUpdate update,
  }) async {
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

    final enriched = existing.copyWith(
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

    _store[personId] = enriched;
    return enriched;
  }

  @override
  Future<void> updateRelationshipStats(
    String personId, {
    int? totalInteractions,
    String? lastInteraction,
    String? relationshipStrength,
    int? sharedEventsCount,
  }) async {
    final existing = await getProfile(personId);
    if (existing != null) {
      final updated = existing.copyWith(
        totalInteractions: totalInteractions ?? existing.totalInteractions,
        lastInteraction: lastInteraction ?? existing.lastInteraction,
        relationshipStrength: relationshipStrength ?? existing.relationshipStrength,
        sharedEventsCount: sharedEventsCount ?? existing.sharedEventsCount,
        updatedAt: DateTime.now(),
      );
      _store[personId] = updated;
    }
  }
}