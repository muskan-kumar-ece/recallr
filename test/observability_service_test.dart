import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/observability/observability.dart';
import 'package:recaller/core/security/environment_config.dart';

void main() {
  group('Phase 13F-03: Observability Services & Telemetry Lifecycle Tests', () {
    test('1. ProductionTelemetryService initializes and stores recent events', () async {
      final telemetry = ProductionTelemetryService();
      await telemetry.initialize();

      final event = TelemetryEvent(
        name: 'app_started',
        feature: TelemetryFeature.bootstrap,
        operation: 'initialize',
        severity: TelemetrySeverity.info,
      );

      telemetry.recordEvent(event);
      final events = telemetry.getRecentEvents();
      expect(events.length, equals(1));
      expect(events.first.name, equals('app_started'));
    });

    test('2. TelemetryEvent updates FeatureHealthMetrics across all domains correctly', () {
      final telemetry = ProductionTelemetryService();

      // People
      telemetry.recordEvent(TelemetryEvent(
        name: 'people_read',
        feature: TelemetryFeature.people,
        operation: 'getPeople',
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'people_write',
        feature: TelemetryFeature.people,
        operation: 'writePerson',
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'people_denied',
        feature: TelemetryFeature.people,
        operation: 'readPerson',
        safeErrorCategory: 'permissionDenied',
      ));

      // Capture & Storage
      telemetry.recordEvent(TelemetryEvent(
        name: 'capture_created',
        feature: TelemetryFeature.capture,
        operation: 'createCapture',
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'capture_saved',
        feature: TelemetryFeature.capture,
        operation: 'saveCapture',
        isSuccess: true,
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'storage_upload_success',
        feature: TelemetryFeature.storage,
        operation: 'uploadMedia',
        isSuccess: true,
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'storage_upload_failed',
        feature: TelemetryFeature.storage,
        operation: 'uploadMedia',
        isSuccess: false,
      ));

      // OCR & Entity Resolution
      telemetry.recordEvent(TelemetryEvent(
        name: 'ocr_success',
        feature: TelemetryFeature.ocr,
        operation: 'extractText',
        isSuccess: true,
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'entity_matched',
        feature: TelemetryFeature.entityResolution,
        operation: 'resolve',
        isSuccess: true,
        safeAttributes: {'status': 'exactMatch'},
      ));

      // Relationship Memory & Follow-ups
      telemetry.recordEvent(TelemetryEvent(
        name: 'rel_enriched',
        feature: TelemetryFeature.relationshipMemory,
        operation: 'enrich',
        isSuccess: true,
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'follow_up_created',
        feature: TelemetryFeature.followUp,
        operation: 'addFollowUp',
        isSuccess: true,
      ));

      // AI & Gemini
      telemetry.recordEvent(TelemetryEvent(
        name: 'ai_question',
        feature: TelemetryFeature.geminiAi,
        operation: 'answerQuestion',
        isSuccess: true,
        safeAttributes: {'answerState': 'grounded'},
      ));
      telemetry.recordEvent(TelemetryEvent(
        name: 'ai_fallback_used',
        feature: TelemetryFeature.geminiAi,
        operation: 'fallback',
        isSuccess: true,
      ));

      // Auth
      telemetry.recordEvent(TelemetryEvent(
        name: 'auth_signed_in',
        feature: TelemetryFeature.auth,
        operation: 'signIn',
      ));

      final metrics = telemetry.aggregateMetrics;
      expect(metrics.peopleReads, equals(2));
      expect(metrics.peopleWrites, equals(1));
      expect(metrics.peoplePermissionDenied, equals(1));
      expect(metrics.capturesStarted, equals(1));
      expect(metrics.capturesSaved, equals(1));
      expect(metrics.mediaUploadsSuccess, equals(1));
      expect(metrics.mediaUploadsFailed, equals(1));
      expect(metrics.ocrSuccess, equals(1));
      expect(metrics.entityMatched, equals(1));
      expect(metrics.relationshipEnriched, equals(1));
      expect(metrics.followUpsCreated, equals(1));
      expect(metrics.aiQuestions, equals(1));
      expect(metrics.aiGroundedAnswers, equals(1));
      expect(metrics.geminiFallback, equals(1));
      expect(metrics.authSignIns, equals(1));
    });

    test('3. High-frequency warning and error telemetry events are deduplicated within window', () {
      final telemetry = ProductionTelemetryService();

      // Emit 5 identical error events rapidly
      for (int i = 0; i < 5; i++) {
        telemetry.recordEvent(
          TelemetryEvent(
            name: 'storage_unavailable',
            feature: TelemetryFeature.storage,
            operation: 'uploadMedia',
            severity: TelemetrySeverity.error,
            isSuccess: false,
            safeErrorCategory: 'network_timeout',
          ),
        );
      }

      final recent = telemetry.getRecentEvents();
      // First event emitted, remaining 4 suppressed by deduplication window
      expect(recent.length, equals(1));
    });

    test('4. PerformanceTracker rethrows errors while recording failure telemetry', () async {
      final telemetry = MockTelemetryService();
      final tracker = PerformanceTracker(telemetry);

      bool didThrow = false;
      try {
        await tracker.track(
          'failing_operation',
          () async {
            throw const FormatException('Malformed payload');
          },
          feature: TelemetryFeature.retrieval,
        );
      } catch (e) {
        didThrow = true;
        expect(e, isA<FormatException>());
      }
      expect(didThrow, isTrue);

      expect(telemetry.recordedEvents.length, equals(1));
      final recorded = telemetry.recordedEvents.first;
      expect(recorded.isSuccess, isFalse);
      expect(recorded.safeErrorCategory, equals('FormatException'));
    });

    test('5. MockCrashReportingService captures errors and records context for unit testing', () async {
      final mockCrash = MockCrashReportingService();
      await mockCrash.initialize();
      expect(mockCrash.isInitialized, isTrue);

      await mockCrash.recordError(Exception('Sample non-fatal'), StackTrace.empty, reason: 'Test context');
      await mockCrash.recordFatalError(Exception('Sample fatal'), StackTrace.empty, reason: 'Fatal context');
      await mockCrash.setUserContext(environment: 'staging');

      expect(mockCrash.recordedErrors.length, equals(2));
      expect(mockCrash.recordedErrors[0].fatal, isFalse);
      expect(mockCrash.recordedErrors[1].fatal, isTrue);
      expect(mockCrash.environmentContext, equals('staging'));

      mockCrash.clear();
      expect(mockCrash.recordedErrors.isEmpty, isTrue);
    });

    test('6. MockTelemetryService records events and supports reset', () async {
      final mockTelemetry = MockTelemetryService();
      await mockTelemetry.initialize();
      expect(mockTelemetry.isInitialized, isTrue);

      mockTelemetry.recordEvent(
        TelemetryEvent(
          name: 'test_event',
          feature: TelemetryFeature.system,
          operation: 'noop',
        ),
      );

      expect(mockTelemetry.recordedEvents.length, equals(1));
      mockTelemetry.clear();
      expect(mockTelemetry.recordedEvents.isEmpty, isTrue);
    });

    test('7. ComponentHealth and SystemHealthReport calculate overall system state correctly', () {
      final healthyComponent = ComponentHealth(
        name: 'Database',
        state: HealthState.healthy,
        latencyMs: 12,
      );
      final degradedComponent = ComponentHealth(
        name: 'AI Engine',
        state: HealthState.degraded,
        message: 'Rate limits high',
      );

      final report = SystemHealthReport(
        overallState: HealthState.degraded,
        components: [healthyComponent, degradedComponent],
      );

      final map = report.toMap();
      expect(map['overallState'], equals('degraded'));
      expect((map['components'] as List).length, equals(2));
    });

    test('8. ProductionDiagnostics accurately reflects degraded state when components fail', () {
      final diagnostics = ProductionDiagnostics.capture(
        config: EnvironmentConfig.development(),
        firebaseInitialized: false, // Core failure
        appCheckActive: false,
        crashReportingActive: true,
      );

      expect(diagnostics.healthReport.overallState, equals(HealthState.unavailable));
    });
  });
}