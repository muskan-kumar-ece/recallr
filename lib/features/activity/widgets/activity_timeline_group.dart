import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/activity_models.dart';
import 'activity_card.dart';

/// Chronological group of activities (e.g. Today, Yesterday, This Week, Earlier).
class ActivityTimelineGroup extends StatelessWidget {
  final TimelinePeriod period;
  final List<ActivityItem> items;
  final String? selectedActivityId;
  final void Function(ActivityItem item)? onTapActivity;
  final void Function(String personId)? onTapPerson;
  final void Function(ActivityItem item)? onShareActivity;
  final void Function(ActivityItem item)? onDeleteActivity;

  const ActivityTimelineGroup({
    super.key,
    required this.period,
    required this.items,
    this.selectedActivityId,
    this.onTapActivity,
    this.onTapPerson,
    this.onShareActivity,
    this.onDeleteActivity,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Period Header
        Row(
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: _getPeriodColor(),
                shape: BoxShape.circle,
              ),
            ),
            RecallrSpacing.gapXs,
            Text(
              period.uppercaseLabel,
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 11.5,
              ),
            ),
            RecallrSpacing.gapXs,
            RecallrBadge(
              text: '${items.length}',
              variant: RecallrBadgeVariant.neutral,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Container(
                height: 1.0,
                color: RecallrColors.borderSubtle,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapMd,

        // Group items list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final item = items[index];
            return ActivityCard(
              activity: item,
              isSelected: item.id == selectedActivityId,
              onShare: onShareActivity != null ? () => onShareActivity!(item) : null,
              onDelete: onDeleteActivity != null ? () => onDeleteActivity!(item) : null,
              onTap: () {
                if (onTapActivity != null) {
                  onTapActivity!(item);
                } else {
                  Navigator.of(context).pushNamed(item.targetRoute);
                }
              },
              onTapPerson: item.personId != null
                  ? () {
                      if (onTapPerson != null) {
                        onTapPerson!(item.personId!);
                      } else {
                        Navigator.of(context).pushNamed('/person/${item.personId}');
                      }
                    }
                  : null,
              onTapAction: () {
                Navigator.of(context).pushNamed(item.targetRoute);
              },
            );
          },
        ),
      ],
    );
  }

  Color _getPeriodColor() {
    switch (period) {
      case TimelinePeriod.today:
        return RecallrColors.aiElectricViolet;
      case TimelinePeriod.yesterday:
        return RecallrColors.aiCyanHighlight;
      case TimelinePeriod.thisWeek:
        return RecallrColors.warmAmberGold;
      case TimelinePeriod.earlier:
        return RecallrColors.textTertiary;
    }
  }
}