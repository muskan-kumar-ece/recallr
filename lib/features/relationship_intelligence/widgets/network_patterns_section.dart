import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Renders detected network patterns with severity badges and recommended actions.
class NetworkPatternsSection extends StatelessWidget {
  final List<NetworkPattern> patterns;
  final ValueChanged<NetworkPattern>? onPatternTap;

  const NetworkPatternsSection({
    super.key,
    required this.patterns,
    this.onPatternTap,
  });

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.insights_rounded,
              size: 15.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                'DETECTED PATTERNS (${patterns.length})',
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
          ],
        ),
        const SizedBox(height: 8.0),
        ...patterns.map((p) => _buildPatternCard(context, p)),
      ],
    );
  }

  Widget _buildPatternCard(BuildContext context, NetworkPattern pattern) {
    final severity = pattern.severity;
    final color = severity.colorToken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: severity == NetworkPatternSeverity.critical
              ? RecallrColors.crimsonAlert.withValues(alpha: 0.5)
              : RecallrColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pattern.type.icon, size: 16.0, color: color),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  pattern.title,
                  style: RecallrTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: RecallrColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: RecallrRadii.radiusPill,
                  border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
                ),
                child: Text(
                  severity.badgeLabel,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            pattern.description,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 12.0,
            ),
          ),
          if (pattern.recommendedAction.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusSm,
                border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 13.0,
                    color: RecallrColors.warmAmberGold,
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      pattern.recommendedAction,
                      style: RecallrTypography.labelSmall.copyWith(
                        color: RecallrColors.textPrimary,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                      ),
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
