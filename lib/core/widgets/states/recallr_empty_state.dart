import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Contextual empty state with dark vector illustration/icon and guidance.
class RecallrEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const RecallrEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: RecallrColors.charcoalCard,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36.0, color: RecallrColors.textTertiary),
            ),
            RecallrSpacing.gapLg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: RecallrTypography.headlineMedium,
            ),
            RecallrSpacing.gapSm,
            Text(
              description,
              textAlign: TextAlign.center,
              style: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textSecondary),
            ),
            if (action != null) ...[
              RecallrSpacing.gapLg,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}