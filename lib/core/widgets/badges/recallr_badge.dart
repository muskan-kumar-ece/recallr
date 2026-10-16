import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_typography.dart';

enum RecallrBadgeVariant { verified, pending, warning, neutral }

/// Reusable Badge and Dot Indicator for statuses, counts, and verifications.
class RecallrBadge extends StatelessWidget {
  final String? text;
  final RecallrBadgeVariant variant;
  final bool isDot;
  final Color? customColor;

  const RecallrBadge({
    super.key,
    this.text,
    this.variant = RecallrBadgeVariant.neutral,
    this.isDot = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? _getColor();

    if (isDot) {
      return Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: RecallrRadii.radiusSm,
        border: Border.all(color: color.withAlpha(102), width: 1.0),
      ),
      child: Text(
        text ?? '',
        style: RecallrTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (variant) {
      case RecallrBadgeVariant.verified:
        return RecallrColors.emeraldVerified;
      case RecallrBadgeVariant.pending:
        return RecallrColors.warmAmberGold;
      case RecallrBadgeVariant.warning:
        return RecallrColors.crimsonAlert;
      case RecallrBadgeVariant.neutral:
        return RecallrColors.textSecondary;
    }
  }
}