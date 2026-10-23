import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Production-grade destructive confirmation dialog adhering to
/// Recallr's Dark-First Pro Design System.
class DestructiveConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;

  const DestructiveConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.delete_outline_rounded,
  });

  /// Displays the dialog and returns `true` if the user confirmed deletion.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.delete_outline_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DestructiveConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RecallrColors.slateSurface,
      shape: RoundedRectangleBorder(
        borderRadius: RecallrRadii.radiusLg,
        side: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      elevation: 12.0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420.0),
        child: Padding(
          padding: const EdgeInsets.all(RecallrSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Header with subtle alert glow
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: RecallrColors.crimsonAlert.withAlpha(25),
                  borderRadius: RecallrRadii.radiusMd,
                  border: Border.all(
                    color: RecallrColors.crimsonAlert.withAlpha(50),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  color: RecallrColors.crimsonAlert,
                  size: 22.0,
                ),
              ),
              const SizedBox(height: RecallrSpacing.md),

              // Title
              Text(
                title,
                style: RecallrTypography.titleMedium.copyWith(fontSize: 18.0, fontWeight: FontWeight.w600).copyWith(
                  color: RecallrColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: RecallrSpacing.xs),

              // Description
              Text(
                message,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: RecallrSpacing.xl),

              // Action Buttons (Wrap prevents overflow on narrow viewports)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: RecallrSpacing.sm,
                  runSpacing: RecallrSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: RecallrColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: RecallrSpacing.md,
                          vertical: RecallrSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: RecallrRadii.radiusSm,
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: RecallrTypography.titleMedium.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600).copyWith(
                          color: RecallrColors.textSecondary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RecallrColors.crimsonAlert,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: RecallrSpacing.lg,
                          vertical: RecallrSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: RecallrRadii.radiusSm,
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: RecallrTypography.titleMedium.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
