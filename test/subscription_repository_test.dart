import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/data/mock/mock_subscription_repository.dart';
import 'package:recaller/features/subscription/models/subscription_models.dart';

void main() {
  group('MockSubscriptionRepository', () {
    late MockSubscriptionRepository repo;

    setUp(() {
      repo = MockSubscriptionRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial subscription stream yields default Starter plan', () async {
      final sub = await repo.streamSubscription().first;
      expect(sub.tier, SubscriptionTier.starter);
      expect(sub.totalAvailableCredits, 20);
      expect(sub.storageLimitBytes, 104857600);
      expect(sub.storageUsedBytes, 0);
    });

    test('consumeCredit deducts from monthly allowance first', () async {
      final initial = await repo.getSubscription();
      expect(initial.monthlyCreditsUsed, 0);

      final success = await repo.consumeCredit(reason: 'ask_query', amount: 1);
      expect(success, isTrue);

      final updated = await repo.getSubscription();
      expect(updated.monthlyCreditsUsed, 1);
      expect(updated.remainingMonthlyCredits, 19);
      expect(updated.totalAvailableCredits, 19);
      expect(repo.ledger.length, 1);
      expect(repo.ledger.first.reason, 'ask_query');
    });

    test('consumeCredit consumes purchased credits when monthly is exhausted', () async {
      // Set 1 remaining monthly and 5 purchased credits
      final custom = UserSubscription.defaultStarter().copyWith(
        monthlyCreditsTotal: 20,
        monthlyCreditsUsed: 19,
        purchasedCredits: 5,
      );
      repo = MockSubscriptionRepository(initial: custom);

      // Consume 2 credits
      final success = await repo.consumeCredit(reason: 'ask_query', amount: 2);
      expect(success, isTrue);

      final updated = await repo.getSubscription();
      expect(updated.monthlyCreditsUsed, 20); // 1 consumed from monthly
      expect(updated.purchasedCredits, 4); // 1 consumed from purchased
      expect(updated.totalAvailableCredits, 4);
    });

    test('consumeCredit fails gracefully when insufficient credits', () async {
      final empty = UserSubscription.defaultStarter().copyWith(
        monthlyCreditsTotal: 20,
        monthlyCreditsUsed: 20,
        purchasedCredits: 0,
      );
      repo = MockSubscriptionRepository(initial: empty);

      final success = await repo.consumeCredit(reason: 'ask_query', amount: 1);
      expect(success, isFalse);

      final current = await repo.getSubscription();
      expect(current.totalAvailableCredits, 0);
    });

    test('purchaseCreditPack stacks purchased credits and appends ledger', () async {
      await repo.purchaseCreditPack(CreditPack.pack150);

      final sub = await repo.getSubscription();
      expect(sub.purchasedCredits, 150);
      expect(sub.totalAvailableCredits, 170); // 20 monthly + 150 purchased
      expect(repo.ledger.length, 1);
      expect(repo.ledger.first.type, 'credit');
      expect(repo.ledger.first.amount, 150);
      expect(repo.ledger.first.reason, 'pack_purchase');
    });

    test('updateStorageUsage increments and decrements correctly', () async {
      await repo.updateStorageUsage(deltaBytes: 500000);
      var sub = await repo.getSubscription();
      expect(sub.storageUsedBytes, 500000);

      await repo.updateStorageUsage(deltaBytes: -200000);
      sub = await repo.getSubscription();
      expect(sub.storageUsedBytes, 300000);

      // Clamps at zero on excessive decrement
      await repo.updateStorageUsage(deltaBytes: -1000000);
      sub = await repo.getSubscription();
      expect(sub.storageUsedBytes, 0);
    });

    test('upgradeTier resets monthly cycle and expands limits', () async {
      // Consume some starter credits
      await repo.consumeCredit(reason: 'test', amount: 5);

      await repo.upgradeTier(SubscriptionTier.pro, annual: true);
      final sub = await repo.getSubscription();

      expect(sub.tier, SubscriptionTier.pro);
      expect(sub.storageLimitBytes, SubscriptionTier.pro.storageLimitBytes);
      expect(sub.monthlyCreditsTotal, 250);
      expect(sub.monthlyCreditsUsed, 0); // Reset for new tier cycle
      expect(sub.totalAvailableCredits, 250);
      expect(sub.productId, 'pro_annual');
    });

    test('setCurrency updates active currency setting', () async {
      await repo.setCurrency('USD');
      final sub = await repo.getSubscription();
      expect(sub.currency, 'USD');
    });
  });
}
