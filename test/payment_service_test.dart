import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_subscription_repository.dart';
import 'package:recaller/features/subscription/models/subscription_models.dart';
import 'package:recaller/screens/settings/subscription_screen.dart';
import 'package:recaller/services/payment/mock_payment_service.dart';
import 'package:recaller/services/payment/payment_service.dart';

void main() {
  group('PaymentService & Results Unit Tests', () {
    test('PaymentResult status getters work accurately', () {
      final success = PaymentResult.success(orderId: 'o1', paymentId: 'p1', updatedCredits: 150);
      expect(success.isSuccess, isTrue);
      expect(success.isCancelled, isFalse);
      expect(success.isFailed, isFalse);
      expect(success.updatedCredits, equals(150));

      final cancelled = PaymentResult.cancelled(orderId: 'o2');
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isSuccess, isFalse);

      final failed = PaymentResult.failed(errorMessage: 'Network error', orderId: 'o3');
      expect(failed.isFailed, isTrue);
      expect(failed.errorMessage, equals('Network error'));
    });

    testWidgets('MockPaymentService purchaseCreditPack completes successfully', (tester) async {
      final repo = MockSubscriptionRepository();
      final paymentSvc = MockPaymentService(subscriptionRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final res = await paymentSvc.purchaseCreditPack(
                    context: context,
                    pack: CreditPack.pack150,
                  );
                  expect(res.isSuccess, isTrue);
                  expect(res.updatedCredits, equals(150));
                },
                child: const Text('Buy'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buy'));
      await tester.pumpAndSettle();

      final current = await repo.streamSubscription().first;
      expect(current.purchasedCredits, equals(150));
    });

    testWidgets('MockPaymentService upgradeTier updates subscription tier', (tester) async {
      final repo = MockSubscriptionRepository();
      final paymentSvc = MockPaymentService(subscriptionRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final res = await paymentSvc.upgradeTier(
                    context: context,
                    tier: SubscriptionTier.pro,
                    isAnnual: false,
                  );
                  expect(res.isSuccess, isTrue);
                },
                child: const Text('Upgrade'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      final current = await repo.streamSubscription().first;
      expect(current.tier, equals(SubscriptionTier.pro));
    });

    testWidgets('SubscriptionScreen triggers payment service top-up and displays SnackBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockSubscriptionRepository();
      final paymentSvc = MockPaymentService(subscriptionRepository: repo);
      final deps = RecallrDependencies.mock(
        subscriptionRepository: repo,
        paymentService: paymentSvc,
      );

      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: MaterialApp(
            theme: RecallrTheme.darkTheme,
            home: SubscriptionScreen(
              repository: repo,
              paymentService: paymentSvc,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Buy Pack" button and tap
      final buyPackButton = find.text('Buy Pack').first;
      await tester.ensureVisible(buyPackButton);
      await tester.pumpAndSettle();
      await tester.tap(buyPackButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Added 150 AI credits'), findsOneWidget);
      final updated = await repo.streamSubscription().first;
      expect(updated.purchasedCredits, equals(150));
    });
  });
}
