import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/data/mock/mock_subscription_repository.dart';
import 'package:recaller/features/subscription/models/subscription_models.dart';
import 'package:recaller/screens/settings/subscription_screen.dart';

void main() {
  Widget createTestWidget({required MockSubscriptionRepository repo}) {
    final deps = RecallrDependencies(
      peopleRepository: MockPeopleRepository(),
      personDetailRepository: MockPersonDetailRepository(),
      activityRepository: MockActivityRepository(),
      followUpRepository: MockFollowUpRepository(),
      captureRepository: MockCaptureRepository(),
      subscriptionRepository: repo,
    );

    return RecallrScope(
      dependencies: deps,
      child: MaterialApp(
        home: SubscriptionScreen(repository: repo),
      ),
    );
  }

  group('SubscriptionScreen Widget Tests', () {
    testWidgets('renders current plan hero, usage gauges, credit packs and tier options', (tester) async {
      final repo = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter().copyWith(
          monthlyCreditsUsed: 5,
          storageUsedBytes: 25 * 1024 * 1024,
        ),
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Title & Hero
      expect(find.text('Subscription & Storage'), findsOneWidget);
      expect(find.text('Starter'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Usage Meters
      expect(find.text('Resource Quotas & Metering'), findsOneWidget);
      expect(find.text('AI Intelligence Credits'), findsOneWidget);
      expect(find.text('15 Available'), findsOneWidget);
      expect(find.text('Cloud Media Storage'), findsOneWidget);
      expect(find.text('25.0 MB of 100 MB'), findsOneWidget);

      // Micro Credit Packs
      expect(find.text('Micro Credit Top-Ups'), findsOneWidget);
      expect(find.text('150 AI Credits'), findsOneWidget);
      expect(find.text('500 AI Credits'), findsOneWidget);
      expect(find.text('1,500 AI Credits'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);

      // Scroll to Tier Comparison
      final upgradeHeading = find.text('Upgrade Membership');
      await tester.scrollUntilVisible(upgradeHeading, 200);
      expect(upgradeHeading, findsOneWidget);
      expect(find.text('Pro Networker'), findsWidgets);
      expect(find.text('Executive'), findsOneWidget);
    });

    testWidgets('purchasing micro credit pack updates balance and displays SnackBar feedback', (tester) async {
      final repo = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter(),
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('20 Available'), findsOneWidget);

      // Find "Buy Pack" buttons and scroll to first
      final buyButtons = find.text('Buy Pack');
      expect(buyButtons, findsWidgets);

      await tester.ensureVisible(buyButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(buyButtons.first);
      await tester.pumpAndSettle();

      // Verify SnackBar
      expect(find.text('Added 150 AI credits to your account!'), findsOneWidget);

      // Scroll back up to verify updated balance in gauge (20 + 150 = 170)
      final balanceText = find.text('170 Available');
      await tester.scrollUntilVisible(balanceText, -200);
      expect(balanceText, findsOneWidget);
    });

    testWidgets('upgrading tier updates active plan badge and allowance', (tester) async {
      final repo = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter(),
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Starter'), findsOneWidget);

      // Scroll to "Select Pro Networker"
      final selectPro = find.text('Select Pro Networker');
      await tester.scrollUntilVisible(selectPro, 500);
      await tester.ensureVisible(selectPro);
      await tester.pumpAndSettle();

      await tester.tap(selectPro);
      await tester.pumpAndSettle();

      // Verify SnackBar
      expect(find.text('Upgraded to Pro Networker!'), findsOneWidget);

      // Button should now reflect Active Plan
      final activePlanText = find.text('Active Plan');
      expect(activePlanText, findsOneWidget);
    });

    testWidgets('currency toggle changes display between INR and USD', (tester) async {
      final repo = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter().copyWith(currency: 'INR'),
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Find currency button showing "INR"
      expect(find.text('INR'), findsOneWidget);
      expect(find.text('₹19'), findsOneWidget);

      // Tap currency toggle
      await tester.tap(find.text('INR'));
      await tester.pumpAndSettle();

      // Should now show USD prices
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('\$0.49'), findsOneWidget);
    });
  });
}
