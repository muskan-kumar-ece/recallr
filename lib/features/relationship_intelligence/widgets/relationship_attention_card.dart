import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/models.dart';

/// Reusable card displaying prioritized relationship attention for a person.
/// Used in Home Command Center, Person Dossier, and relationship dashboards.
class RelationshipAttentionCard extends StatelessWidget {
  final RelationshipAttention attention;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onCreateFollowUp;

  const RelationshipAttentionCard({
    super.key,
    required this.attention,
    this.onTap,
    this.onActionTap,
    this.onCreateFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    final priority = attention.priority;
    final primaryReason = attention.primaryReason;
    final action = attention.primaryAction;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: priority.colorToken.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Name, Company, Priority Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attention.personName,
                      style: RecallrTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: RecallrColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attention.company != null && attention.company!.isNotEmpty) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        attention.company!,
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: priority.colorToken.withValues(alpha: 0.15),
                  borderRadius: RecallrRadii.radiusSm,
                  border: Border.all(
                    color: priority.colorToken.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  priority.badgeLabel,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: priority.colorToken,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // 2. Reason & Grounded Explanation
          if (primaryReason != null) ...[
            Text(
              primaryReason.title,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 3.0),
            Text(
              primaryReason.description,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
          const SizedBox(height: 8.0),

          // 3. Status & Timing Badges Row
          Row(
            children: [
              // Relationship State Dot
              Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: attention.relationshipState.colorToken,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                attention.relationshipState.badgeLabel,
                style: RecallrTypography.labelSmall.copyWith(
                  color: attention.relationshipState.colorToken,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8.0),
              // Timing
              const Icon(
                Icons.schedule_rounded,
                size: 12.0,
                color: RecallrColors.textTertiary,
              ),
              const SizedBox(width: 3.0),
              Expanded(
                child: Text(
                  'Recommended: ${attention.recommendedTiming}',
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
          const SizedBox(height: 10.0),

          // 4. Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final actionLabel = action?.type == RelationshipActionType.completeOverdueFollowUp
                  ? 'Complete Follow-up'
                  : 'Create Follow-up';

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RecallrButton(
                      label: actionLabel,
                      variant: RecallrButtonVariant.primary,
                      leadingIcon: action?.type.icon ?? Icons.add_task_rounded,
                      onPressed: () {
                        if (onCreateFollowUp != null) {
                          onCreateFollowUp!();
                        } else if (onActionTap != null) {
                          onActionTap!();
                        } else {
                          Navigator.of(context).pushNamed(
                            '/follow-ups',
                            arguments: {
                              'personId': attention.personId,
                              'personName': attention.personName,
                              'context': primaryReason?.description ?? 'Relationship follow-up',
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 4.0),
                    Center(
                      child: RecallrTextButton(
                        text: 'View Person',
                        onPressed: () {
                          if (onTap != null) {
                            onTap!();
                          } else {
                            Navigator.of(context).pushNamed('/person/${attention.personId}');
                          }
                        },
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RecallrTextButton(
                    text: 'View Person',
                    onPressed: () {
                      if (onTap != null) {
                        onTap!();
                      } else {
                        Navigator.of(context).pushNamed('/person/${attention.personId}');
                      }
                    },
                  ),
                  const SizedBox(width: 8.0),
                  RecallrButton(
                    label: actionLabel,
                    variant: RecallrButtonVariant.primary,
                    leadingIcon: action?.type.icon ?? Icons.add_task_rounded,
                    onPressed: () {
                      if (onCreateFollowUp != null) {
                        onCreateFollowUp!();
                      } else if (onActionTap != null) {
                        onActionTap!();
                      } else {
                        Navigator.of(context).pushNamed(
                          '/follow-ups',
                          arguments: {
                            'personId': attention.personId,
                            'personName': attention.personName,
                            'context': primaryReason?.description ?? 'Relationship follow-up',
                          },
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
