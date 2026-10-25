import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/subscription/models/subscription_models.dart';
import '../../repositories/subscription_repository.dart';
import '../../services/payment/payment_service.dart';

/// Dark-First Pro Subscription, AI Credit, and Cloud Storage Management Screen.
class SubscriptionScreen extends StatefulWidget {
  final SubscriptionRepository? repository;
  final PaymentService? paymentService;

  const SubscriptionScreen({super.key, this.repository, this.paymentService});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  StreamSubscription<UserSubscription>? _subscriptionSub;
  UserSubscription? _subscription;
  bool _isLoading = true;
  bool _isAnnual = false;
  bool _isProcessing = false;

  SubscriptionRepository get _repo =>
      widget.repository ?? context.subscriptionRepo;

  PaymentService get _paymentService =>
      widget.paymentService ?? context.paymentService;

  @override
  void initState() {
    super.initState();
    _initSubscription();
  }

  void _initSubscription() {
    _subscriptionSub?.cancel();
    _subscriptionSub = _repo.streamSubscription().listen(
      (sub) {
        if (mounted) {
          setState(() {
            _subscription = sub;
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _subscription ??= UserSubscription.defaultStarter();
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscriptionSub?.cancel();
    super.dispose();
  }

  Future<void> _handleTopUp(CreditPack pack) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
      final result = await _paymentService.purchaseCreditPack(
        context: context,
        pack: pack,
        userEmail: user?.email,
        userPhone: user?.phoneNumber,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: RecallrColors.slateSurface,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: RecallrColors.emeraldVerified, size: 20),
                  RecallrSpacing.gapSm,
                  Text('Added ${pack.credits} AI credits to your account!'),
                ],
              ),
            ),
          );
        }
      } else if (result.isFailed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
            content: Text(result.errorMessage ?? 'Payment failed. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
            content: Text('Failed to complete top-up: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUpgrade(SubscriptionTier tier) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
      final result = await _paymentService.upgradeTier(
        context: context,
        tier: tier,
        isAnnual: _isAnnual,
        userEmail: user?.email,
        userPhone: user?.phoneNumber,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: RecallrColors.slateSurface,
              content: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: RecallrColors.aiElectricViolet, size: 20),
                  RecallrSpacing.gapSm,
                  Text('Upgraded to ${tier.displayName}!'),
                ],
              ),
            ),
          );
        }
      } else if (result.isFailed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
            content: Text(result.errorMessage ?? 'Upgrade failed. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
            content: Text('Failed to update plan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _toggleCurrency() {
    final newCurrency = (_subscription?.currency == 'USD') ? 'INR' : 'USD';
    _repo.setCurrency(newCurrency);
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subscription ?? UserSubscription.defaultStarter();

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: const Text('Subscription & Storage'),
        backgroundColor: RecallrColors.obsidianBase,
        elevation: 0,
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          TextButton.icon(
            onPressed: _toggleCurrency,
            icon: const Icon(Icons.currency_exchange_rounded, size: 16, color: RecallrColors.textSecondary),
            label: Text(
              sub.currency,
              style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          RecallrSpacing.gapSm,
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RecallrColors.aiElectricViolet))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: RecallrSpacing.pagePadding,
                  children: [
                    // 1. Current Plan Hero Card
                    _buildCurrentPlanHero(sub),
                    RecallrSpacing.gapLg,

                    // 2. Usage Meters (AI Credits + Cloud Storage)
                    _buildUsageMeters(sub),
                    RecallrSpacing.gapXl,

                    // 3. On-Demand Micro Credit Packs
                    _buildCreditPacksSection(sub),
                    RecallrSpacing.gapXl,

                    // 4. Plan Upgrade Comparison
                    _buildPlanComparisonSection(sub),
                    RecallrSpacing.gapXl,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanHero(UserSubscription sub) {
    final isPro = sub.tier == SubscriptionTier.pro;
    final isExec = sub.tier == SubscriptionTier.executive;

    final badgeColor = isExec
        ? RecallrColors.aiElectricViolet
        : (isPro ? RecallrColors.aiCyanHighlight : RecallrColors.textSecondary);

    return RecallrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(35),
                  borderRadius: RecallrRadii.radiusMd,
                  border: Border.all(color: badgeColor.withAlpha(80)),
                ),
                child: Icon(
                  isExec ? Icons.military_tech_rounded : (isPro ? Icons.workspace_premium_rounded : Icons.shield_outlined),
                  color: badgeColor,
                  size: 26,
                ),
              ),
              RecallrSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(sub.tier.displayName, style: RecallrTypography.headlineMedium),
                        RecallrSpacing.gapSm,
                        RecallrBadge(
                          text: sub.status.toUpperCase(),
                          variant: isPro || isExec ? RecallrBadgeVariant.verified : RecallrBadgeVariant.neutral,
                        ),
                      ],
                    ),
                    Text(
                      sub.tier.tagline,
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          RecallrSpacing.gapMd,
          const Divider(color: RecallrColors.borderSubtle, height: 1),
          RecallrSpacing.gapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Allowance',
                style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary),
              ),
              Text(
                '${sub.tier.monthlyCreditsTotal} AI queries · ${sub.tier.formattedStorageLimit} cloud storage',
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMeters(UserSubscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resource Quotas & Metering', style: RecallrTypography.titleMedium),
        RecallrSpacing.gapSm,

        // AI Credits Gauge
        RecallrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 18, color: RecallrColors.aiElectricViolet),
                      RecallrSpacing.gapSm,
                      Text('AI Intelligence Credits', style: RecallrTypography.titleMedium),
                    ],
                  ),
                  Text(
                    '${sub.totalAvailableCredits} Available',
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: sub.hasAiCredits ? RecallrColors.aiElectricViolet : RecallrColors.crimsonAlert,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              RecallrSpacing.gapSm,
              ClipRRect(
                borderRadius: RecallrRadii.radiusPill,
                child: LinearProgressIndicator(
                  value: sub.monthlyCreditsUsageRatio,
                  minHeight: 8,
                  backgroundColor: RecallrColors.slateSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    sub.totalAvailableCredits > 0 ? RecallrColors.aiElectricViolet : RecallrColors.crimsonAlert,
                  ),
                ),
              ),
              RecallrSpacing.gapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sub.monthlyCreditsUsed} of ${sub.monthlyCreditsTotal} monthly credits used',
                    style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                  ),
                  if (sub.purchasedCredits > 0)
                    Text(
                      '+${sub.purchasedCredits} non-expiring balance',
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.emeraldVerified, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
        ),
        RecallrSpacing.gapSm,

        // Cloud Storage Gauge
        RecallrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_queue_rounded, size: 18, color: RecallrColors.aiCyanHighlight),
                      RecallrSpacing.gapSm,
                      Text('Cloud Media Storage', style: RecallrTypography.titleMedium),
                    ],
                  ),
                  Text(
                    '${(sub.storageUsageRatio * 100).toStringAsFixed(1)}% Used',
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: sub.isStorageExceeded() ? RecallrColors.crimsonAlert : RecallrColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              RecallrSpacing.gapSm,
              ClipRRect(
                borderRadius: RecallrRadii.radiusPill,
                child: LinearProgressIndicator(
                  value: sub.storageUsageRatio,
                  minHeight: 8,
                  backgroundColor: RecallrColors.slateSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    sub.isStorageExceeded() ? RecallrColors.crimsonAlert : RecallrColors.aiCyanHighlight,
                  ),
                ),
              ),
              RecallrSpacing.gapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sub.formattedStorageUsed} of ${sub.formattedStorageLimit}',
                    style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                  ),
                  Text(
                    'Cards & Voice Memos',
                    style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditPacksSection(UserSubscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Micro Credit Top-Ups', style: RecallrTypography.titleMedium),
        Text(
          'Credits never expire · Use anytime when monthly plan credits run out',
          style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
        ),
        RecallrSpacing.gapMd,
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: CreditPack.values.map((pack) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildCreditPackCard(pack, sub),
                  );
                }).toList(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: CreditPack.values.map((pack) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildCreditPackCard(pack, sub),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreditPackCard(CreditPack pack, UserSubscription sub) {
    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: pack.isPopular ? RecallrColors.aiElectricViolet.withAlpha(150) : RecallrColors.borderSubtle,
          width: pack.isPopular ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pack.isPopular) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: RecallrColors.aiElectricViolet.withAlpha(40),
                borderRadius: RecallrRadii.radiusPill,
                border: Border.all(color: RecallrColors.aiElectricViolet.withAlpha(100)),
              ),
              child: Text(
                'POPULAR',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.aiElectricViolet,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            RecallrSpacing.gapSm,
          ],
          Text(pack.title, style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          Text(pack.subtitle, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
          RecallrSpacing.gapMd,
          Text(
            sub.formatCreditPackPrice(pack),
            style: RecallrTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          RecallrSpacing.gapMd,
          RecallrButton(
            label: 'Buy Pack',
            variant: pack.isPopular ? RecallrButtonVariant.primary : RecallrButtonVariant.secondary,
            leadingIcon: Icons.add_rounded,
            onPressed: () => _handleTopUp(pack),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanComparisonSection(UserSubscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('Upgrade Membership', style: RecallrTypography.titleMedium),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Annual (Save 20%)',
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: _isAnnual ? RecallrColors.emeraldVerified : RecallrColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                RecallrSpacing.gapSm,
                Switch.adaptive(
                  value: _isAnnual,
                  activeThumbColor: RecallrColors.emeraldVerified,
                  onChanged: (val) => setState(() => _isAnnual = val),
                ),
              ],
            ),
          ],
        ),
        RecallrSpacing.gapMd,
        _buildTierCard(
          tier: SubscriptionTier.pro,
          sub: sub,
          isHighlighted: true,
          perks: const [
            '1.5 GB Cloud Storage (~5,000 cards & audio)',
            '250 AI Credits every month',
            'Unlimited Professional Contacts',
            'Full vCard 3.0 & Markdown Export',
            'Priority OCR text extraction',
          ],
        ),
        RecallrSpacing.gapMd,
        _buildTierCard(
          tier: SubscriptionTier.executive,
          sub: sub,
          isHighlighted: false,
          perks: const [
            '6.0 GB Cloud Storage (~20,000 cards & audio)',
            '1,000 AI Credits every month',
            'Unlimited Contacts & Follow-ups',
            'Deep Network Graph Clustering',
            'Executive Briefings & VIP Support',
          ],
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required SubscriptionTier tier,
    required UserSubscription sub,
    required bool isHighlighted,
    required List<String> perks,
  }) {
    final isCurrent = sub.tier == tier;

    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: isHighlighted ? RecallrColors.aiCyanHighlight.withAlpha(160) : RecallrColors.borderSubtle,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.displayName, style: RecallrTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(tier.tagline, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                  ],
                ),
              ),
              RecallrSpacing.gapSm,
              Text(
                sub.formatPrice(tier, annual: _isAnnual),
                style: RecallrTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          RecallrSpacing.gapMd,
          const Divider(color: RecallrColors.borderSubtle, height: 1),
          RecallrSpacing.gapMd,
          ...perks.map((perk) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, color: RecallrColors.emeraldVerified, size: 18),
                    RecallrSpacing.gapSm,
                    Expanded(
                      child: Text(perk, style: RecallrTypography.bodyMedium),
                    ),
                  ],
                ),
              )),
          RecallrSpacing.gapLg,
          RecallrButton(
            label: isCurrent ? 'Active Plan' : 'Select ${tier.displayName}',
            variant: isCurrent ? RecallrButtonVariant.secondary : RecallrButtonVariant.primary,
            leadingIcon: isCurrent ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
            onPressed: isCurrent ? null : () => _handleUpgrade(tier),
          ),
        ],
      ),
    );
  }
}
