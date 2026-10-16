import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Reusable Chip for capabilities, filters, and relationship tags.
class RecallrChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final IconData? leadingIcon;
  final Color? selectedColor;

  const RecallrChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
    this.leadingIcon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = selectedColor ?? RecallrColors.aiElectricViolet;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: RecallrRadii.radiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RecallrSpacing.sm + 4.0,
            vertical: RecallrSpacing.xs + 2.0,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : RecallrColors.slateSurface,
            borderRadius: RecallrRadii.radiusPill,
            border: Border.all(
              color: isSelected ? activeBgColor : RecallrColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 14.0,
                  color: isSelected ? RecallrColors.textPrimary : RecallrColors.textSecondary,
                ),
                const SizedBox(width: 4.0),
              ],
              Flexible(
                child: Text(
                  label,
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: isSelected ? RecallrColors.textPrimary : RecallrColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4.0),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14.0,
                    color: isSelected ? RecallrColors.textPrimary : RecallrColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}