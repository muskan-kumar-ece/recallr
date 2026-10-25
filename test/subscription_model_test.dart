import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/features/subscription/models/subscription_models.dart';

void main() {
  group('SubscriptionTier', () {
    test('tier defaults and limits match accessible monetization specification', () {
      expect(SubscriptionTier.starter.monthlyPriceInr, 0);
      expect(SubscriptionTier.starter.monthlyPriceUsd, 0.0);
      expect(SubscriptionTier.starter.storageLimitBytes, 104857600); // 100 MB
      expect(SubscriptionTier.starter.monthlyCreditsTotal, 20);
      expect(SubscriptionTier.starter.maxContacts, 50);
      expect(SubscriptionTier.starter.formattedStorageLimit, '100 MB');

      expect(SubscriptionTier.pro.monthlyPriceInr, 49);
      expect(SubscriptionTier.pro.annualPriceInr, 399);
      expect(SubscriptionTier.pro.monthlyPriceUsd, 0.99);
      expect(SubscriptionTier.pro.storageLimitBytes, 1610612736); // 1.5 GB
      expect(SubscriptionTier.pro.monthlyCreditsTotal, 250);
      expect(SubscriptionTier.pro.isUnlimitedContacts, isTrue);
      expect(SubscriptionTier.pro.formattedStorageLimit, '1.5 GB');

      expect(SubscriptionTier.executive.monthlyPriceInr, 149);
      expect(SubscriptionTier.executive.annualPriceInr, 1299);
      expect(SubscriptionTier.executive.monthlyPriceUsd, 1.99);
      expect(SubscriptionTier.executive.storageLimitBytes, 6442450944); // 6.0 GB
      expect(SubscriptionTier.executive.monthlyCreditsTotal, 1000);
      expect(SubscriptionTier.executive.isUnlimitedContacts, isTrue);
      expect(SubscriptionTier.executive.formattedStorageLimit, '6.0 GB');
    });

    test('fromId parses case-insensitively with Starter fallback', () {
      expect(SubscriptionTier.fromId('PRO'), SubscriptionTier.pro);
      expect(SubscriptionTier.fromId('executive'), SubscriptionTier.executive);
      expect(SubscriptionTier.fromId('starter'), SubscriptionTier.starter);
      expect(SubscriptionTier.fromId('unknown_tier'), SubscriptionTier.starter);
      expect(SubscriptionTier.fromId(null), SubscriptionTier.starter);
    });
  });

  group('CreditPack', () {
    test('micro credit pack constants match ~30% net margin specification', () {
      expect(CreditPack.pack150.credits, 150);
      expect(CreditPack.pack150.priceInr, 19);
      expect(CreditPack.pack150.priceUsd, 0.49);

      expect(CreditPack.pack500.credits, 500);
      expect(CreditPack.pack500.priceInr, 49);
      expect(CreditPack.pack500.priceUsd, 0.99);
      expect(CreditPack.pack500.isPopular, isTrue);

      expect(CreditPack.pack1500.credits, 1500);
      expect(CreditPack.pack1500.priceInr, 129);
      expect(CreditPack.pack1500.priceUsd, 1.99);
    });

    test('fromId finds valid pack or returns null', () {
      expect(CreditPack.fromId('credit_pack_150'), CreditPack.pack150);
      expect(CreditPack.fromId('credit_pack_500'), CreditPack.pack500);
      expect(CreditPack.fromId('credit_pack_1500'), CreditPack.pack1500);
      expect(CreditPack.fromId('invalid_id'), isNull);
    });
  });

  group('UserSubscription', () {
    test('defaultStarter initializes with 100 MB and 20 monthly credits', () {
      final sub = UserSubscription.defaultStarter();
      expect(sub.tier, SubscriptionTier.starter);
      expect(sub.status, 'active');
      expect(sub.currency, 'INR');
      expect(sub.storageLimitBytes, 104857600);
      expect(sub.storageUsedBytes, 0);
      expect(sub.monthlyCreditsTotal, 20);
      expect(sub.monthlyCreditsUsed, 0);
      expect(sub.purchasedCredits, 0);
      expect(sub.remainingMonthlyCredits, 20);
      expect(sub.totalAvailableCredits, 20);
      expect(sub.hasAiCredits, isTrue);
      expect(sub.storageUsageRatio, 0.0);
    });

    test('credit calculations handle partial usage and top-ups correctly', () {
      final now = DateTime.now();
      final sub = UserSubscription(
        tier: SubscriptionTier.starter,
        storageLimitBytes: 104857600,
        monthlyCreditsTotal: 20,
        monthlyCreditsUsed: 15,
        purchasedCredits: 50,
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 30)),
        updatedAt: now,
      );

      expect(sub.remainingMonthlyCredits, 5);
      expect(sub.totalAvailableCredits, 55);
      expect(sub.hasAiCredits, isTrue);
      expect(sub.monthlyCreditsUsageRatio, 0.75);
    });

    test('credit calculations when monthly limit is exhausted', () {
      final now = DateTime.now();
      final sub = UserSubscription(
        tier: SubscriptionTier.starter,
        storageLimitBytes: 104857600,
        monthlyCreditsTotal: 20,
        monthlyCreditsUsed: 20,
        purchasedCredits: 10,
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 30)),
        updatedAt: now,
      );

      expect(sub.remainingMonthlyCredits, 0);
      expect(sub.totalAvailableCredits, 10);
      expect(sub.hasAiCredits, isTrue);

      final fullyExhausted = sub.copyWith(purchasedCredits: 0);
      expect(fullyExhausted.remainingMonthlyCredits, 0);
      expect(fullyExhausted.totalAvailableCredits, 0);
      expect(fullyExhausted.hasAiCredits, isFalse);
    });

    test('storage quota and formatting calculations', () {
      final now = DateTime.now();
      final sub = UserSubscription(
        tier: SubscriptionTier.starter,
        storageLimitBytes: 104857600, // 100 MB
        storageUsedBytes: 52428800, // 50 MB
        monthlyCreditsTotal: 20,
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 30)),
        updatedAt: now,
      );

      expect(sub.formattedStorageUsed, '50.0 MB');
      expect(sub.formattedStorageLimit, '100 MB');
      expect(sub.storageUsageRatio, 0.5);
      expect(sub.isStorageExceeded(10 * 1024 * 1024), isFalse);
      expect(sub.isStorageExceeded(60 * 1024 * 1024), isTrue); // 50 + 60 > 100
    });

    test('currency formatting works seamlessly for INR and USD', () {
      final inrSub = UserSubscription.defaultStarter().copyWith(currency: 'INR');
      expect(inrSub.formatPrice(SubscriptionTier.pro), '₹49/mo');
      expect(inrSub.formatPrice(SubscriptionTier.pro, annual: true), '₹399/yr');
      expect(inrSub.formatCreditPackPrice(CreditPack.pack150), '₹19');

      final usdSub = inrSub.copyWith(currency: 'USD');
      expect(usdSub.formatPrice(SubscriptionTier.pro), '\$0.99/mo');
      expect(usdSub.formatPrice(SubscriptionTier.pro, annual: true), '\$7.99/yr');
      expect(usdSub.formatCreditPackPrice(CreditPack.pack150), '\$0.49');
    });

    test('serialization round-trip preserves all fields', () {
      final now = DateTime.utc(2026, 10, 25, 12, 0, 0);
      final sub = UserSubscription(
        tier: SubscriptionTier.pro,
        status: 'active',
        currency: 'USD',
        storageLimitBytes: SubscriptionTier.pro.storageLimitBytes,
        storageUsedBytes: 12450000,
        monthlyCreditsTotal: 250,
        monthlyCreditsUsed: 42,
        purchasedCredits: 150,
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 30)),
        billingProvider: 'store',
        productId: 'pro_monthly_99',
        updatedAt: now,
      );

      final map = sub.toMap();
      final restored = UserSubscription.fromMap(map);

      expect(restored.tier, SubscriptionTier.pro);
      expect(restored.status, 'active');
      expect(restored.currency, 'USD');
      expect(restored.storageLimitBytes, SubscriptionTier.pro.storageLimitBytes);
      expect(restored.storageUsedBytes, 12450000);
      expect(restored.monthlyCreditsTotal, 250);
      expect(restored.monthlyCreditsUsed, 42);
      expect(restored.purchasedCredits, 150);
      expect(restored.productId, 'pro_monthly_99');
    });
  });

  group('CreditLedgerEntry', () {
    test('serialization round-trip', () {
      final now = DateTime.utc(2026, 10, 25, 14, 0, 0);
      final entry = CreditLedgerEntry(
        id: 'tx_123',
        timestamp: now,
        type: 'debit',
        amount: 1,
        reason: 'ask_query',
        metadata: {'model': 'gemini-1.5-flash'},
      );

      final map = entry.toMap();
      final restored = CreditLedgerEntry.fromMap(map, 'tx_123');

      expect(restored.id, 'tx_123');
      expect(restored.type, 'debit');
      expect(restored.amount, 1);
      expect(restored.reason, 'ask_query');
      expect(restored.metadata?['model'], 'gemini-1.5-flash');
    });
  });
}
