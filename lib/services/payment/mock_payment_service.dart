import 'package:flutter/widgets.dart';
import '../../features/subscription/models/subscription_models.dart';
import '../../repositories/subscription_repository.dart';
import 'payment_service.dart';

class MockPaymentService implements PaymentService {
  final SubscriptionRepository? subscriptionRepository;
  bool shouldSucceed;

  MockPaymentService({
    this.subscriptionRepository,
    this.shouldSucceed = true,
  });

  @override
  Future<PaymentResult> purchaseCreditPack({
    required BuildContext context,
    required CreditPack pack,
    String? userEmail,
    String? userPhone,
  }) async {
    if (!shouldSucceed) {
      return PaymentResult.failed(errorMessage: 'Mock payment failure triggered');
    }

    if (subscriptionRepository != null) {
      await subscriptionRepository!.purchaseCreditPack(pack);
    }

    return PaymentResult.success(
      orderId: 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      updatedCredits: pack.credits,
    );
  }

  @override
  Future<PaymentResult> upgradeTier({
    required BuildContext context,
    required SubscriptionTier tier,
    required bool isAnnual,
    String? userEmail,
    String? userPhone,
  }) async {
    if (!shouldSucceed) {
      return PaymentResult.failed(errorMessage: 'Mock payment failure triggered');
    }

    if (subscriptionRepository != null) {
      await subscriptionRepository!.upgradeTier(tier, annual: isAnnual);
    }

    return PaymentResult.success(
      orderId: 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      tier: tier.name,
    );
  }

  @override
  void dispose() {}
}
