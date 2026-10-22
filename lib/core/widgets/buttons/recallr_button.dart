import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

enum RecallrButtonVariant { primary, secondary, ghost, destructive, aiGradient }

/// Reusable Recallr Button component supporting multiple variants and loading states.
class RecallrButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final RecallrButtonVariant variant;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;

  const RecallrButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = RecallrButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final isAi = variant == RecallrButtonVariant.aiGradient;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? 48.0,
          minHeight: 48.0,
        ),
        child: SizedBox(
          width: width,
          height: 48.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: RecallrRadii.radiusMd,
              splashColor: isAi
                  ? RecallrColors.aiCyanHighlight.withAlpha(50)
                  : RecallrColors.aiElectricVioletPressed.withAlpha(50),
              highlightColor: Colors.white.withAlpha(15),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: (isAi && !isDisabled) ? RecallrColors.aiGradient : null,
                  color: (!isAi || isDisabled) ? _getBackgroundColor(isDisabled) : null,
                  borderRadius: RecallrRadii.radiusMd,
                  border: _getBorder(isDisabled),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md),
                    child: isLoading
                        ? const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(RecallrColors.textPrimary),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (leadingIcon != null) ...[
                                Icon(leadingIcon, size: 18.0, color: _getTextColor(isDisabled)),
                                RecallrSpacing.gapSm,
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  style: RecallrTypography.titleMedium.copyWith(
                                    color: _getTextColor(isDisabled),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (trailingIcon != null) ...[
                                RecallrSpacing.gapSm,
                                Icon(trailingIcon, size: 18.0, color: _getTextColor(isDisabled)),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) return RecallrColors.charcoalCard.withAlpha(128);
    switch (variant) {
      case RecallrButtonVariant.primary:
        return RecallrColors.aiElectricViolet;
      case RecallrButtonVariant.secondary:
        return RecallrColors.charcoalCard;
      case RecallrButtonVariant.ghost:
        return Colors.transparent;
      case RecallrButtonVariant.destructive:
        return RecallrColors.crimsonAlert;
      case RecallrButtonVariant.aiGradient:
        return RecallrColors.aiElectricViolet;
    }
  }

  Border? _getBorder(bool isDisabled) {
    if (variant == RecallrButtonVariant.secondary) {
      return Border.all(
        color: isDisabled ? RecallrColors.borderSubtle.withAlpha(77) : RecallrColors.borderSubtle,
        width: 1.0,
      );
    }
    return null;
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) return RecallrColors.textTertiary;
    if (variant == RecallrButtonVariant.ghost) return RecallrColors.textSecondary;
    return RecallrColors.textPrimary;
  }
}