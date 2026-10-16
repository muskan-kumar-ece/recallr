import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/ask_models.dart';

/// Grounded Answer card showing synthesized answer, grounding metadata, and follow-up chips.
class GroundedAnswerCard extends StatelessWidget {
  final GroundedAnswer answer;
  final ValueChanged<String>? onFollowUpSelected;
  final VoidCallback? onNewQuestion;

  const GroundedAnswerCard({
    super.key,
    required this.answer,
    this.onFollowUpSelected,
    this.onNewQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: RecallrColors.aiElectricViolet.withAlpha(90),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Grounding Status
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
                    Expanded(
                      child: Text(
                        'Grounded Memory Answer',
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
              if (onNewQuestion != null)
                RecallrButton(
                  label: 'New Question',
                  variant: RecallrButtonVariant.ghost,
                  onPressed: onNewQuestion,
                )
              else
                RecallrBadge(
                  text: answer.metadata.groundingSummary.toUpperCase(),
                  variant: RecallrBadgeVariant.verified,
                ),
            ],
          ),
          RecallrSpacing.gapSm,

          // Grounding Metadata Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
              border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 13.0,
                  color: RecallrColors.emeraldVerified,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    answer.metadata.groundingSummary,
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.textSecondary,
                      fontSize: 11.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          RecallrSpacing.gapMd,

          // Grounded Answer Text
          Text(
            answer.answerText,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textPrimary,
              fontSize: 14.0,
              height: 1.5,
            ),
          ),

          // Follow-up Suggestions
          if (answer.followUpSuggestions.isNotEmpty) ...[
            RecallrSpacing.gapMd,
            const RecallrDivider(),
            RecallrSpacing.gapSm,
            Text(
              'Follow-up Questions',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.aiCyanHighlight,
                fontWeight: FontWeight.w600,
                fontSize: 11.0,
              ),
            ),
            RecallrSpacing.gapXs,
            Wrap(
              spacing: RecallrSpacing.xs,
              runSpacing: RecallrSpacing.xs,
              children: answer.followUpSuggestions.map((prompt) {
                return RecallrChip(
                  label: prompt,
                  leadingIcon: Icons.bolt_rounded,
                  onTap: () {
                    if (onFollowUpSelected != null) {
                      onFollowUpSelected!(prompt);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}