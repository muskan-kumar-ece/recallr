import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';

/// Recent queries horizontal history.
class RecentQueries extends StatelessWidget {
  final List<String> queries;
  final ValueChanged<String> onSelected;

  const RecentQueries({
    super.key,
    required this.queries,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 16.0,
              color: RecallrColors.textTertiary,
            ),
            RecallrSpacing.gapXs,
            Flexible(
              child: Text(
                'Recent Questions',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        Wrap(
          spacing: RecallrSpacing.xs,
          runSpacing: RecallrSpacing.xs,
          children: queries.map((q) {
            return RecallrChip(
              label: q,
              leadingIcon: Icons.search_rounded,
              onTap: () => onSelected(q),
            );
          }).toList(),
        ),
      ],
    );
  }
}