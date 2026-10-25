import '../features/subscription/models/subscription_models.dart';

/// Abstract contract for user subscription, storage quota, and AI credit operations.
abstract class SubscriptionRepository {
  /// Real-time stream of the current user's subscription and credit balance.
  Stream<UserSubscription> streamSubscription();

  /// Retrieve the current user's subscription snapshot.
  Future<UserSubscription> getSubscription();

  /// Increment or decrement the user's used cloud storage bytes.
  Future<void> updateStorageUsage({required int deltaBytes});

  /// Consume [amount] AI credit(s). Returns `true` if successful, `false` if insufficient credits.
  Future<bool> consumeCredit({
    required String reason,
    int amount = 1,
    Map<String, dynamic>? metadata,
  });

  /// Apply purchased top-up credits to user's balance.
  Future<void> purchaseCreditPack(CreditPack pack);

  /// Change/upgrade user's active subscription tier.
  Future<void> upgradeTier(SubscriptionTier tier, {bool annual = false});

  /// Set user's preferred pricing display currency ('INR' or 'USD').
  Future<void> setCurrency(String currency);
}
