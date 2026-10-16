import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// 6-metric responsive grid displaying core network aggregates.
class NetworkMetricsGrid extends StatelessWidget {
  final NetworkHealth health;

  const NetworkMetricsGrid({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'People',
        value: '${health.totalPeople}',
        icon: Icons.people_outline_rounded,
        color: RecallrColors.textPrimary,
      ),
      _MetricData(
        label: 'Strong',
        value: '${health.strongRelationships}',
        icon: Icons.shield_outlined,
        color: RecallrColors.emeraldVerified,
      ),
      _MetricData(
        label: 'Active',
        value: '${health.activeRelationships}',
        icon: Icons.bolt_rounded,
        color: RecallrColors.aiCyanHighlight,
      ),
      _MetricData(
        label: 'Cooling',
        value: '${health.coolingRelationships}',
        icon: Icons.ac_unit_rounded,
        color: RecallrColors.warmAmberGold,
      ),
      _MetricData(
        label: 'Needs Attention',
        value: '${health.relationshipsNeedingAttention}',
        icon: Icons.notifications_active_outlined,
        color: health.relationshipsNeedingAttention > 0
            ? RecallrColors.crimsonAlert
            : RecallrColors.textSecondary,
      ),
      _MetricData(
        label: 'Overdue',
        value: '${health.overdueFollowUps}',
        icon: Icons.schedule_rounded,
        color: health.overdueFollowUps > 0
            ? RecallrColors.crimsonAlert
            : RecallrColors.textSecondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 480 ? 2 : (constraints.maxWidth < 900 ? 3 : 6);
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 8.0) / crossAxisCount;

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: metrics.map((m) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: RecallrColors.slateSurface,
                  borderRadius: RecallrRadii.radiusMd,
                  border: Border.all(
                    color: RecallrColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(m.icon, size: 14.0, color: m.color),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            m.label,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      m.value,
                      style: RecallrTypography.titleMedium.copyWith(
                        color: m.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
