import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';

/// Premium first-memory empty state experience.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                shape: BoxShape.circle,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 48.0,
                color: RecallrColors.aiElectricViolet,
              ),
            ),
            RecallrSpacing.gapLg,
            Text(
              'Your professional memory starts here.',
              style: RecallrTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapSm,
            Text(
              'Capture people, conversations, and meetings to build your personal memory graph. Ask questions anytime with zero hallucination.',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapXl,
            RecallrButton(
              label: 'Capture First Encounter',
              variant: RecallrButtonVariant.aiGradient,
              leadingIcon: Icons.add_rounded,
              onPressed: () {
                RecallrBottomSheet.show(
                  context: context,
                  child: const CaptureModal(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}