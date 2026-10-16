import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Memory-aware activity search bar for Recallr Phase 09.
class ActivitySearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ActivitySearch({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return RecallrSearchField(
      controller: controller,
      hintText: 'Search your activity...',
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}