import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';

/// State displayed when no confident grounded answer is found.
class AskNoResultsState extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSuggestionSelected;

  const AskNoResultsState({
    super.key,
    required this.query,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                shape: BoxShape.circle,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: RecallrColors.textSecondary,
                size: 32.0,
              ),
            ),
            RecallrSpacing.gapMd,
            Text(
              'No grounded memories found',
              style: RecallrTypography.headlineMedium.copyWith(fontSize: 18.0),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: Text(
                'I couldn\'t find enough memory to answer "$query" confidently.\nTry asking about a specific person, meeting, company, or topic.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            RecallrSpacing.gapLg,
            Text(
              'Explore Remembered Topics',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.aiCyanHighlight,
                fontWeight: FontWeight.w600,
              ),
            ),
            RecallrSpacing.gapSm,
            Wrap(
              spacing: RecallrSpacing.xs,
              runSpacing: RecallrSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                'What did I discuss with Priya?',
                'Who knows about PCB manufacturing?',
                'When did I meet Vivek?',
                'Who can help with Quantum?',
              ].map((suggestion) {
                return RecallrChip(
                  label: suggestion,
                  leadingIcon: Icons.bolt_rounded,
                  onTap: () => onSuggestionSelected(suggestion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}