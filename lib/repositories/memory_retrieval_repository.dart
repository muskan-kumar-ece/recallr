import '../features/activity/models/activity_models.dart';
import '../features/ask/models/memory_retrieval_models.dart';
import '../features/capture/models/capture_models.dart';
import '../features/follow_ups/models/follow_up_models.dart';
import '../features/people/models/person_item.dart';

/// Abstract contract for multi-source personal memory retrieval.
abstract class MemoryRetrievalRepository {
  /// Search people directory by query terms.
  Future<List<PersonItem>> searchPeople(String query, {int limit = 10});

  /// Search chronological activity timeline.
  Future<List<ActivityItem>> searchActivities(String query, {int limit = 10});

  /// Search persisted Omni-Capture records.
  Future<List<CaptureItem>> searchCaptures(String query, {int limit = 10});

  /// Search active and completed follow-up commitments.
  Future<List<FollowUpItem>> searchFollowUps(String query, {int limit = 10});

  /// Retrieve all memory evidence candidates for a query.
  Future<List<MemoryEvidence>> searchEvidence(MemoryQuery query, {int limit = 30});

  /// Retrieve recent interaction evidence.
  Future<List<MemoryEvidence>> getRecentInteractions({int limit = 10});
}