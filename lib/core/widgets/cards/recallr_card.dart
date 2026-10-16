import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_shadows.dart';
import '../../theme/recallr_spacing.dart';

/// Reusable Charcoal Card container with 1px border and optional tap interaction.
class RecallrCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final int elevation;
  final BorderRadius? borderRadius;

  const RecallrCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = RecallrSpacing.cardPadding,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? RecallrRadii.radiusLg;
    final effectiveBorderColor = borderColor ?? RecallrColors.borderSubtle;
    final effectiveBgColor = backgroundColor ?? RecallrColors.charcoalCard;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorderColor, width: 1.0),
        boxShadow: elevation == 1
            ? [RecallrShadows.elevation1]
            : (elevation >= 2 ? [RecallrShadows.elevation2] : null),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}