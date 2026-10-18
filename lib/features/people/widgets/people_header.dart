import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Available sorting options for People Directory.
enum PeopleSortOption {
  recent,
  nameAsc,
  nameDesc,
  interactions,
}

extension PeopleSortOptionExt on PeopleSortOption {
  String get label {
    switch (this) {
      case PeopleSortOption.recent:
        return 'Recent Activity';
      case PeopleSortOption.nameAsc:
        return 'Name (A → Z)';
      case PeopleSortOption.nameDesc:
        return 'Name (Z → A)';
      case PeopleSortOption.interactions:
        return 'Most Interactions';
    }
  }

  IconData get icon {
    switch (this) {
      case PeopleSortOption.recent:
        return Icons.history_rounded;
      case PeopleSortOption.nameAsc:
        return Icons.sort_by_alpha_rounded;
      case PeopleSortOption.nameDesc:
        return Icons.sort_by_alpha_rounded;
      case PeopleSortOption.interactions:
        return Icons.trending_up_rounded;
    }
  }
}

/// Header for People Directory with sort and quick add capabilities.
class PeopleHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onAddPerson;
  final PeopleSortOption sortOption;
  final ValueChanged<PeopleSortOption>? onSortChanged;

  const PeopleHeader({
    super.key,
    required this.count,
    this.onAddPerson,
    this.sortOption = PeopleSortOption.recent,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        'People',
                        style: RecallrTypography.headlineMedium,
                      ),
                      RecallrBadge(
                        text: '$count REMEMBERED',
                        isDot: false,
                        variant: RecallrBadgeVariant.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Your professional memory, organized around the people you know.',
                    style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (onAddPerson != null) ...[
              RecallrSpacing.gapSm,
              RecallrButton(
                label: 'Add',
                leadingIcon: Icons.person_add_outlined,
                variant: RecallrButtonVariant.primary,
                onPressed: onAddPerson!,
              ),
            ],
          ],
        ),
        if (onSortChanged != null) ...[
          RecallrSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<PeopleSortOption>(
                initialValue: sortOption,
                onSelected: onSortChanged,
                color: RecallrColors.charcoalCard,
                shape: RoundedRectangleBorder(
                  borderRadius: RecallrRadii.radiusMd,
                  side: const BorderSide(color: RecallrColors.borderSubtle),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sortOption.icon, size: 14.0, color: RecallrColors.textSecondary),
                      const SizedBox(width: 6.0),
                      Text(
                        sortOption.label,
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16.0, color: RecallrColors.textTertiary),
                    ],
                  ),
                ),
                itemBuilder: (context) => PeopleSortOption.values.map((opt) {
                  final isSelected = opt == sortOption;
                  return PopupMenuItem<PeopleSortOption>(
                    value: opt,
                    child: Row(
                      children: [
                        Icon(opt.icon, size: 16.0, color: isSelected ? RecallrColors.aiCyanHighlight : RecallrColors.textSecondary),
                        const SizedBox(width: 8.0),
                        Text(
                          opt.label,
                          style: RecallrTypography.bodyMedium.copyWith(
                            color: isSelected ? RecallrColors.aiCyanHighlight : RecallrColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}