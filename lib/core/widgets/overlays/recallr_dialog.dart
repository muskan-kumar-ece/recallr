import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Modal dialog with custom dark styling, title, content, and action buttons.
class RecallrDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const RecallrDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  /// Helper to display this dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => RecallrDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RecallrColors.slateSurface,
      shape: RoundedRectangleBorder(
        borderRadius: RecallrRadii.radiusLg,
        side: const BorderSide(color: RecallrColors.borderHighlight, width: 1.0),
      ),
      insetPadding: const EdgeInsets.all(RecallrSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(RecallrSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: RecallrTypography.headlineMedium),
            RecallrSpacing.gapMd,
            content,
            RecallrSpacing.gapLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((a) => Padding(padding: const EdgeInsets.only(left: 8.0), child: a)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}