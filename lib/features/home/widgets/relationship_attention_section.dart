import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../relationship_intelligence/models/models.dart';
import '../../relationship_intelligence/widgets/relationship_attention_card.dart';

/// Phase 13H-03: Home Command Center Relationship Attention Section.
/// Renders prioritized, grounded attention items answering "Who needs my attention right now, and why?".
class RelationshipAttentionSection extends StatelessWidget {
  final List<RelationshipAttention> attentionItems;
  final List<RelationshipAction>? actions;
  final Function(dynamic item)? onAttentionTap;
  final Function(dynamic item)? onActionTap;
  final Function(dynamic item)? onCreateFollowUp;

  const RelationshipAttentionSection({
    super.key,
    this.attentionItems = const [],
    this.actions,
    this.onAttentionTap,
    this.onActionTap,
    this.onCreateFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    final items = attentionItems.isNotEmpty
        ? attentionItems
        : (actions != null ? _convertActionsToAttention(actions!) : const <RelationshipAttention>[]);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              size: 16.0,
              color: RecallrColors.warmAmberGold,
            ),
            RecallrSpacing.gapXs,
            Expanded(
              child: Text(
                'Relationship Attention',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: RecallrColors.warmAmberGold.withValues(alpha: 0.15),
                borderRadius: RecallrRadii.radiusPill,
                border: Border.all(
                  color: RecallrColors.warmAmberGold.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Text(
                '${items.length} Action${items.length == 1 ? '' : 's'}',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.warmAmberGold,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        ...items.take(3).map((item) {
          final originalAction = actions != null && actions!.isNotEmpty
              ? actions!.firstWhere(
                  (a) => a.personId == item.personId,
                  orElse: () => actions!.first,
                )
              : null;

          return RelationshipAttentionCard(
            attention: item,
            onTap: () {
              if (onAttentionTap != null) {
                onAttentionTap!(originalAction ?? item);
              } else if (onActionTap != null) {
                onActionTap!(originalAction ?? item);
              } else {
                Navigator.of(context).pushNamed('/person/${item.personId}');
              }
            },
            onActionTap: () {
              if (onActionTap != null) {
                onActionTap!(originalAction ?? item);
              } else if (onCreateFollowUp != null) {
                onCreateFollowUp!(originalAction ?? item);
              } else {
                Navigator.of(context).pushNamed(
                  '/follow-ups',
                  arguments: {
                    'personId': item.personId,
                    'personName': item.personName,
                    'context': item.summary,
                  },
                );
              }
            },
            onCreateFollowUp: () {
              if (onCreateFollowUp != null) {
                onCreateFollowUp!(originalAction ?? item);
              } else if (onActionTap != null) {
                onActionTap!(originalAction ?? item);
              } else {
                Navigator.of(context).pushNamed(
                  '/follow-ups',
                  arguments: {
                    'personId': item.personId,
                    'personName': item.personName,
                    'context': item.summary,
                  },
                );
              }
            },
          );
        }),
      ],
    );
  }

  List<RelationshipAttention> _convertActionsToAttention(List<RelationshipAction> actionList) {
    return actionList.map((a) {
      final prio = a.priority == RelationshipActionPriority.urgent
          ? RelationshipAttentionPriority.critical
          : (a.priority == RelationshipActionPriority.high
              ? RelationshipAttentionPriority.high
              : (a.priority == RelationshipActionPriority.medium
                  ? RelationshipAttentionPriority.medium
                  : RelationshipAttentionPriority.low));

      return RelationshipAttention(
        personId: a.personId,
        personName: a.personName,
        attentionScore: a.priority.rank * 25.0,
        priority: prio,
        relationshipState: a.relationshipState,
        relationshipStrength: RelationshipStrength(
          score: a.relationshipScore,
          factors: const [],
          level: 'Active',
          summary: '',
        ),
        reasons: [
          RelationshipAttentionReason(
            code: a.type.name,
            title: a.title,
            description: a.description,
            weight: 1.0,
          ),
        ],
        primaryAction: a,
        recommendedTiming: a.recommendedAt,
        generatedAt: a.generatedAt,
        deduplicationKey: 'attention_${a.personId}_${prio.name}_${a.type.name}',
      );
    }).toList();
  }
}
