import '../features/activity/models/activity_models.dart';

/// Abstract contract for chronological activity and relationship timeline.
abstract class ActivityRepository {
  /// Stream of chronological timeline activities with optional keyword and category filtering.
  Stream<List<ActivityItem>> streamActivities({
    String? query,
    ActivityFilter? filter,
    int limit = 100,
  });

  /// Fetch a single activity record by ID.
  Future<ActivityItem?> getActivity(String id);

  /// Record a new chronological encounter, call, meeting, note, or card capture.
  Future<void> addActivity(ActivityItem activity);

  /// Delete or archive an activity item.
  Future<void> deleteActivity(String id);
}