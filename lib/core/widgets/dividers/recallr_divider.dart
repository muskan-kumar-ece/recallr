import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// 1px Subtle divider with optional centered or leading label.
class RecallrDivider extends StatelessWidget {
  final String? label;
  final double verticalSpacing;

  const RecallrDivider({
    super.key,
    this.label,
    this.verticalSpacing = RecallrSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalSpacing),
        child: const Divider(
          color: RecallrColors.borderSubtle,
          height: 1.0,
          thickness: 1.0,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalSpacing),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: RecallrColors.borderSubtle, height: 1.0, thickness: 1.0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md),
            child: Text(
              label!,
              style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary),
            ),
          ),
          const Expanded(
            child: Divider(color: RecallrColors.borderSubtle, height: 1.0, thickness: 1.0),
          ),
        ],
      ),
    );
  }
}