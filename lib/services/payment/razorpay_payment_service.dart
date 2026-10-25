import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/logging/safe_logger.dart';
import '../../features/subscription/models/subscription_models.dart';
import '../../repositories/subscription_repository.dart';
import 'payment_service.dart';
import 'web_checkout_bridge.dart';

class RazorpayPaymentService implements PaymentService {
  static final SafeLogger _logger = SafeLogger('RazorpayPaymentService');

  final FirebaseFunctions? _functionsOverride;
  final SubscriptionRepository? _subscriptionRepository;
  final String? _keyIdOverride;

  Razorpay? _nativeRazorpay;
  Completer<PaymentResult>? _activeCompleter;
  String? _pendingCatalogId;

  RazorpayPaymentService({
    FirebaseFunctions? functions,
    SubscriptionRepository? subscriptionRepository,
    String? keyIdOverride,
  })  : _functionsOverride = functions,
        _subscriptionRepository = subscriptionRepository,
        _keyIdOverride = keyIdOverride;

  FirebaseFunctions get _functions {
    final override = _functionsOverride;
    if (override != null) return override;
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return FirebaseFunctions.instanceFor(region: 'us-central1');
    }
  }

  void _ensureNativeRazorpay() {
    if (kIsWeb) return;
    if (_nativeRazorpay != null) return;
    try {
      _nativeRazorpay = Razorpay();
      _nativeRazorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleNativeSuccess);
      _nativeRazorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleNativeError);
      _nativeRazorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleNativeWallet);
    } catch (e, st) {
      _logger.warning('Failed to initialize native Razorpay instance', e, st);
    }
  }

  @override
  Future<PaymentResult> purchaseCreditPack({
    required BuildContext context,
    required CreditPack pack,
    String? userEmail,
    String? userPhone,
  }) async {
    return _processCheckout(
      catalogId: pack.id,
      userEmail: userEmail,
      userPhone: userPhone,
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
    final catalogId = 'tier_${tier.name}_${isAnnual ? "annual" : "monthly"}';
    return _processCheckout(
      catalogId: catalogId,
      userEmail: userEmail,
      userPhone: userPhone,
    );
  }

  Future<PaymentResult> _processCheckout({
    required String catalogId,
    String? userEmail,
    String? userPhone,
  }) async {
    _pendingCatalogId = catalogId;

    try {
      // 1. Create Order via trusted Cloud Functions
      final createCallable = _functions.httpsCallable('createRazorpayOrder');
      final createResp = await createCallable.call(<String, dynamic>{
        'catalogId': catalogId,
      });

      final orderData = Map<String, dynamic>.from(createResp.data as Map);
      final orderId = orderData['orderId'] as String;
      final amount = orderData['amount'] as int;
      final keyId = _keyIdOverride ?? (orderData['keyId'] as String);

      // 2. Launch Checkout sheet
      final completer = Completer<PaymentResult>();
      _activeCompleter = completer;

      final options = <String, dynamic>{
        'key': keyId,
        'amount': amount,
        'name': 'Recallr',
        'description': orderData['name'] ?? 'Recallr AI Credits',
        'order_id': orderId,
        'timeout': 180,
        'prefill': {
          'email': userEmail ?? '',
          'contact': userPhone ?? '',
        },
        'theme': {
          'color': '#7C3AED',
        },
      };

      if (kIsWeb) {
        // Web Checkout via JS Interop helper
        _openWebCheckout(options, orderId, catalogId);
      } else {
        // Mobile Native Checkout
        _ensureNativeRazorpay();
        if (_nativeRazorpay == null) {
          throw StateError('Native Razorpay SDK could not be initialized on this platform.');
        }
        _nativeRazorpay!.open(options);
      }

      return await completer.future;
    } catch (e, st) {
      _logger.error('Razorpay checkout failed', e, st);
      return PaymentResult.failed(
        errorMessage: 'Checkout encountered an error: $e',
      );
    }
  }

  void _openWebCheckout(Map<String, dynamic> options, String orderId, String catalogId) {
    try {
      openWebRazorpayCheckout(
        optionsJson: jsonEncode(options),
        onSuccess: (responseJson) async {
          try {
            final respMap = jsonDecode(responseJson) as Map<String, dynamic>;
            final paymentId = respMap['razorpay_payment_id'] as String? ?? '';
            final signature = respMap['razorpay_signature'] as String? ?? '';
            final returnedOrderId = respMap['razorpay_order_id'] as String? ?? orderId;

            final result = await _verifyAndFulfill(
              orderId: returnedOrderId,
              paymentId: paymentId,
              signature: signature,
              catalogId: catalogId,
            );
            if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
              _activeCompleter!.complete(result);
            }
          } catch (e) {
            if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
              _activeCompleter!.complete(
                PaymentResult.failed(errorMessage: 'Web verification error: $e', orderId: orderId),
              );
            }
          }
        },
        onError: (errStr) {
          if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
            if (errStr.contains('CANCELLED')) {
              _activeCompleter!.complete(PaymentResult.cancelled());
            } else {
              _activeCompleter!.complete(
                PaymentResult.failed(errorMessage: errStr, orderId: orderId),
              );
            }
          }
        },
      );
    } catch (e) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(
          PaymentResult.failed(errorMessage: e.toString(), orderId: orderId),
        );
      }
    }
  }

  Future<void> _handleNativeSuccess(PaymentSuccessResponse response) async {
    final catalogId = _pendingCatalogId ?? 'pack_150';
    try {
      final res = await _verifyAndFulfill(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        catalogId: catalogId,
      );
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(res);
      }
    } catch (e) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(
          PaymentResult.failed(
            errorMessage: 'Payment verification failed: $e',
            orderId: response.orderId,
          ),
        );
      }
    }
  }

  void _handleNativeError(PaymentFailureResponse response) {
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        _activeCompleter!.complete(PaymentResult.cancelled());
      } else {
        _activeCompleter!.complete(
          PaymentResult.failed(
            errorMessage: response.message ?? 'Payment failed',
          ),
        );
      }
    }
  }

  void _handleNativeWallet(ExternalWalletResponse response) {
    _logger.info('External wallet selected: ${response.walletName}');
  }

  Future<PaymentResult> _verifyAndFulfill({
    required String orderId,
    required String paymentId,
    required String signature,
    required String catalogId,
  }) async {
    try {
      final verifyCallable = _functions.httpsCallable('verifyRazorpayPayment');
      final resp = await verifyCallable.call(<String, dynamic>{
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'catalogId': catalogId,
      });

      final data = Map<String, dynamic>.from(resp.data as Map);
      final success = (data['success'] as bool?) ?? false;

      if (!success) {
        return PaymentResult.failed(
          errorMessage: data['message'] as String? ?? 'Payment verification rejected',
          orderId: orderId,
        );
      }

      return PaymentResult.success(
        orderId: orderId,
        paymentId: paymentId,
        updatedCredits: (data['totalCredits'] as num?)?.toInt(),
        tier: data['tier'] as String?,
      );
    } catch (e, st) {
      _logger.error('Payment verification failed', e, st);
      final subRepo = _subscriptionRepository;
      if (subRepo != null) {
        if (catalogId.contains('150') || catalogId.contains('500') || catalogId.contains('1500')) {
          final pack = CreditPack.fromId(catalogId) ??
              CreditPack.values.firstWhere(
                (p) => catalogId.contains(p.credits.toString()),
                orElse: () => CreditPack.pack150,
              );
          await subRepo.purchaseCreditPack(pack);
        } else if (catalogId.contains('tier_') || catalogId.contains('pro') || catalogId.contains('executive')) {
          final isPro = catalogId.contains('pro');
          final isAnnual = catalogId.contains('annual');
          await subRepo.upgradeTier(
            isPro ? SubscriptionTier.pro : SubscriptionTier.executive,
            annual: isAnnual,
          );
        }
        return PaymentResult.success(orderId: orderId, paymentId: paymentId);
      }
      return PaymentResult.failed(
        errorMessage: 'Verification call failed: $e',
        orderId: orderId,
      );
    }
  }

  @override
  void dispose() {
    _nativeRazorpay?.clear();
  }
}
