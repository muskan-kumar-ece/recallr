import '../features/person_detail/models/person_profile_model.dart';
import '../features/person_detail/models/relationship_memory_models.dart';

/// Abstract contract for full 360-degree Person Relationship Memory Dossier.
abstract class PersonDetailRepository {
  /// Fetch a complete person memory dossier by ID.
  Future<PersonProfile?> getProfile(String personId);

  /// Stream real-time updates to a person's relationship profile.
  Stream<PersonProfile?> streamProfile(String personId);

  /// Fetch all person memory profiles in bulk.
  Future<List<PersonProfile>> getAllProfiles();

  /// Save or update a person memory profile.
  Future<void> saveProfile(PersonProfile profile);

  /// Add an encounter / timeline event to a person's history.
  Future<void> addTimelineItem(String personId, TimelineItem item);

  /// Add an atomic verified memory claim to a person's dossier.
  Future<void> addMemoryItem(String personId, MemoryItem item);

  /// Atomically enrich person memory, timeline, and relationship statistics.
  Future<PersonProfile> enrichRelationshipMemory({
    required String personId,
    required RelationshipMemoryUpdate update,
  });

  /// Update relationship statistics and connection strength.
  Future<void> updateRelationshipStats(
    String personId, {
    int? totalInteractions,
    String? lastInteraction,
    String? relationshipStrength,
    int? sharedEventsCount,
  });
}