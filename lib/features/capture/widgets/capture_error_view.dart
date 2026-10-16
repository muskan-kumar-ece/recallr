import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Capture error recovery view with optional Settings navigation for permanent permission denial.
class CaptureErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  /// Optional callback shown as an 'Open Settings' button when a system
  /// permission (e.g. microphone) is permanently denied. When null, only
  /// the Retry button is shown.
  final VoidCallback? onOpenSettings;

  const CaptureErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onCancel,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RecallrErrorState(
          message: errorMessage,
          onRetry: onOpenSettings == null ? onRetry : null,
        ),
        if (onOpenSettings != null) ...[
          RecallrSpacing.gapSm,
          RecallrButton(
            label: 'Open Settings',
            variant: RecallrButtonVariant.primary,
            leadingIcon: Icons.settings_outlined,
            onPressed: onOpenSettings!,
          ),
          RecallrSpacing.gapSm,
          RecallrButton(
            label: 'Try Again',
            variant: RecallrButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ] else ...[
          RecallrSpacing.gapMd,
        ],
        RecallrButton(
          label: 'Cancel',
          variant: RecallrButtonVariant.secondary,
          onPressed: onCancel,
        ),
      ],
    );
  }
}