import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// AI Relationship Summary container for Person Profile.
class AiRelationshipSummary extends StatelessWidget {
  final String summary;
  final List<String> keyTakeaways;

  const AiRelationshipSummary({
    super.key,
    required this.summary,
    this.keyTakeaways = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: RecallrColors.aiElectricViolet.withAlpha(80),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16.0,
                      color: RecallrColors.aiElectricViolet,
                    ),
                    RecallrSpacing.gapXs,
                    Flexible(
                      child: Text(
                        'AI Relationship Summary',
                        style: RecallrTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapSm,
              const RecallrBadge(
                text: 'GROUNDED',
                variant: RecallrBadgeVariant.verified,
              ),
            ],
          ),
          RecallrSpacing.gapMd,
          Text(
            summary,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          if (keyTakeaways.isNotEmpty) ...[
            RecallrSpacing.gapMd,
            const RecallrDivider(),
            RecallrSpacing.gapSm,
            Text(
              'Key Context Takeaways',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.aiCyanHighlight,
                fontWeight: FontWeight.w600,
              ),
            ),
            RecallrSpacing.gapXs,
            ...keyTakeaways.map(
              (takeaway) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5.0, right: 6.0),
                      child: Icon(
                        Icons.circle,
                        size: 5.0,
                        color: RecallrColors.aiCyanHighlight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        takeaway,
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}