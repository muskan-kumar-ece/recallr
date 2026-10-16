import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Header for Ask your memory.
class AskHeader extends StatelessWidget {
  final bool hasActiveAnswer;
  final VoidCallback? onNewConversation;

  const AskHeader({
    super.key,
    this.hasActiveAnswer = false,
    this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20.0,
                    color: RecallrColors.aiElectricViolet,
                  ),
                  RecallrSpacing.gapXs,
                  Expanded(
                    child: Text(
                      'Ask your memory',
                      style: RecallrTypography.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                'Find people, conversations, decisions, and context from everything Recallr remembers.',
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        RecallrSpacing.gapSm,
        if (hasActiveAnswer && onNewConversation != null)
          RecallrButton(
            label: 'New Question',
            variant: RecallrButtonVariant.secondary,
            leadingIcon: Icons.refresh_rounded,
            onPressed: onNewConversation,
          )
        else
          const RecallrBadge(
            text: 'GROUNDED MEMORY',
            variant: RecallrBadgeVariant.verified,
          ),
      ],
    );
  }
}