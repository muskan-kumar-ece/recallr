import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/observability/observability.dart';
import 'package:recaller/core/release/release_candidate_config.dart';
import 'package:recaller/core/security/environment_config.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/data/mock/mock_gemini_ai_provider.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/relationship_memory_models.dart';
import 'package:recaller/services/ai/gemini/gemini_ai_configuration.dart';
import 'package:recaller/services/ai/gemini/gemini_grounded_answer_generator.dart';
import 'package:recaller/services/relationship_memory_service.dart';

void main() {
  group('Phase 13F-06: V1.0 Production Launch Monitoring & Post-Launch Reliability Tests', () {
    test('1. Idempotent Capture Retries: duplicate ID writes update without creating new documents', () async {
      final repo = MockCaptureRepository();
      const capture = CaptureItem(
        id: 'cap_rel_001',
        type: CaptureType.note,
        title: 'Initial Encounter Note',
        description: 'Met at Enterprise AI Summit',
        timestamp: '2026-08-28',
        targetRoute: '/capture/cap_rel_001',
      );

      final saved1 = await repo.saveCapture(capture);
      expect(saved1.id, equals('cap_rel_001'));
      expect(saved1.title, equals('Initial Encounter Note'));

      // Retry save with updated description
      const updatedCapture = CaptureItem(
        id: 'cap_rel_001',
        type: CaptureType.note,
        title: 'Initial Encounter Note',
        description: 'Updated: Discussed multi-agent orchestration architecture',
        timestamp: '2026-08-28',
        targetRoute: '/capture/cap_rel_001',
      );

      final saved2 = await repo.saveCapture(updatedCapture);
      expect(saved2.id, equals('cap_rel_001'));
      expect(saved2.description, contains('Updated: Discussed multi-agent'));

      final retrieved = await repo.getCapture('cap_rel_001');
      expect(retrieved?.description, contains('Updated: Discussed multi-agent'));
    });

    test('2. Idempotent Relationship Memory Enrichment: repeated enrichment does not duplicate metrics', () async {
      final personRepo = MockPersonDetailRepository();
      final relService = DeterministicRelationshipMemoryService(
        personDetailRepository: personRepo,
      );

      final person = PersonItem(
        id: 'per_rel_001',
        name: 'Sarah Chen',
        role: 'VP Engineering',
        company: 'Apex AI',
        initials: 'SC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const capture = CaptureItem(
        id: 'cap_rel_002',
        type: CaptureType.businessCard,
        title: 'Met Sarah Chen',
        description: 'Discussed Q4 expansion',
        timestamp: 'Today',
        targetRoute: '/capture/cap_rel_002',
      );

      // First enrichment
      final result1 = await relService.enrichMemory(
        capture: capture,
        person: person,
      );
      expect(result1.status, equals(RelationshipMemoryStatus.completed));
      final totalAfterFirst = result1.updatedProfile?.totalInteractions;
      expect(totalAfterFirst, isNotNull);

      // Second enrichment (simulating retry with identical capture)
      final result2 = await relService.enrichMemory(
        capture: capture,
        person: person,
      );
      expect(result2.status, equals(RelationshipMemoryStatus.completed));
      // Total interactions remains exactly the same because timeline item ID matches (idempotency)
      expect(result2.updatedProfile?.totalInteractions, equals(totalAfterFirst));
    });

    test('3. Gemini Grounded Generator: Empty context fast-path returns zero-hallucination empty response', () async {
      final mockProvider = MockGeminiAiProvider();
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(),
        provider: mockProvider,
      );

      final emptyContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Who is Dr. Unknown?'),
        assembledAt: DateTime.now(),
      );

      final answer = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Who is Dr. Unknown?'),
        context: emptyContext,
      );

      expect(answer.status, equals(AiAnswerStatus.empty));
      expect(answer.confidence, equals(0.0));
      expect(answer.evidence, isEmpty);
      // Zero API calls made
      expect(mockProvider.generateCalls, equals(0));
    });

    test('4. Gemini Grounded Generator: Malformed provider output falls back deterministically', () async {
      final mockProvider = MockGeminiAiProvider(
        shouldReturnMalformedJson: true,
      );

      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(),
        provider: mockProvider,
      );

      final contextWithMemory = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Tell me about Sarah Chen'),
        evidenceItems: [
          const MemoryEvidence(
            id: 'ev_001',
            sourceType: MemorySourceType.activity,
            sourceId: 'act_001',
            personId: 'per_001',
            personName: 'Sarah Chen',
            content: 'Sarah Chen is VP Engineering at Apex AI',
            relevanceScore: 0.9,
            matchReason: 'Person match',
          ),
        ],
        assembledAt: DateTime.now(),
      );

      final answer = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Tell me about Sarah Chen'),
        context: contextWithMemory,
      );

      // Should recover via deterministic fallback generator
      expect(answer.answer, isNotEmpty);
      expect(answer.status, equals(AiAnswerStatus.completed));
    });

    test('5. Telemetry deduplication suppresses high-frequency duplicate events within 5-second window', () {
      final telemetry = ProductionTelemetryService();

      final event1 = TelemetryEvent(
        name: 'capture_failed',
        feature: TelemetryFeature.capture,
        operation: 'upload_media',
        severity: TelemetrySeverity.error,
        safeErrorCategory: 'network_timeout',
      );

      final event2 = TelemetryEvent(
        name: 'capture_failed',
        feature: TelemetryFeature.capture,
        operation: 'upload_media',
        severity: TelemetrySeverity.error,
        safeErrorCategory: 'network_timeout',
      );

      telemetry.recordEvent(event1);
      telemetry.recordEvent(event2); // Should be deduplicated

      // Only 1 event logged in recent ring
      final recent = telemetry.getRecentEvents();
      expect(recent.length, equals(1));
    });

    test('6. Production Release Candidate Audit verifies complete readiness', () {
      final prodConfig = EnvironmentConfig.production(
        geminiApiKey: 'AIzaSyVerifiedProductionKey123',
      );

      final audit = ReleaseCandidateConfig.audit(config: prodConfig);
      expect(audit.isProductionReady, isTrue);
      expect(audit.validationErrors, isEmpty);
      expect(audit.featureReadiness['Authentication'], isTrue);
      expect(audit.featureReadiness['Deterministic_Fallback'], isTrue);
      expect(audit.featureReadiness['Security_Rules_Hardened'], isTrue);
    });
  });
}