import 'package:flutter/widgets.dart';
import '../../features/subscription/models/subscription_models.dart';

enum PaymentStatus {
  success,
  cancelled,
  failed,
}

class PaymentResult {
  final PaymentStatus status;
  final String? orderId;
  final String? paymentId;
  final String? errorMessage;
  final int? updatedCredits;
  final String? tier;

  const PaymentResult({
    required this.status,
    this.orderId,
    this.paymentId,
    this.errorMessage,
    this.updatedCredits,
    this.tier,
  });

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailed => status == PaymentStatus.failed;

  factory PaymentResult.success({
    required String orderId,
    required String paymentId,
    int? updatedCredits,
    String? tier,
  }) =>
      PaymentResult(
        status: PaymentStatus.success,
        orderId: orderId,
        paymentId: paymentId,
        updatedCredits: updatedCredits,
        tier: tier,
      );

  factory PaymentResult.cancelled({String? orderId}) =>
      PaymentResult(status: PaymentStatus.cancelled, orderId: orderId);

  factory PaymentResult.failed({required String errorMessage, String? orderId}) =>
      PaymentResult(status: PaymentStatus.failed, errorMessage: errorMessage, orderId: orderId);
}

abstract class PaymentService {
  Future<PaymentResult> purchaseCreditPack({
    required BuildContext context,
    required CreditPack pack,
    String? userEmail,
    String? userPhone,
  });

  Future<PaymentResult> upgradeTier({
    required BuildContext context,
    required SubscriptionTier tier,
    required bool isAnnual,
    String? userEmail,
    String? userPhone,
  });

  void dispose();
}
