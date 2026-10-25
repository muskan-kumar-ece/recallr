import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/app/app_shell.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/routing/recallr_routes.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_subscription_repository.dart';
import 'package:recaller/repositories/subscription_repository.dart';
import 'package:recaller/features/ask/widgets/ask_header.dart';
import 'package:recaller/features/subscription/models/subscription_models.dart';

Widget _buildHarness({
  required Widget child,
  SubscriptionRepository? subscriptionRepository,
  List<NavigatorObserver>? observers,
}) {
  final deps = RecallrDependencies.mock(
    subscriptionRepository: subscriptionRepository ?? MockSubscriptionRepository(),
  );

  return RecallrScope(
    dependencies: deps,
    child: MaterialApp(
      theme: RecallrTheme.darkTheme,
      navigatorObservers: observers ?? [],
      routes: {
        RecallrRoutes.subscription: (context) => const Scaffold(
              body: Text('Subscription Screen Destination'),
            ),
        RecallrRoutes.settings: (context) => const Scaffold(
              body: Text('Settings Screen Destination'),
            ),
      },
      home: child,
    ),
  );
}

class _TestNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

void main() {
  group('Subscription Navigation Direct Discoverability Tests', () {
    testWidgets('1. Top AppBar AI Credits Pill renders balance and navigates to /subscription', (tester) async {
      final observer = _TestNavigatorObserver();
      final mockSub = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter().copyWith(
          monthlyCreditsTotal: 50,
          monthlyCreditsUsed: 10,
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: const RecallrAppShell(initialIndex: 0),
          subscriptionRepository: mockSub,
          observers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      // Find the credits pill in the top AppBar
      final pillFinder = find.byKey(const ValueKey<String>('appbar_credits_pill'));
      expect(pillFinder, findsOneWidget);
      expect(find.text('40'), findsOneWidget); // 50 - 10 = 40 remaining

      // Tap on the credits pill
      await tester.tap(pillFinder);
      await tester.pumpAndSettle();

      // Verify navigation to Subscription Screen
      expect(find.text('Subscription Screen Destination'), findsOneWidget);
      expect(observer.pushedRoutes, contains(RecallrRoutes.subscription));
    });

    testWidgets('2. User Avatar Popup Menu offers Subscription & Storage and navigates to /subscription', (tester) async {
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        _buildHarness(
          child: const RecallrAppShell(initialIndex: 0),
          observers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      // Tap avatar popup button
      final avatarFinder = find.byType(PopupMenuButton<String>);
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Verify the Subscription menu item is present
      final menuItemFinder = find.byKey(const ValueKey<String>('menu_item_subscription'));
      expect(menuItemFinder, findsOneWidget);
      expect(find.text('Subscription & Storage'), findsOneWidget);

      // Tap the menu item
      await tester.tap(menuItemFinder);
      await tester.pumpAndSettle();

      // Verify navigation to Subscription Screen
      expect(find.text('Subscription Screen Destination'), findsOneWidget);
      expect(observer.pushedRoutes, contains(RecallrRoutes.subscription));
    });

    testWidgets('3. Desktop NavigationRail shows Subscription item and navigates to /subscription', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        _buildHarness(
          child: const RecallrAppShell(initialIndex: 0),
          observers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      final railButtonFinder = find.byKey(const ValueKey<String>('nav_rail_subscription_desktop'));
      expect(railButtonFinder, findsOneWidget);

      await tester.tap(railButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Subscription Screen Destination'), findsOneWidget);
      expect(observer.pushedRoutes, contains(RecallrRoutes.subscription));
    });

    testWidgets('4. Tablet NavigationRail shows Subscription icon and navigates to /subscription', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        _buildHarness(
          child: const RecallrAppShell(initialIndex: 0),
          observers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      final tabletIconFinder = find.byKey(const ValueKey<String>('nav_rail_subscription_tablet'));
      expect(tabletIconFinder, findsOneWidget);

      await tester.tap(tabletIconFinder);
      await tester.pumpAndSettle();

      expect(find.text('Subscription Screen Destination'), findsOneWidget);
      expect(observer.pushedRoutes, contains(RecallrRoutes.subscription));
    });

    testWidgets('5. AskHeader renders AI credits badge and navigates to /subscription', (tester) async {
      final observer = _TestNavigatorObserver();
      final mockSub = MockSubscriptionRepository(
        initial: UserSubscription.defaultStarter().copyWith(
          monthlyCreditsTotal: 100,
          monthlyCreditsUsed: 25,
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: AskHeader(),
            ),
          ),
          subscriptionRepository: mockSub,
          observers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      final creditsBadgeFinder = find.byKey(const ValueKey<String>('ask_header_credits_badge'));
      expect(creditsBadgeFinder, findsOneWidget);
      expect(find.text('75'), findsOneWidget); // 100 - 25 = 75 remaining

      await tester.tap(creditsBadgeFinder);
      await tester.pumpAndSettle();

      expect(find.text('Subscription Screen Destination'), findsOneWidget);
      expect(observer.pushedRoutes, contains(RecallrRoutes.subscription));
    });
  });
}
