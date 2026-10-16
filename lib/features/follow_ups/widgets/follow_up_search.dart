import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Search input for filtering relationship commitments.
class FollowUpSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const FollowUpSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return RecallrSearchField(
      controller: controller,
      hintText: 'Search commitments & follow-ups...',
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}