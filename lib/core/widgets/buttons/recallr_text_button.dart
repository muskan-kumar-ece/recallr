import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Reusable Recallr Text Button with WCAG compliant touch target.
class RecallrTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? leadingIcon;

  const RecallrTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? RecallrColors.aiCyanHighlight,
          padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md, vertical: RecallrSpacing.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16.0,
                color: isDisabled ? RecallrColors.textTertiary : (textColor ?? RecallrColors.aiCyanHighlight),
              ),
              RecallrSpacing.gapSm,
            ],
            Text(
              text,
              style: RecallrTypography.titleMedium.copyWith(
                color: isDisabled ? RecallrColors.textTertiary : (textColor ?? RecallrColors.aiCyanHighlight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}