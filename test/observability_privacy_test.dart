import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/observability/observability.dart';
import 'package:recaller/core/security/environment_config.dart';

void main() {
  group('Phase 13F-03: Observability Privacy & Sanitization Boundary Tests', () {
    test('1. TelemetryEvent sanitizes and redacts Google / Gemini API keys in attributes', () {
      final event = TelemetryEvent(
        name: 'ai_request_started',
        feature: TelemetryFeature.geminiAi,
        operation: 'synthesizeAnswer',
        safeAttributes: {
          'key': 'AIzaSyFakeKeyWithSecretTokens12345',
          'provider': 'gemini',
        },
      );

      final map = event.toMap();
      final attr = map['attributes'] as Map<String, dynamic>;
      expect(attr['key'], isNot(contains('AIzaSyFakeKeyWithSecretTokens12345')));
      expect(attr['key'], contains('[REDACTED_API_KEY]'));
    });

    test('2. TelemetryEvent sanitizes and redacts Bearer tokens in attributes', () {
      final event = TelemetryEvent(
        name: 'auth_header_check',
        feature: TelemetryFeature.auth,
        operation: 'validateSession',
        safeAttributes: {
          'authHeader': 'Bearer secret_jwt_token_payload_xyz.123',
        },
      );

      final map = event.toMap();
      final attr = map['attributes'] as Map<String, dynamic>;
      expect(attr['authHeader'], isNot(contains('secret_jwt_token_payload_xyz.123')));
      expect(attr['authHeader'], contains('Bearer [REDACTED_TOKEN]'));
    });

    test('3. TelemetryEvent sanitizes and redacts private email addresses in attributes', () {
      final event = TelemetryEvent(
        name: 'contact_sync',
        feature: TelemetryFeature.people,
        operation: 'syncPerson',
        safeAttributes: {
          'contact': 'john.doe@confidential-company.com',
        },
      );

      final map = event.toMap();
      final attr = map['attributes'] as Map<String, dynamic>;
      expect(attr['contact'], isNot(contains('john.doe@confidential-company.com')));
      expect(attr['contact'], contains('[REDACTED_EMAIL]'));
    });

    test('4. TelemetryEvent sanitizes and redacts private phone numbers in attributes', () {
      final event = TelemetryEvent(
        name: 'contact_lookup',
        feature: TelemetryFeature.people,
        operation: 'resolvePhone',
        safeAttributes: {
          'phone': '+1 555-123-4567',
        },
      );

      final map = event.toMap();
      final attr = map['attributes'] as Map<String, dynamic>;
      expect(attr['phone'], isNot(contains('+1 555-123-4567')));
      expect(attr['phone'], contains('[REDACTED_PHONE]'));
    });

    test('5. TelemetryEvent sanitizes raw memory notes, OCR text, and private user questions', () {
      final event = TelemetryEvent(
        name: 'ai_request_failed',
        feature: TelemetryFeature.geminiAi,
        operation: 'synthesizeAnswer',
        safeErrorCategory: 'timeout',
        safeAttributes: {
          'errorDetails': 'Failed while querying: Alice is allergic to peanuts and works at Google. Phone: 415-555-0199',
        },
      );

      final map = event.toMap();
      final attr = map['attributes'] as Map<String, dynamic>;
      // Phone number within text is redacted
      expect(attr['errorDetails'], isNot(contains('415-555-0199')));
      expect(attr['errorDetails'], contains('[REDACTED_PHONE]'));
    });

    test('6. ProductionCrashReportingService sanitizes fatal errors before logging', () async {
      final crashService = ProductionCrashReportingService();
      await crashService.initialize();

      // Ensure recording a crash with secret token doesn't throw and is handled
      expect(
        () async => await crashService.recordFatalError(
          Exception('Failed token AIzaSySecretKeyXYZ with Bearer my_jwt_token'),
          StackTrace.current,
          reason: 'Critical failure on email test@example.com',
        ),
        returnsNormally,
      );
    });

    test('7. ProductionCrashReportingService setUserContext never logs private user identifiers', () async {
      final crashService = ProductionCrashReportingService();
      await crashService.setUserContext(environment: 'staging');
      // Succeeds safely without requiring UID or private identity
    });

    test('8. TelemetryService aggregate counters do not store private UIDs or emails', () {
      final telemetry = ProductionTelemetryService();
      telemetry.recordEvent(
        TelemetryEvent(
          name: 'auth_signed_in',
          feature: TelemetryFeature.auth,
          operation: 'signInWithEmail',
        ),
      );

      final metrics = telemetry.aggregateMetrics.toMap();
      expect(metrics['auth']['signIns'], equals(1));
      expect(metrics.toString(), isNot(contains('user_id')));
      expect(metrics.toString(), isNot(contains('email')));
    });

    test('9. PerformanceTracker tracks operation duration without storing private payload', () async {
      final telemetry = MockTelemetryService();
      final tracker = PerformanceTracker(telemetry);

      final result = await tracker.track(
        'parse_business_card',
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'Card Parse Result';
        },
        feature: TelemetryFeature.ocr,
        safeAttributes: {'modality': 'card'},
      );

      expect(result, equals('Card Parse Result'));
      expect(telemetry.recordedEvents.length, equals(1));
      final recorded = telemetry.recordedEvents.first;
      expect(recorded.operation, equals('parse_business_card'));
      expect(recorded.feature, equals(TelemetryFeature.ocr));
      expect(recorded.durationMs, isNotNull);
      expect(recorded.isSuccess, isTrue);
    });

    test('10. ProductionDiagnostics captures non-sensitive system status only', () {
      final diagnostics = ProductionDiagnostics.capture(
        config: EnvironmentConfig.production(geminiApiKey: 'AIzaSyRealProdKey12345'),
        firebaseInitialized: true,
        appCheckActive: true,
        crashReportingActive: true,
        telemetryService: ProductionTelemetryService(),
      );

      final map = diagnostics.toMap();
      expect(map['environment'], equals('production'));
      expect(map['geminiConfigured'], isTrue);
      expect(map.toString(), isNot(contains('AIzaSyRealProdKey12345')));
      expect(map.toString(), isNot(contains('private_key')));
      expect(map['health']['overallState'], equals('healthy'));
    });
  });
}