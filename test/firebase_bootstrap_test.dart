import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/bootstrap/firebase_bootstrap.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/security/security.dart';

void main() {
  group('Phase 13F-02: Firebase Bootstrap Lifecycle Tests', () {
    test('1. FirebaseBootstrap succeeds with valid development configuration', () async {
      final mockAppCheck = MockAppCheckService(shouldSucceed: true);
      final devConfig = EnvironmentConfig.development();

      final result = await FirebaseBootstrap.initialize(
        configOverride: devConfig,
        appCheckOverride: mockAppCheck,
      );

      expect(result.isSuccess, isTrue);
      expect(result.config.isDevelopment, isTrue);
      expect(mockAppCheck.isActivated, isTrue);
      expect(result.dependencies, isNotNull);
    });

    test('2. FirebaseBootstrap halts when configuration validation fails for production', () async {
      const invalidProdConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: true, // Violation
        enableAppCheck: false,
      );

      final result = await FirebaseBootstrap.initialize(
        configOverride: invalidProdConfig,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Configuration Validation Error'));
      expect(result.dependencies, isNull);
    });

    test('3. FirebaseBootstrap accepts custom dependency overrides', () async {
      final mockAppCheck = MockAppCheckService(shouldSucceed: true);
      final customDeps = RecallrDependencies(
        peopleRepository: RecallrDependencies.mock().peopleRepository,
        personDetailRepository: RecallrDependencies.mock().personDetailRepository,
        activityRepository: RecallrDependencies.mock().activityRepository,
        followUpRepository: RecallrDependencies.mock().followUpRepository,
        captureRepository: RecallrDependencies.mock().captureRepository,
      );

      final result = await FirebaseBootstrap.initialize(
        configOverride: EnvironmentConfig.development(),
        appCheckOverride: mockAppCheck,
        dependenciesOverride: customDeps,
      );

      expect(result.isSuccess, isTrue);
      expect(identical(result.dependencies, customDeps), isTrue);
    });

    testWidgets('4. RecallrBootstrapErrorApp renders sanitized error surface on fatal bootstrap failure',
        (tester) async {
      const sensitiveErrorMessage =
          'Error connecting to users/usr_12345678901234567890/ with key AIzaSyA123456789012345678901234567890B';

      await tester.pumpWidget(
        const RecallrBootstrapErrorApp(errorMessage: sensitiveErrorMessage),
      );

      expect(find.text('Initialization Failure'), findsOneWidget);
      expect(
        find.textContaining('Recallr encountered a secure startup error'),
        findsOneWidget,
      );

      // Verify credentials and UIDs are sanitized from the UI display
      expect(find.textContaining('[REDACTED_API_KEY]'), findsOneWidget);
      expect(find.textContaining('AIzaSy'), findsNothing);
      expect(find.textContaining('usr_12345678901234567890'), findsNothing);
    });
  });
}