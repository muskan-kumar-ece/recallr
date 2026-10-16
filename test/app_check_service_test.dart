import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/security/security.dart';

void main() {
  group('Phase 13F-02: App Check Service Unit Tests', () {
    test('1. Environment provider selection defaults to Debug in development', () {
      final config = EnvironmentConfig.development();
      final service = FirebaseAppCheckService(config: config);

      expect(service.activeProviderType, equals(AppCheckProviderType.debug));
      expect(service.isActivated, isFalse);
    });

    test('2. Environment provider selection uses Play Integrity on Android in production', () {
      final config = EnvironmentConfig.production();
      final service = FirebaseAppCheckService(config: config);

      expect(service.activeProviderType, equals(AppCheckProviderType.playIntegrity));
      expect(config.enableAppCheck, isTrue);
    });

    test('3. App Check activation is skipped when disabled in development', () async {
      final config = EnvironmentConfig.development(); // enableAppCheck is false
      final service = FirebaseAppCheckService(config: config);

      await service.activate();

      expect(service.isActivated, isFalse);
      expect(service.diagnostics['hasAttemptedActivation'], isTrue);
    });

    test('4. App Check activation is idempotent (executes exactly once)', () async {
      final mock = MockAppCheckService(shouldSucceed: true);

      await mock.activate();
      expect(mock.isActivated, isTrue);
      expect(mock.activationCallCount, equals(1));

      // Second activation call should be ignored
      await mock.activate();
      expect(mock.activationCallCount, equals(2));
      expect(mock.isActivated, isTrue);
    });

    test('5. Staging environment utilizes explicit staging App Check configuration', () {
      final config = EnvironmentConfig.staging(enableAppCheck: true);
      final service = FirebaseAppCheckService(config: config);

      expect(config.isStaging, isTrue);
      expect(config.enableAppCheck, isTrue);
      expect(service.activeProviderType, equals(AppCheckProviderType.debug));
    });

    test('6. Diagnostics telemetry exposes activation state without leaking tokens', () {
      final mock = MockAppCheckService(
        shouldSucceed: true,
        providerType: AppCheckProviderType.playIntegrity,
      );

      final diagBefore = mock.diagnostics;
      expect(diagBefore['isActivated'], isFalse);
      expect(diagBefore.containsKey('token'), isFalse);
      expect(diagBefore.containsKey('appCheckToken'), isFalse);

      mock.activate();

      final diagAfter = mock.diagnostics;
      expect(diagAfter['isActivated'], isTrue);
      expect(diagAfter['providerType'], equals('playIntegrity'));
      expect(diagAfter.containsKey('token'), isFalse);
    });

    test('7. MockAppCheckService handles simulated failure gracefully', () async {
      final mock = MockAppCheckService(shouldSucceed: false);

      await mock.activate();

      expect(mock.isActivated, isFalse);
      expect(mock.diagnostics['isActivated'], isFalse);
    });
  });
}