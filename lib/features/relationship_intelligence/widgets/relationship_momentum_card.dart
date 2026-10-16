import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Renders a contact's relationship evolution, interaction velocity, cadence, and grounded factors.
class RelationshipMomentumCard extends StatelessWidget {
  final RelationshipMomentum momentum;

  const RelationshipMomentumCard({
    super.key,
    required this.momentum,
  });

  @override
  Widget build(BuildContext context) {
    final direction = momentum.direction;
    final velocity = momentum.velocity;
    final cadence = momentum.cadence;

    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: direction.colorToken.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header & Direction Badge
          Row(
            children: [
              Icon(
                direction.icon,
                size: 15.0,
                color: direction.colorToken,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'RELATIONSHIP EVOLUTION',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: direction.colorToken.withValues(alpha: 0.12),
                  borderRadius: RecallrRadii.radiusPill,
                  border: Border.all(
                    color: direction.colorToken.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  direction.badgeLabel,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: direction.colorToken,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Grounded Headline
          Text(
            momentum.headline,
            style: RecallrTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: RecallrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),

          // Detailed Explanation
          Text(
            momentum.explanation,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 12.0,
              height: 1.4,
            ),
          ),

          // Cadence & Velocity Metrics Pill Strip (if sufficient history)
          if (direction != MomentumDirection.insufficientHistory) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusSm,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Row(
                children: [
                  // Cadence
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CADENCE',
                          style: RecallrTypography.labelSmall.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          cadence.hasSufficientCadence
                              ? 'Every ~${cadence.averageCadenceDays!.toInt()}d'
                              : 'Irregular',
                          style: RecallrTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: cadence.isOffCadence
                                ? RecallrColors.warmAmberGold
                                : RecallrColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1.0, height: 24.0, color: RecallrColors.borderSubtle),
                  const SizedBox(width: 10.0),
                  // Last Contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAST CONTACT',
                          style: RecallrTypography.labelSmall.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          cadence.daysSinceLastInteraction != null
                              ? '${cadence.daysSinceLastInteraction}d ago'
                              : 'None',
                          style: RecallrTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: cadence.isCriticallyOffCadence
                                ? RecallrColors.crimsonAlert
                                : (cadence.isOffCadence ? RecallrColors.warmAmberGold : RecallrColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1.0, height: 24.0, color: RecallrColors.borderSubtle),
                  const SizedBox(width: 10.0),
                  // Velocity (30d)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '30D VELOCITY',
                          style: RecallrTypography.labelSmall.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '${velocity.recentCount} touchpoints',
                          style: RecallrTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: velocity.isAccelerating
                                ? RecallrColors.emeraldVerified
                                : (velocity.isDecelerating ? RecallrColors.warmAmberGold : RecallrColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
