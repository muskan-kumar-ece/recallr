import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Empty state widget for Follow-ups & Commitments Hub.
class FollowUpEmptyState extends StatelessWidget {
  final bool isSearchEmpty;
  final VoidCallback? onClearSearch;
  final VoidCallback? onCapture;

  const FollowUpEmptyState({
    super.key,
    required this.isSearchEmpty,
    this.onClearSearch,
    this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RecallrColors.slateSurface,
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 26.0,
                  color: RecallrColors.textSecondary,
                ),
              ),
              RecallrSpacing.gapMd,
              Text(
                'No follow-ups match your filters.',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapXs,
              Text(
                'Try clearing your search query or switching filter tabs to see active relationship commitments.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapLg,
              if (onClearSearch != null)
                RecallrButton(
                  label: 'Clear Search & Filters',
                  variant: RecallrButtonVariant.secondary,
                  leadingIcon: Icons.refresh_rounded,
                  onPressed: onClearSearch,
                ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RecallrColors.slateSurface,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 30.0,
                color: RecallrColors.aiCyanHighlight,
              ),
            ),
            RecallrSpacing.gapMd,
            Text(
              'No follow-ups yet',
              style: RecallrTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapXs,
            Text(
              'Recallr will surface commitments from the conversations and encounters you capture.',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapLg,
            RecallrButton(
              label: 'Capture First Encounter',
              variant: RecallrButtonVariant.primary,
              leadingIcon: Icons.add_circle_outline_rounded,
              onPressed: onCapture,
            ),
          ],
        ),
      ),
    );
  }
}