import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/home_memory_item.dart';
import 'attention_card.dart';

/// Needs Attention section for actionable memory signals.
class NeedsAttentionSection extends StatelessWidget {
  final List<AttentionItem> items;

  const NeedsAttentionSection({super.key, required this.items});

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
                    Icons.bolt_rounded,
                    size: 18.0,
                    color: RecallrColors.warmAmberGold,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Needs Attention',
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
              '${items.length} actionable',
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
            return AttentionCard(item: items[index]);
          },
        ),
      ],
    );
  }
}