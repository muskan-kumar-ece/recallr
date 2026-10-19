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

/// Header for People Directory with quick add capabilities.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4.0),
                Text(
                  'Your professional memory, organized around the people you know.',
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textSecondary,
                    fontSize: 12.5,
                  ),
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
    );
  }
}