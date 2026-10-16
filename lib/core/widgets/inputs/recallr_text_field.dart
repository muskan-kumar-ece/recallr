import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Production-grade text field with obsidian/charcoal surface, 1px border, and focus highlight.
class RecallrTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const RecallrTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: RecallrTypography.titleMedium.copyWith(color: RecallrColors.textSecondary),
          ),
          RecallrSpacing.gapSm,
        ],
        Container(
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusMd,
            border: Border.all(
              color: errorText != null ? RecallrColors.crimsonAlert : RecallrColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            autofocus: autofocus,
            maxLines: maxLines,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            style: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textPrimary),
            cursorColor: RecallrColors.aiCyanHighlight,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textTertiary),
              prefixIcon: prefix,
              suffixIcon: suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: RecallrSpacing.md,
                vertical: RecallrSpacing.md,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: RecallrSpacing.xs, left: RecallrSpacing.xs),
            child: Text(
              errorText!,
              style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.crimsonAlert),
            ),
          ),
        ],
      ],
    );
  }
}