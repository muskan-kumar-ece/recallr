import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';
import '../buttons/recallr_button.dart';

/// Graceful inline error state with retry action.
class RecallrErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RecallrErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.crimsonAlert.withAlpha(20),
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(color: RecallrColors.crimsonAlert.withAlpha(77), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: RecallrColors.crimsonAlert, size: 20.0),
              RecallrSpacing.gapSm,
              Expanded(
                child: Text(
                  message,
                  style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            RecallrSpacing.gapMd,
            Align(
              alignment: Alignment.centerRight,
              child: RecallrButton(
                label: 'Retry',
                onPressed: onRetry,
                variant: RecallrButtonVariant.ghost,
              ),
            ),
          ],
        ],
      ),
    );
  }
}