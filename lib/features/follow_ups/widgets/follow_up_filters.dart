import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../models/follow_up_models.dart';

/// Horizontally scrollable filter chips for Follow-ups Hub.
class FollowUpFilters extends StatelessWidget {
  final FollowUpFilter selectedFilter;
  final ValueChanged<FollowUpFilter> onFilterSelected;

  const FollowUpFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FollowUpFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: RecallrChip(
              label: filter.label,
              isSelected: isSelected,
              onTap: () => onFilterSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}