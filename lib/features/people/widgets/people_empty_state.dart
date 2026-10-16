import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';

/// Empty state for People Directory (supports initial onboarding & search empty states).
class PeopleEmptyState extends StatelessWidget {
  final bool isSearch;
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  const PeopleEmptyState({
    super.key,
    this.isSearch = false,
    this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearch) {
      return Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  color: RecallrColors.charcoalCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  color: RecallrColors.textSecondary,
                  size: 32.0,
                ),
              ),
              RecallrSpacing.gapMd,
              Text(
                'No remembered people found',
                style: RecallrTypography.headlineMedium.copyWith(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapXs,
              Text(
                searchQuery != null && searchQuery!.isNotEmpty
                    ? 'No contacts matched "$searchQuery". Try searching by skill, company, or event.'
                    : 'No contacts matched the selected filter.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 13.0,
                ),
                textAlign: TextAlign.center,
              ),
              if (onClearSearch != null) ...[
                RecallrSpacing.gapLg,
                RecallrButton(
                  label: 'Clear Search & Filters',
                  variant: RecallrButtonVariant.secondary,
                  onPressed: onClearSearch,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                shape: BoxShape.circle,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: RecallrColors.aiElectricViolet,
                size: 36.0,
              ),
            ),
            RecallrSpacing.gapLg,
            Text(
              'Your professional memory starts here.',
              style: RecallrTypography.headlineMedium.copyWith(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: Text(
                'Recallr organizes your relationship intelligence around every encounter. Scan a visiting card, record a voice memo, or log meeting notes to start.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 14.0,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            RecallrSpacing.gapXl,
            RecallrButton(
              label: 'Capture First Person',
              variant: RecallrButtonVariant.aiGradient,
              leadingIcon: Icons.add_rounded,
              onPressed: () {
                RecallrBottomSheet.show(
                  context: context,
                  child: const CaptureModal(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}