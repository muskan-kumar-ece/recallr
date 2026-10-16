import 'dart:async';
import '../../features/activity/models/activity_mock_data.dart';
import '../../features/activity/models/activity_models.dart';
import '../../repositories/activity_repository.dart';

/// Mock implementation of ActivityRepository using deterministic activity stream.
class MockActivityRepository implements ActivityRepository {
  List<ActivityItem> _activities;

  MockActivityRepository({List<ActivityItem>? initialActivities})
      : _activities = initialActivities != null
            ? List.from(initialActivities)
            : List.from(ActivityMockData.mockActivities);

  @override
  Stream<List<ActivityItem>> streamActivities({
    String? query,
    ActivityFilter? filter,
    int limit = 100,
  }) {
    var result = List<ActivityItem>.from(_activities);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((a) {
        final matchesTitle = a.title.toLowerCase().contains(q);
        final matchesSummary = a.summary.toLowerCase().contains(q);
        final matchesPerson = a.personName?.toLowerCase().contains(q) ?? false;
        final matchesCompany = a.companyName?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesSummary || matchesPerson || matchesCompany;
      }).toList();
    }

    if (filter != null && filter != ActivityFilter.all) {
      result = result.where((a) => filter.matches(a.type)).toList();
    }

    if (limit > 0) {
      result = result.take(limit).toList();
    }

    return Stream.value(result);
  }

  @override
  Future<ActivityItem?> getActivity(String id) async {
    try {
      return _activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addActivity(ActivityItem activity) async {
    _activities.insert(0, activity);
  }

  @override
  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);
  }
}