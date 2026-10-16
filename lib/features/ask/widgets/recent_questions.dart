import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';

/// Recent questions history chips.
class RecentQuestions extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String> onSelected;

  const RecentQuestions({
    super.key,
    required this.questions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

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
                'Recent Inquiries',
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
          children: questions.map((q) {
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