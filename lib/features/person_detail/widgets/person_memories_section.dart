import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/person_profile_model.dart';

/// Key Memories & Verified Claims Section.
class PersonMemoriesSection extends StatelessWidget {
  final List<MemoryItem> items;

  const PersonMemoriesSection({super.key, required this.items});

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
                    Icons.psychology_rounded,
                    size: 16.0,
                    color: RecallrColors.emeraldVerified,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Memories & Context Claims',
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
              '${items.length} verified',
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
          separatorBuilder: (context, index) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final memory = items[index];
            return RecallrCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          memory.category,
                          style: RecallrTypography.labelSmall.copyWith(
                            color: RecallrColors.aiCyanHighlight,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (memory.isVerified) ...[
                        RecallrSpacing.gapSm,
                        const RecallrBadge(
                          text: 'VERIFIED',
                          variant: RecallrBadgeVariant.verified,
                        ),
                      ],
                    ],
                  ),
                  RecallrSpacing.gapXs,
                  Text(
                    memory.text,
                    style: RecallrTypography.bodyLarge.copyWith(
                      color: RecallrColors.textPrimary,
                      fontSize: 13.0,
                      height: 1.45,
                    ),
                  ),
                  RecallrSpacing.gapSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Source: ${memory.source}',
                          style: RecallrTypography.bodyMedium.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 11.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (memory.timestamp != null)
                        Text(
                          memory.timestamp!,
                          style: RecallrTypography.monoMetadata.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}