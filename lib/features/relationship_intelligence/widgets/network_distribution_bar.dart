import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Visual distribution widget showing the proportional breakdown of relationship states.
class NetworkDistributionBar extends StatelessWidget {
  final NetworkHealth health;

  const NetworkDistributionBar({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final total = health.totalPeople;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final segments = [
      _Segment('Strong', health.strongRelationships, RelationshipState.strong.colorToken),
      _Segment('Active', health.activeRelationships, RelationshipState.active.colorToken),
      _Segment('New', health.newRelationships, RelationshipState.newRelationship.colorToken),
      _Segment('Cooling', health.coolingRelationships, RelationshipState.cooling.colorToken),
      _Segment('Neglected', health.neglectedRelationships, RelationshipState.neglected.colorToken),
      _Segment('Dormant', health.dormantRelationships, RelationshipState.dormant.colorToken),
    ];

    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RELATIONSHIP DISTRIBUTION',
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textTertiary,
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10.0),

          // Proportional Bar
          ClipRRect(
            borderRadius: RecallrRadii.radiusPill,
            child: SizedBox(
              height: 10.0,
              child: Row(
                children: segments.where((s) => s.count > 0).map((s) {
                  return Expanded(
                    flex: s.count,
                    child: Container(
                      color: s.color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Legend
          Wrap(
            spacing: 12.0,
            runSpacing: 6.0,
            children: segments.map((s) {
              final pct = total > 0 ? ((s.count / total) * 100.0).toInt() : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${s.name} (${s.count} · $pct%)',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Segment {
  final String name;
  final int count;
  final Color color;

  const _Segment(this.name, this.count, this.color);
}
