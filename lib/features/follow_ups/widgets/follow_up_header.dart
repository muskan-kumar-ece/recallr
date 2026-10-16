import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Editorial header for Recallr Phase 10 Follow-ups & Commitments Hub.
class FollowUpHeader extends StatelessWidget {
  const FollowUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Follow-ups',
          style: RecallrTypography.displayLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        RecallrSpacing.gapXs,
        Text(
          'What needs your attention across your relationships?',
          style: RecallrTypography.bodyLarge.copyWith(
            color: RecallrColors.textSecondary,
          ),
        ),
      ],
    );
  }
}