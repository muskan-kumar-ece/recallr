import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Hero header widget presenting the aggregate network health score and level.
class NetworkHealthHeader extends StatelessWidget {
  final NetworkHealth health;

  const NetworkHealthHeader({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final level = health.level;
    final confidence = health.confidence;
    final score = health.score.toInt();

    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: level.colorToken.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Tag & Confidence
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 15.0,
                color: RecallrColors.aiCyanHighlight,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'NETWORK HEALTH',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.5,
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
                  color: confidence.colorToken.withValues(alpha: 0.12),
                  borderRadius: RecallrRadii.radiusPill,
                  border: Border.all(
                    color: confidence.colorToken.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  confidence.displayName.toUpperCase(),
                  style: RecallrTypography.labelSmall.copyWith(
                    color: confidence.colorToken,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Score & Level Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: RecallrTypography.displayLarge.copyWith(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w700,
                  color: level.colorToken,
                  height: 1.0,
                ),
              ),
              Text(
                ' / 100',
                style: RecallrTypography.titleMedium.copyWith(
                  color: RecallrColors.textTertiary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: level.colorToken.withValues(alpha: 0.15),
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(
                      color: level.colorToken.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    level.badgeLabel,
                    style: RecallrTypography.labelSmall.copyWith(
                      color: level.colorToken,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Grounded Description
          Text(
            health.totalPeople == 0
                ? 'Your network is just getting started. Add your first connection to derive health intelligence.'
                : (confidence == NetworkConfidence.limited
                    ? 'Limited data: Keep recording interactions to unlock deeper network health intelligence.'
                    : level.description),
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 13.0,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
