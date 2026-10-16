import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';

/// Modal bottom sheet container with glass surface and drag handle.
class RecallrBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  const RecallrBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(
      RecallrSpacing.md,
      RecallrSpacing.sm,
      RecallrSpacing.md,
      RecallrSpacing.xl,
    ),
  });

  /// Helper to display this bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecallrBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RecallrColors.slateSurface,
        borderRadius: RecallrRadii.radiusTopSheet,
        border: Border(
          top: BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: RecallrColors.textTertiary.withAlpha(128),
                borderRadius: RecallrRadii.radiusPill,
              ),
            ),
          ),
          RecallrSpacing.gapMd,
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            RecallrSpacing.gapMd,
          ],
          Flexible(
            child: child,
          ),
        ],
      ),
    );
  }
}