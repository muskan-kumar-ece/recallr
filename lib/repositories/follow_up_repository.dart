import '../features/follow_ups/models/follow_up_models.dart';

/// Abstract contract for Follow-ups & Relationship Commitments Hub.
abstract class FollowUpRepository {
  /// Stream of user-scoped follow-ups with optional search and filter.
  Stream<List<FollowUpItem>> streamFollowUps({
    String? query,
    FollowUpFilter? filter,
    int limit = 100,
  });

  /// Fetch a single follow-up item by ID.
  Future<FollowUpItem?> getFollowUp(String id);

  /// Toggle completion state of a relationship commitment.
  Future<void> toggleComplete(String id, bool isCompleted);

  /// Add a new relationship commitment.
  Future<void> addFollowUp(FollowUpItem followUp);

  /// Update an existing commitment.
  Future<void> updateFollowUp(FollowUpItem followUp);

  /// Delete a follow-up item.
  Future<void> deleteFollowUp(String id);

  /// Stream or fetch summary statistics for active/upcoming/overdue follow-ups.
  Stream<FollowUpSummaryStats> streamSummaryStats();
}