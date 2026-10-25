import 'package:flutter/material.dart';
import '../../features/subscription/models/subscription_models.dart';
import '../theme/theme.dart';
import 'buttons/recallr_button.dart';

enum QuotaType {
  aiCredits,
  cloudStorage,
}

/// Standardized Dark-First Pro modal displayed when a user exceeds their AI credits or storage quota.
/// Provides actionable 1-tap resolutions (top-up or upgrade) while never blocking essential offline operations.
class QuotaExceededDialog extends StatelessWidget {
  final QuotaType quotaType;
  final UserSubscription? subscription;
  final VoidCallback? onTopUpCredits;
  final VoidCallback? onUpgradePlan;
  final VoidCallback? onSaveWithoutPhoto;
  final VoidCallback? onDismiss;

  const QuotaExceededDialog({
    super.key,
    required this.quotaType,
    this.subscription,
    this.onTopUpCredits,
    this.onUpgradePlan,
    this.onSaveWithoutPhoto,
    this.onDismiss,
  });

  /// Static helper to display the modal easily from any screen or modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required QuotaType quotaType,
    UserSubscription? subscription,
    VoidCallback? onTopUpCredits,
    VoidCallback? onUpgradePlan,
    VoidCallback? onSaveWithoutPhoto,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => QuotaExceededDialog(
        quotaType: quotaType,
        subscription: subscription,
        onTopUpCredits: onTopUpCredits,
        onUpgradePlan: onUpgradePlan,
        onSaveWithoutPhoto: onSaveWithoutPhoto,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredits = quotaType == QuotaType.aiCredits;
    final isCurrencyUsd = subscription?.currency == 'USD';

    final iconColor = isCredits ? RecallrColors.aiElectricViolet : RecallrColors.warmAmberGold;
    final iconData = isCredits ? Icons.auto_awesome_rounded : Icons.cloud_off_rounded;

    final title = isCredits ? 'AI Credits Exhausted' : 'Cloud Storage Full';
    final description = isCredits
        ? 'You have used all available AI queries for this cycle. Top up instantly or upgrade to Pro for 250 monthly credits.'
        : 'You have reached your cloud storage limit (${subscription?.formattedStorageLimit ?? "100 MB"}). Upgrade to Pro for 1.5 GB or continue without cloud sync.';

    final topUpLabel = isCurrencyUsd ? 'Top Up 150 Credits (\$0.49)' : 'Top Up 150 Credits (₹19)';
    final upgradeLabel = isCurrencyUsd ? 'Upgrade to Pro (\$0.99/mo)' : 'Upgrade to Pro (₹49/mo)';

    return Dialog(
      backgroundColor: RecallrColors.charcoalCard,
      shape: RoundedRectangleBorder(
        borderRadius: RecallrRadii.radiusLg,
        side: const BorderSide(color: RecallrColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(35),
                      borderRadius: RecallrRadii.radiusMd,
                      border: Border.all(color: iconColor.withAlpha(80)),
                    ),
                    child: Icon(iconData, color: iconColor, size: 24),
                  ),
                  RecallrSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: RecallrTypography.headlineMedium.copyWith(fontSize: 18),
                        ),
                        Text(
                          isCredits ? 'Monthly limit reached' : 'Storage capacity reached',
                          style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              RecallrSpacing.gapMd,

              // Body Copy
              Text(
                description,
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary, height: 1.4),
              ),
              RecallrSpacing.gapLg,

              // Primary Action (Top-Up or Upgrade)
              if (isCredits) ...[
                RecallrButton(
                  label: topUpLabel,
                  variant: RecallrButtonVariant.primary,
                  leadingIcon: Icons.bolt_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onTopUpCredits != null) {
                      onTopUpCredits!();
                    } else {
                      Navigator.of(context).pushNamed('/subscription');
                    }
                  },
                ),
                RecallrSpacing.gapSm,
                RecallrButton(
                  label: upgradeLabel,
                  variant: RecallrButtonVariant.secondary,
                  leadingIcon: Icons.workspace_premium_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onUpgradePlan != null) {
                      onUpgradePlan!();
                    } else {
                      Navigator.of(context).pushNamed('/subscription');
                    }
                  },
                ),
              ] else ...[
                RecallrButton(
                  label: upgradeLabel,
                  variant: RecallrButtonVariant.primary,
                  leadingIcon: Icons.cloud_upload_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onUpgradePlan != null) {
                      onUpgradePlan!();
                    } else {
                      Navigator.of(context).pushNamed('/subscription');
                    }
                  },
                ),
                if (onSaveWithoutPhoto != null) ...[
                  RecallrSpacing.gapSm,
                  RecallrButton(
                    label: 'Save Contact Without Cloud Photo',
                    variant: RecallrButtonVariant.secondary,
                    leadingIcon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSaveWithoutPhoto!();
                    },
                  ),
                ],
              ],

              RecallrSpacing.gapSm,

              // Dismiss Text Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                child: Text(
                  'Dismiss',
                  style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
