import 'package:flutter/material.dart';
import '../../../core/widgets/inputs/recallr_search_field.dart';

/// People search input widget wrapping RecallrSearchField.
class PeopleSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const PeopleSearch({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return RecallrSearchField(
      controller: controller,
      hintText: 'Search people you remember (skills, companies, events)...',
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}