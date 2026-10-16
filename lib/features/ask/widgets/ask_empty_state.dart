import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';

/// Empty state when no memories exist yet in the user's account.
class AskEmptyState extends StatelessWidget {
  final VoidCallback? onCapture;

  const AskEmptyState({super.key, this.onCapture});

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
                Icons.bubble_chart_outlined,
                color: RecallrColors.aiElectricViolet,
                size: 32.0,
              ),
            ),
            RecallrSpacing.gapMd,
            Text(
              'Your memory is still quiet',
              style: RecallrTypography.headlineMedium.copyWith(fontSize: 18.0),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Text(
                'Capture a few professional encounters and Recallr will start connecting the context.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            RecallrSpacing.gapLg,
            RecallrButton(
              label: 'Capture First Encounter',
              variant: RecallrButtonVariant.aiGradient,
              leadingIcon: Icons.add_rounded,
              onPressed: () {
                if (onCapture != null) {
                  onCapture!();
                } else {
                  RecallrBottomSheet.show(
                    context: context,
                    child: const CaptureModal(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}