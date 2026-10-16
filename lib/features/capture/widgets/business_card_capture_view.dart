import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Business card camera scanner simulation view.
class BusinessCardCaptureView extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onCancel;

  const BusinessCardCaptureView({
    super.key,
    required this.onCapture,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera Viewfinder Simulation Container
        Container(
          height: 180.0,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: RecallrRadii.radiusMd,
            border: Border.all(color: RecallrColors.warmAmberGold.withAlpha(120), width: 1.5),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 42.0,
                      color: RecallrColors.warmAmberGold.withAlpha(180),
                    ),
                    RecallrSpacing.gapSm,
                    Text(
                      'Align visiting card inside frame',
                      style: RecallrTypography.monoMetadata.copyWith(
                        color: RecallrColors.textSecondary,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Corner Scanning Guides
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                      left: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                      right: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                      left: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8.0,
                right: 8.0,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                      right: BorderSide(color: RecallrColors.warmAmberGold, width: 2.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        RecallrSpacing.gapMd,

        // Context Note
        Text(
          'Instant optical entity recognition will extract name, title, organization, and contact credentials.',
          style: RecallrTypography.bodyMedium.copyWith(
            color: RecallrColors.textSecondary,
            fontSize: 12.0,
          ),
          textAlign: TextAlign.center,
        ),
        RecallrSpacing.gapLg,

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'Cancel',
                variant: RecallrButtonVariant.secondary,
                onPressed: onCancel,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Scan & Extract',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.camera_alt_rounded,
                onPressed: onCapture,
              ),
            ),
          ],
        ),
      ],
    );
  }
}