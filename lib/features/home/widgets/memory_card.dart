import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/home_memory_item.dart';

/// Context-rich memory card representing a Person, Company, Interaction, or Note.
class MemoryCard extends StatelessWidget {
  final RecentMemoryItem item;

  const MemoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return RecallrCard(
      onTap: () => Navigator.of(context).pushNamed(item.targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RecallrAvatar(
                initials: item.initials,
                size: RecallrAvatarSize.md,
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
                        Expanded(
                          child: Text(
                            item.title,
                            style: RecallrTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.timeAgo != null)
                          Text(
                            item.timeAgo!,
                            style: RecallrTypography.monoMetadata.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 11.0,
                            ),
                          ),
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        item.subtitle!,
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item.eventOrLocation != null) ...[
            RecallrSpacing.gapSm,
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14.0,
                  color: RecallrColors.textTertiary,
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    item.eventOrLocation!,
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
          ],
          RecallrSpacing.gapSm,
          Container(
            padding: const EdgeInsets.all(RecallrSpacing.sm),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
              border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
            ),
            child: Text(
              item.contextSnippet,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textPrimary,
                fontSize: 13.0,
                height: 1.4,
              ),
            ),
          ),
          if (item.tags.isNotEmpty) ...[
            RecallrSpacing.gapSm,
            Wrap(
              spacing: RecallrSpacing.xs,
              runSpacing: RecallrSpacing.xs,
              children: item.tags.map((tag) {
                return RecallrChip(label: tag, isSelected: false);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}