import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Pill-shaped Smart Search Field with voice trigger and clear action.
class RecallrSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceTrigger;
  final bool autofocus;

  const RecallrSearchField({
    super.key,
    required this.controller,
    this.hintText = "Search people, companies, notes...",
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onVoiceTrigger,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: RecallrColors.slateSurface,
        borderRadius: RecallrRadii.radiusPill,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textPrimary),
          cursorColor: RecallrColors.aiCyanHighlight,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textTertiary),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: RecallrColors.textSecondary,
              size: 20.0,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18.0, color: RecallrColors.textSecondary),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                    tooltip: 'Clear search',
                  ),
                if (onVoiceTrigger != null)
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, size: 20.0, color: RecallrColors.aiCyanHighlight),
                    onPressed: onVoiceTrigger,
                    tooltip: 'Voice Search',
                  ),
              ],
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md),
          ),
        ),
      ),
    );
  }
}