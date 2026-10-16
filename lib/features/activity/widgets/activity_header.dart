import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Editorial Activity Header for Recallr Phase 09.
class ActivityHeader extends StatelessWidget {
  const ActivityHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 24.0,
              color: RecallrColors.aiElectricViolet,
            ),
            RecallrSpacing.gapXs,
            Text(
              'Activity',
              style: RecallrTypography.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Your professional memory, in chronological context.',
          style: RecallrTypography.bodyMedium.copyWith(
            color: RecallrColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}