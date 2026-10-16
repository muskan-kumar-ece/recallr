import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/activity_models.dart';
import 'activity_timeline_group.dart';

/// Complete chronological timeline displaying grouped activity encounters.
class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;
  final String? selectedActivityId;
  final void Function(ActivityItem item)? onTapActivity;
  final void Function(String personId)? onTapPerson;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.selectedActivityId,
    this.onTapActivity,
    this.onTapPerson,
  });

  @override
  Widget build(BuildContext context) {
    final List<TimelinePeriod> activePeriods = TimelinePeriod.values.where((period) {
      return activities.any((item) => item.period == period);
    }).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activePeriods.length,
      separatorBuilder: (_, __) => RecallrSpacing.gapXl,
      itemBuilder: (context, index) {
        final period = activePeriods[index];
        final groupItems = activities.where((item) => item.period == period).toList();

        return ActivityTimelineGroup(
          period: period,
          items: groupItems,
          selectedActivityId: selectedActivityId,
          onTapActivity: onTapActivity,
          onTapPerson: onTapPerson,
        );
      },
    );
  }
}