import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Empty state when no captures are recorded yet.
class CaptureEmptyState extends StatelessWidget {
  const CaptureEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 28.0,
              color: RecallrColors.textTertiary.withAlpha(120),
            ),
            RecallrSpacing.gapSm,
            Text(
              'Your captured memories will appear here.',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}