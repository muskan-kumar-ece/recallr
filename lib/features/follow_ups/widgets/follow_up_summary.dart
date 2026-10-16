import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/follow_up_models.dart';

/// Relationship commitments KPI summary strip.
class FollowUpSummary extends StatelessWidget {
  final FollowUpSummaryStats stats;
  final FollowUpFilter selectedFilter;
  final ValueChanged<FollowUpFilter>? onFilterSelected;

  const FollowUpSummary({
    super.key,
    required this.stats,
    required this.selectedFilter,
    this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 480.0;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Today',
                      count: stats.todayCount,
                      color: RecallrColors.warmAmberGold,
                      filter: FollowUpFilter.dueToday,
                    ),
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Upcoming',
                      count: stats.upcomingCount,
                      color: RecallrColors.aiCyanHighlight,
                      filter: FollowUpFilter.upcoming,
                    ),
                  ),
                ],
              ),
              RecallrSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Waiting',
                      count: stats.waitingCount,
                      color: RecallrColors.aiElectricViolet,
                      filter: FollowUpFilter.waiting,
                    ),
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Overdue',
                      count: stats.overdueCount,
                      color: RecallrColors.crimsonAlert,
                      filter: FollowUpFilter.overdue,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Today',
                count: stats.todayCount,
                color: RecallrColors.warmAmberGold,
                filter: FollowUpFilter.dueToday,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: _buildMetricCard(
                label: 'Upcoming',
                count: stats.upcomingCount,
                color: RecallrColors.aiCyanHighlight,
                filter: FollowUpFilter.upcoming,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: _buildMetricCard(
                label: 'Waiting',
                count: stats.waitingCount,
                color: RecallrColors.aiElectricViolet,
                filter: FollowUpFilter.waiting,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: _buildMetricCard(
                label: 'Overdue',
                count: stats.overdueCount,
                color: RecallrColors.crimsonAlert,
                filter: FollowUpFilter.overdue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required Color color,
    required FollowUpFilter filter,
  }) {
    final bool isSelected = selectedFilter == filter;

    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: isSelected ? color : RecallrColors.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: RecallrRadii.radiusMd,
        child: InkWell(
          borderRadius: RecallrRadii.radiusMd,
          onTap: onFilterSelected != null ? () => onFilterSelected!(filter) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: RecallrTypography.labelSmall.copyWith(
                        color: isSelected ? color : RecallrColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count > 0 ? color : RecallrColors.textTertiary.withAlpha(80),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  '$count',
                  style: RecallrTypography.displayLarge.copyWith(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : RecallrColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}