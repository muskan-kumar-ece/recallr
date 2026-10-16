import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/home_memory_item.dart';

/// Single Actionable Memory Signal card.
class AttentionCard extends StatelessWidget {
  final AttentionItem item;

  const AttentionCard({super.key, required this.item});

  RecallrBadgeVariant _getBadgeVariant() {
    switch (item.type) {
      case AttentionType.pendingCommitment:
        return RecallrBadgeVariant.pending;
      case AttentionType.followUp:
        return RecallrBadgeVariant.neutral;
      case AttentionType.missingContext:
        return RecallrBadgeVariant.warning;
      case AttentionType.staleRelationship:
        return RecallrBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecallrCard(
      onTap: () => Navigator.of(context).pushNamed(item.targetRoute),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
              border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
            ),
            child: Icon(item.icon, size: 18.0, color: RecallrColors.warmAmberGold),
          ),
          RecallrSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: RecallrBadge(text: item.badgeText, variant: _getBadgeVariant())),
                    if (item.dueText != null) ...[
                      RecallrSpacing.gapXs,
                      Text(
                        item.dueText!,
                        style: RecallrTypography.monoMetadata.copyWith(
                          color: RecallrColors.textTertiary,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ],
                ),
                RecallrSpacing.gapXs,
                Text(
                  item.title,
                  style: RecallrTypography.titleMedium.copyWith(fontSize: 14.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  item.description,
                  style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary, fontSize: 12.0),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}