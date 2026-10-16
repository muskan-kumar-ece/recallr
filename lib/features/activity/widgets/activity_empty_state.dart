import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';

/// Contextual empty states for Activity / Relationship Timeline.
class ActivityEmptyState extends StatelessWidget {
  final bool isSearchEmpty;
  final VoidCallback? onClearSearch;
  final VoidCallback? onCapture;

  const ActivityEmptyState({
    super.key,
    this.isSearchEmpty = false,
    this.onClearSearch,
    this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchEmpty) {
      return Center(
        child: Padding(
          padding: RecallrSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RecallrEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No activity matches this search.',
                description: 'Try searching for another person, topic, company, or reset your filters.',
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
        padding: RecallrSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RecallrEmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Your professional timeline is still quiet.',
              description: 'Captured encounters, meetings, calls, notes, and commitments will appear here in chronological context.',
            ),
            RecallrSpacing.gapLg,
            RecallrButton(
              label: 'Capture First Encounter',
              variant: RecallrButtonVariant.primary,
              leadingIcon: Icons.add_circle_outline_rounded,
              onPressed: () {
                if (onCapture != null) {
                  onCapture!();
                } else {
                  RecallrBottomSheet.show(
                    context: context,
                    child: const CaptureModal(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}