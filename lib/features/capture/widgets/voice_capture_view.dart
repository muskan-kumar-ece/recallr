import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Voice memo recording simulation view.
class VoiceCaptureView extends StatelessWidget {
  final bool isRecording;
  final String durationText;
  final VoidCallback onToggleRecording;
  final VoidCallback onProcessVoice;
  final VoidCallback onCancel;

  const VoiceCaptureView({
    super.key,
    required this.isRecording,
    required this.durationText,
    required this.onToggleRecording,
    required this.onProcessVoice,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mic Center Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusMd,
            border: Border.all(
              color: isRecording ? RecallrColors.aiElectricViolet : RecallrColors.borderSubtle,
              width: isRecording ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: onToggleRecording,
                child: Container(
                  width: 68.0,
                  height: 68.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording
                        ? RecallrColors.aiElectricViolet.withAlpha(40)
                        : RecallrColors.slateSurface,
                    border: Border.all(
                      color: isRecording ? RecallrColors.aiElectricViolet : RecallrColors.borderSubtle,
                      width: 2.0,
                    ),
                  ),
                  child: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                    size: 32.0,
                    color: isRecording ? RecallrColors.aiElectricViolet : RecallrColors.textPrimary,
                  ),
                ),
              ),
              RecallrSpacing.gapMd,
              Text(
                isRecording ? 'Recording conversation takeaway...' : 'What would you like Recallr to remember?',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapXs,
              Text(
                durationText,
                style: RecallrTypography.monoMetadata.copyWith(
                  color: isRecording ? RecallrColors.aiCyanHighlight : RecallrColors.textTertiary,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                label: isRecording ? 'Finish & Process' : 'Start Recording',
                variant: RecallrButtonVariant.primary,
                leadingIcon: isRecording ? Icons.check_circle_outline_rounded : Icons.fiber_manual_record_rounded,
                onPressed: isRecording ? onProcessVoice : onToggleRecording,
              ),
            ),
          ],
        ),
      ],
    );
  }
}