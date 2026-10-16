import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Large universal memory query input card.
class MemoryQueryCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceTrigger;
  final bool isLoading;

  const MemoryQueryCard({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onClear,
    this.onVoiceTrigger,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: RecallrColors.aiElectricViolet.withAlpha(90),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: RecallrColors.aiElectricViolet,
                size: 20.0,
              ),
              RecallrSpacing.gapXs,
              Text(
                'Memory Query',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.aiCyanHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          RecallrSpacing.gapSm,
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 1,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textPrimary,
              fontSize: 15.0,
            ),
            cursorColor: RecallrColors.aiCyanHighlight,
            textInputAction: TextInputAction.search,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty && onSubmitted != null) {
                onSubmitted!(val.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Ask your memory (e.g. "What did I discuss with Priya?")...',
              hintStyle: RecallrTypography.bodyLarge.copyWith(
                color: RecallrColors.textTertiary,
                fontSize: 14.5,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          RecallrSpacing.gapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18.0, color: RecallrColors.textSecondary),
                      tooltip: 'Clear query',
                      onPressed: onClear,
                    ),
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, size: 18.0, color: RecallrColors.textSecondary),
                    tooltip: 'Voice Memo Query',
                    onPressed: onVoiceTrigger,
                  ),
                ],
              ),
              RecallrSpacing.gapXs,
              Flexible(
                child: RecallrButton(
                  label: 'Ask Memory',
                  variant: RecallrButtonVariant.aiGradient,
                  leadingIcon: Icons.auto_awesome_rounded,
                  isLoading: isLoading,
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty && onSubmitted != null) {
                      onSubmitted!(text);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}