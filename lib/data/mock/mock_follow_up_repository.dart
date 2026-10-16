import 'dart:async';
import '../../features/follow_ups/models/follow_up_mock_data.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../repositories/follow_up_repository.dart';

/// Mock implementation of FollowUpRepository using in-memory state.
class MockFollowUpRepository implements FollowUpRepository {
  List<FollowUpItem> _followUps;

  MockFollowUpRepository({List<FollowUpItem>? initialFollowUps})
      : _followUps = initialFollowUps != null
            ? List.from(initialFollowUps)
            : List.from(FollowUpMockData.mockFollowUps);

  @override
  Stream<List<FollowUpItem>> streamFollowUps({
    String? query,
    FollowUpFilter? filter,
    int limit = 100,
  }) {
    var result = List<FollowUpItem>.from(_followUps);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((f) {
        final matchesTitle = f.title.toLowerCase().contains(q);
        final matchesContext = f.context.toLowerCase().contains(q);
        final matchesPerson = f.personName?.toLowerCase().contains(q) ?? false;
        final matchesCompany = f.companyName?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesContext || matchesPerson || matchesCompany;
      }).toList();
    }

    if (filter != null && filter != FollowUpFilter.all) {
      result = result.where((f) => filter.matches(f)).toList();
    }

    if (limit > 0) {
      result = result.take(limit).toList();
    }

    return Stream.value(result);
  }

  @override
  Future<FollowUpItem?> getFollowUp(String id) async {
    try {
      return _followUps.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    final index = _followUps.indexWhere((f) => f.id == id);
    if (index != -1) {
      final current = _followUps[index];
      _followUps[index] = current.copyWith(
        isCompleted: isCompleted,
        status: isCompleted ? FollowUpStatus.completed : FollowUpStatus.dueToday,
        completedAt: isCompleted ? 'Just now' : null,
      );
    }
  }

  @override
  Future<void> addFollowUp(FollowUpItem followUp) async {
    _followUps.insert(0, followUp);
  }

  @override
  Future<void> updateFollowUp(FollowUpItem followUp) async {
    final index = _followUps.indexWhere((f) => f.id == followUp.id);
    if (index != -1) {
      _followUps[index] = followUp;
    }
  }

  @override
  Future<void> deleteFollowUp(String id) async {
    _followUps.removeWhere((f) => f.id == id);
  }

  @override
  Stream<FollowUpSummaryStats> streamSummaryStats() {
    int today = 0;
    int upcoming = 0;
    int waiting = 0;
    int overdue = 0;
    int completed = 0;

    for (final item in _followUps) {
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

    return Stream.value(FollowUpSummaryStats(
      todayCount: today,
      upcomingCount: upcoming,
      waitingCount: waiting,
      overdueCount: overdue,
      completedCount: completed,
    ));
  }
}