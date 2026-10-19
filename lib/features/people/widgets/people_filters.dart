import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';
import '../models/person_item.dart';

/// Horizontal filter bar for People Directory.
class PeopleFilters extends StatelessWidget {
  final PeopleFilterOption selectedFilter;
  final ValueChanged<PeopleFilterOption> onSelected;

  const PeopleFilters({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.0,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: PeopleFilterOption.values.length,
        separatorBuilder: (context, index) => RecallrSpacing.gapSm,
        itemBuilder: (context, index) {
          final option = PeopleFilterOption.values[index];
          final isSelected = option == selectedFilter;

          return RecallrChip(
            label: option.label,
            leadingIcon: option.icon,
            isSelected: isSelected,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }
}