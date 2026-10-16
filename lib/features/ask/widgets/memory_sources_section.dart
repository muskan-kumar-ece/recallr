import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/ask_models.dart';
import 'source_memory_card.dart';

/// Sources & Evidence Section for Grounded Answer.
class MemorySourcesSection extends StatelessWidget {
  final List<MemorySource> sources;

  const MemorySourcesSection({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

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
                    Icons.account_tree_outlined,
                    size: 16.0,
                    color: RecallrColors.emeraldVerified,
                  ),
                  RecallrSpacing.gapXs,
                  Expanded(
                    child: Text(
                      'Source Memories & Evidence',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              '${sources.length} sources',
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
          itemCount: sources.length,
          separatorBuilder: (context, index) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            return SourceMemoryCard(source: sources[index]);
          },
        ),
      ],
    );
  }
}