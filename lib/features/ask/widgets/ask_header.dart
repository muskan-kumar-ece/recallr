import 'package:flutter/material.dart';
import '../../../core/di/recallr_dependencies.dart';
import '../../../core/routing/recallr_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../subscription/models/subscription_models.dart';

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
        StreamBuilder<UserSubscription>(
          stream: context.subscriptionRepo.streamSubscription(),
          builder: (context, snapshot) {
            final sub = snapshot.data;
            final credits = sub?.totalAvailableCredits ?? 20;

            return Tooltip(
              message: 'AI Credits: $credits remaining\nTap to top up or upgrade',
              child: InkWell(
                key: const ValueKey<String>('ask_header_credits_badge'),
                onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.subscription),
                borderRadius: RecallrRadii.radiusPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusPill,
                    border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 15.0, color: RecallrColors.warmAmberGold),
                      const SizedBox(width: 4.0),
                      Text(
                        '$credits',
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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