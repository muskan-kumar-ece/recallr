import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Capture error recovery view with optional Settings navigation for permanent permission denial
/// or fallback save option when cloud media upload is unconfigured.
class CaptureErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  /// Optional callback shown as an 'Open Settings' button when a system
  /// permission (e.g. microphone) is permanently denied.
  final VoidCallback? onOpenSettings;

  /// Optional secondary fallback action (e.g. Save contact details without cloud photo).
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;

  const CaptureErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onCancel,
    this.onOpenSettings,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
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
        if (onSecondaryAction != null) ...[
          RecallrSpacing.gapSm,
          RecallrButton(
            label: secondaryActionLabel ?? 'Save Details Without Cloud Photo',
            variant: RecallrButtonVariant.primary,
            leadingIcon: secondaryActionIcon ?? Icons.save_alt_rounded,
            onPressed: onSecondaryAction!,
          ),
          RecallrSpacing.gapSm,
          RecallrButton(
            label: 'Try Again',
            variant: RecallrButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ] else if (onOpenSettings != null) ...[
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
        RecallrSpacing.gapSm,
        RecallrButton(
          label: 'Cancel',
          variant: RecallrButtonVariant.secondary,
          onPressed: onCancel,
        ),
      ],
    );
  }
}