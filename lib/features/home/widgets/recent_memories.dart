import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/home_memory_item.dart';
import 'memory_card.dart';

/// Recently Remembered section displaying contextual memory records.
class RecentMemoriesSection extends StatelessWidget {
  final List<RecentMemoryItem> items;

  const RecentMemoriesSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
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
                    Icons.history_rounded,
                    size: 18.0,
                    color: RecallrColors.aiCyanHighlight,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Recently Remembered',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              '${items.length} moments',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            return MemoryCard(item: items[index]);
          },
        ),
      ],
    );
  }
}