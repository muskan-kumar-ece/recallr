import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/activity_models.dart';

/// Horizontally scrollable filter chips for the Activity timeline.
class ActivityFilters extends StatelessWidget {
  final ActivityFilter selectedFilter;
  final ValueChanged<ActivityFilter> onFilterSelected;

  const ActivityFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ActivityFilter.values.map((filter) {
          final bool isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                filter.label,
                style: RecallrTypography.labelSmall.copyWith(
                  color: isSelected
                      ? RecallrColors.textPrimary
                      : RecallrColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filter),
              backgroundColor: RecallrColors.charcoalCard,
              selectedColor: RecallrColors.aiElectricViolet.withAlpha(60),
              checkmarkColor: RecallrColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: RecallrRadii.radiusPill,
                side: BorderSide(
                  color: isSelected
                      ? RecallrColors.aiElectricViolet
                      : RecallrColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}