import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Question composer card for Ask your memory.
class QuestionInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceTrigger;
  final bool isLoading;

  const QuestionInput({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onClear,
    this.onVoiceTrigger,
    this.isLoading = false,
  });

  @override
  State<QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends State<QuestionInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant QuestionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.trim().isNotEmpty;

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
            controller: widget.controller,
            maxLines: 4,
            minLines: 1,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textPrimary,
              fontSize: 15.0,
            ),
            cursorColor: RecallrColors.aiCyanHighlight,
            textInputAction: TextInputAction.send,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty && widget.onSubmitted != null && !widget.isLoading) {
                widget.onSubmitted!(val.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Ask anything about your professional memory...',
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
                  if (hasText)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18.0, color: RecallrColors.textSecondary),
                      tooltip: 'Clear input',
                      onPressed: widget.onClear,
                    ),
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, size: 18.0, color: RecallrColors.textSecondary),
                    tooltip: 'Voice memo query',
                    onPressed: widget.onVoiceTrigger,
                  ),
                ],
              ),
              RecallrSpacing.gapXs,
              Flexible(
                child: RecallrButton(
                  label: 'Ask Memory',
                  variant: RecallrButtonVariant.aiGradient,
                  leadingIcon: Icons.auto_awesome_rounded,
                  isLoading: widget.isLoading,
                  onPressed: hasText && !widget.isLoading
                      ? () {
                          final text = widget.controller.text.trim();
                          if (text.isNotEmpty && widget.onSubmitted != null) {
                            widget.onSubmitted!(text);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}