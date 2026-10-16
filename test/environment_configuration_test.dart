import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/security/security.dart';

void main() {
  group('Phase 13F-02: Environment Configuration & Safety Validator Tests', () {
    test('1. AppEnvironment.fromEnvironment parses valid and custom values', () {
      expect(AppEnvironment.fromEnvironment('development'), equals(AppEnvironment.development));
      expect(AppEnvironment.fromEnvironment('dev'), equals(AppEnvironment.development));
      expect(AppEnvironment.fromEnvironment('staging'), equals(AppEnvironment.staging));
      expect(AppEnvironment.fromEnvironment('stage'), equals(AppEnvironment.staging));
      expect(AppEnvironment.fromEnvironment('production'), equals(AppEnvironment.production));
      expect(AppEnvironment.fromEnvironment('prod'), equals(AppEnvironment.production));
      expect(AppEnvironment.fromEnvironment('unknown_value'), equals(AppEnvironment.development));
    });

    test('2. EnvironmentConfig.development factory sets safe dev defaults', () {
      final config = EnvironmentConfig.development(useEmulators: true, emulatorHost: '10.0.2.2');

      expect(config.isDevelopment, isTrue);
      expect(config.useEmulators, isTrue);
      expect(config.emulatorHost, equals('10.0.2.2'));
      expect(config.enableVerboseLogging, isTrue);
      expect(config.allowMockFallback, isTrue);
      expect(config.enableAppCheck, isFalse);
    });

    test('3. EnvironmentConfig.staging factory sets staging defaults', () {
      final config = EnvironmentConfig.staging();

      expect(config.isStaging, isTrue);
      expect(config.useEmulators, isFalse);
      expect(config.firebaseProjectId, equals('recaller-staging'));
      expect(config.enableAppCheck, isTrue);
    });

    test('4. EnvironmentConfig.production factory enforces hardened production settings', () {
      final config = EnvironmentConfig.production(
        geminiApiKey: 'test_key',
        firebaseProjectId: 'recaller-prod',
      );

      expect(config.isProduction, isTrue);
      expect(config.useEmulators, isFalse);
      expect(config.enableAppCheck, isTrue);
      expect(config.allowMockFallback, isFalse);
      expect(config.enableVerboseLogging, isFalse);
      expect(config.appCheckProviderType, equals(AppCheckProviderType.playIntegrity));
    });

    test('5. ProductionConfigurationValidator passes valid production config', () {
      final config = EnvironmentConfig.production(
        geminiApiKey: 'valid_key',
        firebaseProjectId: 'recaller-prod-cluster',
      );

      final result = ProductionConfigurationValidator.validate(config);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('6. ProductionConfigurationValidator rejects emulators in production', () {
      const invalidConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: true, // Violation
        enableAppCheck: true,
        appCheckProviderType: AppCheckProviderType.playIntegrity,
        allowMockFallback: false,
      );

      final result = ProductionConfigurationValidator.validate(invalidConfig);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Emulators are strictly forbidden')), isTrue);
    });

    test('7. ProductionConfigurationValidator rejects DebugAppCheckProvider in production', () {
      const invalidConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: false,
        enableAppCheck: true,
        appCheckProviderType: AppCheckProviderType.debug, // Violation
        allowMockFallback: false,
      );

      final result = ProductionConfigurationValidator.validate(invalidConfig);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('DebugAppCheckProvider is strictly forbidden')), isTrue);
    });

    test('8. ProductionConfigurationValidator rejects disabled App Check in production', () {
      const invalidConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: false,
        enableAppCheck: false, // Violation
        appCheckProviderType: AppCheckProviderType.playIntegrity,
        allowMockFallback: false,
      );

      final result = ProductionConfigurationValidator.validate(invalidConfig);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('App Check must be enabled in production')), isTrue);
    });

    test('9. ProductionConfigurationValidator.validateOrThrow throws on production violations', () {
      const invalidConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: true,
        enableAppCheck: false,
      );

      expect(
        () => ProductionConfigurationValidator.validateOrThrow(invalidConfig),
        throwsA(isA<RecallrConfigurationException>()),
      );
    });

    test('10. FirebaseEmulatorHelper throws when called with production configuration', () async {
      final config = EnvironmentConfig.production();

      expect(
        () => FirebaseEmulatorHelper.connectIfEnabled(
          config,
        ),
        returnsNormally, // useEmulators is false, so it safely does nothing
      );

      const violatingConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        useEmulators: true,
      );

      expect(
        () => FirebaseEmulatorHelper.connectIfEnabled(violatingConfig),
        throwsA(isA<RecallrConfigurationException>()),
      );
    });
  });
}