import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Processing and extraction loading skeleton for Omni-Capture Hub.
class CaptureProcessingView extends StatelessWidget {
  final String statusText;

  const CaptureProcessingView({
    super.key,
    this.statusText = 'Extracting relationship context & entities...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusMd,
            border: Border.all(color: RecallrColors.aiElectricViolet.withAlpha(90), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RecallrColors.aiElectricViolet.withAlpha(30),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(RecallrColors.aiElectricViolet),
                    ),
                  ),
                ),
              ),
              RecallrSpacing.gapMd,
              Text(
                statusText,
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapXs,
              Text(
                'Structuring key takeaways, contact entities, and promises',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 12.0,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapLg,
              const RecallrSkeleton(height: 16.0),
              RecallrSpacing.gapSm,
              const RecallrSkeleton(height: 16.0),
              RecallrSpacing.gapSm,
              const RecallrSkeleton(height: 16.0),
            ],
          ),
        ),
      ],
    );
  }
}