import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_theme.dart';

/// Glassmorphic surface overlay utilizing BackdropFilter.
class RecallrSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? surfaceColor;
  final double blurSigma;
  final Border? border;

  const RecallrSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.surfaceColor,
    this.blurSigma = 16.0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveRadius = borderRadius ?? RecallrRadii.radiusLg;

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor ?? colors.glassOverlay,
            borderRadius: effectiveRadius,
            border: border ?? Border.all(color: colors.borderSubtle, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
