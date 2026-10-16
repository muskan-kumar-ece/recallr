import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/observability/observability.dart';
import 'package:recaller/core/release/release_candidate_config.dart';
import 'package:recaller/core/security/environment_config.dart';
import 'package:recaller/core/security/production_configuration_validator.dart';

void main() {
  group('Phase 13F-05: Production Deployment & Activation Tests', () {
    test('1. Production environment strictly requires App Check and valid project', () {
      final validProd = EnvironmentConfig.production(
        geminiApiKey: 'AIzaSyProdKey_987654321',
      );

      final validationResult = ProductionConfigurationValidator.validate(validProd);
      expect(validationResult.isValid, isTrue);
      expect(validationResult.errors, isEmpty);
      expect(validProd.isProduction, isTrue);
      expect(validProd.useEmulators, isFalse);
    });

    test('2. Production rejects debug App Check provider type', () {
      final invalidAppCheckProd = EnvironmentConfig(
        environment: AppEnvironment.production,
        firebaseProjectId: 'recaller-prod',
        enableAppCheck: true,
        appCheckProviderType: AppCheckProviderType.debug, // VIOLATION
        geminiApiKey: 'AIzaSyProdKey_987654321',
      );

      final result = ProductionConfigurationValidator.validate(invalidAppCheckProd);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('DebugAppCheckProvider is strictly forbidden in production')),
        isTrue,
      );
    });

    test('3. Production environment rejects mock fallback in production', () {
      final mockFallbackProd = EnvironmentConfig(
        environment: AppEnvironment.production,
        firebaseProjectId: 'recaller-prod',
        enableAppCheck: true,
        appCheckProviderType: AppCheckProviderType.playIntegrity,
        allowMockFallback: true, // VIOLATION
      );

      final result = ProductionConfigurationValidator.validate(mockFallbackProd);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('Mock fallback is forbidden in production builds')),
        isTrue,
      );
    });

    test('4. Telemetry strictly filters private data from structured events', () {
      final safeEvent = TelemetryEvent(
        name: 'capture_completed',
        feature: TelemetryFeature.capture,
        operation: 'create_capture',
        safeAttributes: {
          'captureType': 'businessCard',
          'email': 'vip.executive@partner.com',
          'auth_token': 'Bearer secret_jwt_token',
        },
      );

      expect(safeEvent.safeAttributes['auth_token'], equals('Bearer [REDACTED_TOKEN]'));
      expect(safeEvent.safeAttributes['email'], equals('[REDACTED_EMAIL]'));
      expect(safeEvent.safeAttributes['captureType'], equals('businessCard'));
    });

    test('5. Production diagnostics produces zero secret credentials', () {
      final config = EnvironmentConfig.production(
        geminiApiKey: 'AIzaSySecretProductionKey123',
      );

      final diagnostics = ProductionDiagnostics.capture(
        config: config,
        appCheckActive: true,
      );

      final diagMap = diagnostics.toMap();
      expect(diagMap['environment'], equals('production'));
      expect(diagMap['geminiConfigured'], isTrue);
      // Ensure raw key is never present in diagnostics
      expect(diagMap.toString().contains('AIzaSySecretProductionKey123'), isFalse);
    });

    test('6. Release Candidate Config validates production feature readiness', () {
      final audit = ReleaseCandidateConfig.audit(
        config: EnvironmentConfig.production(
          geminiApiKey: 'AIzaSyProductionKeyVerified',
        ),
      );

      expect(audit.isProductionReady, isTrue);
      expect(audit.featureReadiness['Cloud_Storage_Media'], isTrue);
      expect(audit.featureReadiness['Deterministic_Fallback'], isTrue);
      expect(audit.featureReadiness['Security_Rules_Hardened'], isTrue);
      expect(audit.featureReadiness['Crash_Reporting'], isTrue);
    });
  });
}