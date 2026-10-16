import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';

/// Reusable Recallr Icon Button ensuring minimum 48x48dp touch target and semantic labels.
class RecallrIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isActive;
  final Color? color;
  final double iconSize;

  const RecallrIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isActive = false,
    this.color,
    this.iconSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    final Widget button = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: RecallrRadii.radiusMd,
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: isActive ? RecallrColors.charcoalCard : Colors.transparent,
              borderRadius: RecallrRadii.radiusMd,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: isDisabled
                  ? RecallrColors.textTertiary
                  : (color ?? (isActive ? RecallrColors.aiCyanHighlight : RecallrColors.textPrimary)),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: Semantics(button: true, label: tooltip, child: button),
      );
    }
    return button;
  }
}