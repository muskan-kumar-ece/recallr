import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';

/// Suggested questions for Ask your memory.
class SuggestedQuestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const SuggestedQuestions({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 16.0,
              color: RecallrColors.aiElectricViolet,
            ),
            RecallrSpacing.gapXs,
            Flexible(
              child: Text(
                'Suggested Inquiries',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
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
          children: suggestions.map((s) {
            return RecallrChip(
              label: s,
              leadingIcon: Icons.bolt_rounded,
              onTap: () => onSelected(s),
            );
          }).toList(),
        ),
      ],
    );
  }
}