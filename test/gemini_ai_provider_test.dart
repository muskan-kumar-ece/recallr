import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_gemini_ai_provider.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/features/ask/widgets/grounded_answer_card.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/screens/ask/ask_screen.dart';
import 'package:recaller/services/ai/gemini/gemini_ai_configuration.dart';
import 'package:recaller/services/ai/gemini/gemini_ai_provider.dart';
import 'package:recaller/services/ai/gemini/gemini_grounded_answer_generator.dart';
import 'package:recaller/services/ai/gemini/gemini_prompt_builder.dart';
import 'package:recaller/services/ai/gemini/gemini_response_parser.dart';
import 'package:recaller/services/ai/gemini/grounded_answer_validator.dart';

void main() {
  group('Phase 13E-03: Gemini AI Configuration Tests', () {
    test('1. Default configuration has conservative grounding parameters', () {
      const config = GeminiAiConfiguration();
      expect(config.apiKey, isEmpty);
      expect(config.model, equals('gemini-1.5-flash'));
      expect(config.temperature, equals(0.2));
      expect(config.maxOutputTokens, equals(1024));
      expect(config.timeout, equals(const Duration(seconds: 15)));
      expect(config.maxRetries, equals(2));
      expect(config.isConfigured, isFalse);
    });

    test('2. Custom configuration and copyWith work as expected', () {
      final config = const GeminiAiConfiguration(apiKey: 'test-key')
          .copyWith(temperature: 0.1, model: 'gemini-1.5-pro');
      expect(config.apiKey, equals('test-key'));
      expect(config.model, equals('gemini-1.5-pro'));
      expect(config.temperature, equals(0.1));
      expect(config.isConfigured, isTrue);
    });

    test('3. Configuration toMap exports complete debug structure', () {
      const config = GeminiAiConfiguration(apiKey: 'secret-key');
      final map = config.toMap();
      expect(map['model'], equals('gemini-1.5-flash'));
      expect(map['temperature'], equals(0.2));
      expect(map['isConfigured'], isTrue);
      // Ensure API key is NEVER exposed in toMap
      expect(map.containsKey('apiKey'), isFalse);
    });
  });

  group('Phase 13E-03: Gemini Prompt Builder Tests', () {
    const builder = GeminiPromptBuilder();

    test('4. Injects strict 12 anti-hallucination system rules', () {
      final query = const MemoryQuery(rawQuery: 'Who is Sarah Chen?');
      final context = MemoryContext(query: query, assembledAt: DateTime.now());
      final request = const AiAnswerRequest(query: 'Who is Sarah Chen?');

      final prompt = builder.build(request: request, context: context);
      expect(prompt.systemInstruction, contains('Grounding Invariant'));
      expect(prompt.systemInstruction, contains('Anti-Hallucination'));
      expect(prompt.systemInstruction, contains('Zero Citation Fabrication'));
      expect(prompt.userPrompt, contains('OUTPUT JSON SCHEMA'));
    });

    test('5. Formats target person, query intent, and capabilities', () {
      final query = const MemoryQuery(
        rawQuery: 'Tell me about Sarah Chen',
        intent: MemoryQueryIntent.personLookup,
      );
      final person = PersonItem(
        id: 'p_1',
        name: 'Sarah Chen',
        role: 'VP of AI',
        company: 'Mosaic AI',
        initials: 'SC',
        capabilities: const ['LLM Architecture', 'Team Leadership'],
        relationshipType: RelationshipContextType.collaborator,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final context = MemoryContext(
        query: query,
        targetPerson: person,
        assembledAt: DateTime.now(),
      );
      final request = const AiAnswerRequest(query: 'Tell me about Sarah Chen');

      final prompt = builder.build(request: request, context: context);
      expect(prompt.userPrompt, contains('Sarah Chen (VP of AI at Mosaic AI)'));
      expect(prompt.userPrompt, contains('LLM Architecture, Team Leadership'));
      expect(prompt.userPrompt, contains('Query Intent: personLookup'));
    });

    test('6. Formats candidate evidence items and enforces context budget', () {
      final query = const MemoryQuery(rawQuery: 'What did we discuss?');
      final evidenceItems = List<MemoryEvidence>.generate(
        20,
        (i) => MemoryEvidence(
          id: 'ev_$i',
          sourceType: MemorySourceType.activity,
          sourceId: 'act_$i',
          content: 'Discussed project roadmap item $i in detail with the engineering team.',
          relevanceScore: 0.90 - (i * 0.02),
          matchReason: 'Relevance match',
        ),
      );

      final context = MemoryContext(
        query: query,
        evidenceItems: evidenceItems,
        assembledAt: DateTime.now(),
      );
      final request = const AiAnswerRequest(query: 'What did we discuss?', maxEvidence: 5);

      final prompt = builder.build(request: request, context: context, maxEvidence: 5);
      expect(prompt.userPrompt, contains('act_0'));
      expect(prompt.userPrompt, contains('act_4'));
      expect(prompt.userPrompt, isNot(contains('act_6')));
    });

    test('7. Excludes sensitive internal storage paths and metadata', () {
      final query = const MemoryQuery(rawQuery: 'Find file');
      final context = MemoryContext(
        query: query,
        evidenceItems: [
          const MemoryEvidence(
            id: 'ev_1',
            sourceType: MemorySourceType.capture,
            sourceId: 'cap_1',
            content: 'Visiting card scan for John Doe',
            relevanceScore: 0.85,
            matchReason: 'Keyword match',
          ),
        ],
        assembledAt: DateTime.now(),
      );
      final request = const AiAnswerRequest(query: 'Find file');

      final prompt = builder.build(request: request, context: context);
      expect(prompt.userPrompt, isNot(contains('gs://')));
      expect(prompt.userPrompt, isNot(contains('firebase_storage')));
      expect(prompt.userPrompt, isNot(contains('users/')));
    });
  });

  group('Phase 13E-03: Gemini Response Parser Tests', () {
    const parser = GeminiResponseParser();

    test('8. Parses clean valid JSON structured response', () {
      const rawJson = '''
{
  "answer": "Sarah Chen is the VP of AI at Mosaic AI leading LLM systems.",
  "confidence": 0.92,
  "evidenceIds": ["act_1", "p_1"],
  "mentionedPeople": [
    {"personId": "p_1", "name": "Sarah Chen"}
  ],
  "suggestedActions": ["View full profile", "Schedule sync"]
}
''';
      final parsed = parser.parse(rawJson);
      expect(parsed.isSuccess, isTrue);
      expect(parsed.answer, equals('Sarah Chen is the VP of AI at Mosaic AI leading LLM systems.'));
      expect(parsed.confidence, equals(0.92));
      expect(parsed.evidenceIds, equals(['act_1', 'p_1']));
      expect(parsed.mentionedPeople.first['personId'], equals('p_1'));
      expect(parsed.suggestedActions.length, equals(2));
    });

    test('9. Parses markdown fenced JSON blocks safely', () {
      const fenced = '''
```json
{
  "answer": "Priya Sharma discussed RISC-V compute architecture.",
  "confidence": 0.88,
  "evidenceIds": ["act_10"],
  "mentionedPeople": [{"personId": "p_2", "name": "Priya Sharma"}],
  "suggestedActions": []
}
```
''';
      final parsed = parser.parse(fenced);
      expect(parsed.isSuccess, isTrue);
      expect(parsed.answer, contains('RISC-V'));
      expect(parsed.confidence, equals(0.88));
      expect(parsed.evidenceIds, equals(['act_10']));
    });

    test('10. Handles malformed or broken JSON safely without throwing', () {
      const malformed = 'This is not json: { "answer": incomplete';
      final parsed = parser.parse(malformed);
      expect(parsed.isSuccess, isFalse);
      expect(parsed.errorMessage, isNotNull);
      expect(parsed.answer, isEmpty);
      expect(parsed.confidence, equals(0.0));
    });

    test('11. Handles empty string response gracefully', () {
      final parsed = parser.parse('');
      expect(parsed.isSuccess, isFalse);
      expect(parsed.errorMessage, contains('empty'));
    });

    test('12. Clamps invalid confidence numbers to [0.0, 1.0]', () {
      const overConf = '{"answer": "Test", "confidence": 1.75}';
      final parsedOver = parser.parse(overConf);
      expect(parsedOver.confidence, equals(1.0));

      const negConf = '{"answer": "Test", "confidence": -0.5}';
      final parsedNeg = parser.parse(negConf);
      expect(parsedNeg.confidence, equals(0.0));
    });
  });

  group('Phase 13E-03: Grounded Answer Validator Tests', () {
    const validator = GroundedAnswerValidator();

    final query = const MemoryQuery(rawQuery: 'Who is Sarah?');
    final person = PersonItem(
      id: 'p_1',
      name: 'Sarah Chen',
      role: 'VP of AI',
      company: 'Mosaic AI',
      initials: 'SC',
      relationshipType: RelationshipContextType.collaborator,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final context = MemoryContext(
      query: query,
      targetPerson: person,
      evidenceItems: [
        const MemoryEvidence(
          id: 'ev_1',
          sourceType: MemorySourceType.activity,
          sourceId: 'act_1',
          personId: 'p_1',
          personName: 'Sarah Chen',
          content: 'Discussed architecture roadmap',
          relevanceScore: 0.85,
          matchReason: 'Person match',
        ),
      ],
      assembledAt: DateTime.now(),
    );
    final request = const AiAnswerRequest(query: 'Who is Sarah?');

    test('13. Accepts valid evidence IDs matching Recallr context', () {
      final parsed = const ParsedGeminiAnswer(
        answer: 'Sarah Chen is VP of AI.',
        confidence: 0.90,
        evidenceIds: ['act_1'],
        mentionedPeople: [{'personId': 'p_1', 'name': 'Sarah Chen'}],
      );

      final answer = validator.validate(parsed: parsed, context: context, request: request);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.evidence.any((e) => e.sourceId == 'act_1'), isTrue);
    });

    test('14. Critical Anti-Hallucination: Rejects unknown evidence IDs invented by Gemini', () {
      final parsed = const ParsedGeminiAnswer(
        answer: 'Sarah Chen is VP of AI.',
        confidence: 0.90,
        evidenceIds: ['hallucinated_doc_999', 'unknown_act_777'],
        mentionedPeople: [{'personId': 'p_1', 'name': 'Sarah Chen'}],
      );

      final answer = validator.validate(parsed: parsed, context: context, request: request);
      // Must not contain the hallucinated IDs
      expect(answer.evidence.any((e) => e.sourceId == 'hallucinated_doc_999'), isFalse);
      expect(answer.evidence.any((e) => e.sourceId == 'unknown_act_777'), isFalse);
      // Fallback retains candidate context
      expect(answer.evidence.any((e) => e.sourceId == 'act_1'), isTrue);
    });

    test('15. Critical Anti-Hallucination: Drops hallucinated people not in context', () {
      final parsed = const ParsedGeminiAnswer(
        answer: 'Sarah Chen and John Doe met yesterday.',
        confidence: 0.90,
        evidenceIds: ['act_1'],
        mentionedPeople: [
          {'personId': 'p_1', 'name': 'Sarah Chen'},
          {'personId': 'p_fake', 'name': 'John Doe'},
        ],
      );

      final answer = validator.validate(parsed: parsed, context: context, request: request);
      expect(answer.mentionedPeople.any((p) => p.name == 'Sarah Chen'), isTrue);
      expect(answer.mentionedPeople.any((p) => p.name == 'John Doe'), isFalse);
    });

    test('16. Confidence is calibrated and capped by deterministic evidence score', () {
      final parsed = const ParsedGeminiAnswer(
        answer: 'Sarah Chen is VP of AI.',
        confidence: 0.99, // Artificially high
        evidenceIds: ['act_1'],
      );

      final answer = validator.validate(parsed: parsed, context: context, request: request);
      expect(answer.confidence, lessThanOrEqualTo(1.0));
      expect(answer.confidence, greaterThan(0.0));
    });

    test('17. Empty context yields AiAnswerStatus.empty with 0.0 confidence', () {
      final emptyContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Unknown query'),
        assembledAt: DateTime.now(),
      );
      final parsed = const ParsedGeminiAnswer(
        answer: 'Some generated hallucination text',
        confidence: 0.85,
        evidenceIds: ['unknown_1'],
      );

      final answer = validator.validate(
        parsed: parsed,
        context: emptyContext,
        request: const AiAnswerRequest(query: 'Unknown query'),
      );
      expect(answer.status, equals(AiAnswerStatus.empty));
      expect(answer.confidence, equals(0.0));
      expect(answer.evidence, isEmpty);
    });
  });

  group('Phase 13E-03: Mock Gemini Provider Tests', () {
    test('18. Tracks generate calls and records prompts', () async {
      final mockProvider = MockGeminiAiProvider();
      expect(mockProvider.generateCalls, equals(0));

      final res = await mockProvider.generate(
        systemInstruction: 'System test',
        prompt: 'User test prompt',
      );
      expect(mockProvider.generateCalls, equals(1));
      expect(mockProvider.recordedPrompts.first, equals('User test prompt'));
      expect(mockProvider.recordedSystemInstructions.first, equals('System test'));
      expect(res.text, contains('Mock Gemini grounded answer'));
    });

    test('19. Simulates timeout exception', () async {
      final mockProvider = MockGeminiAiProvider(shouldTimeout: true);
      expect(
        () => mockProvider.generate(systemInstruction: '', prompt: ''),
        throwsA(isA<GeminiTimeoutException>()),
      );
    });

    test('20. Simulates rate limit exception (HTTP 429)', () async {
      final mockProvider = MockGeminiAiProvider(shouldRateLimit: true);
      expect(
        () => mockProvider.generate(systemInstruction: '', prompt: ''),
        throwsA(isA<GeminiRateLimitException>()),
      );
    });

    test('21. Simulates provider unavailable exception', () async {
      final mockProvider = MockGeminiAiProvider(shouldBeUnavailable: true);
      expect(
        () => mockProvider.generate(systemInstruction: '', prompt: ''),
        throwsA(isA<GeminiUnavailableException>()),
      );
    });

    test('22. Simulates malformed JSON return', () async {
      final mockProvider = MockGeminiAiProvider(shouldReturnMalformedJson: true);
      final res = await mockProvider.generate(systemInstruction: '', prompt: '');
      expect(res.text, contains('This is not valid JSON'));
    });
  });

  group('Phase 13E-03: Gemini Grounded Answer Generator & Fallback Tests', () {
    final query = const MemoryQuery(
      rawQuery: 'Who is Sarah Chen?',
      intent: MemoryQueryIntent.personLookup,
    );
    final person = PersonItem(
      id: 'p_1',
      name: 'Sarah Chen',
      role: 'VP of AI',
      company: 'Mosaic AI',
      initials: 'SC',
      relationshipType: RelationshipContextType.collaborator,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final context = MemoryContext(
      query: query,
      targetPerson: person,
      evidenceItems: [
        const MemoryEvidence(
          id: 'ev_1',
          sourceType: MemorySourceType.activity,
          sourceId: 'act_1',
          personId: 'p_1',
          personName: 'Sarah Chen',
          content: 'Discussed architecture roadmap',
          relevanceScore: 0.85,
          matchReason: 'Person match',
        ),
      ],
      assembledAt: DateTime.now(),
    );
    final request = const AiAnswerRequest(query: 'Who is Sarah Chen?');

    test('23. Fast path: returns empty answer immediately on empty context', () async {
      final mockProvider = MockGeminiAiProvider();
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'key'),
        provider: mockProvider,
      );

      final emptyContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Nothing'),
        assembledAt: DateTime.now(),
      );

      final answer = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Nothing'),
        context: emptyContext,
      );

      expect(answer.status, equals(AiAnswerStatus.empty));
      expect(answer.confidence, equals(0.0));
      // Proves no API call was wasted
      expect(mockProvider.generateCalls, equals(0));
    });

    test('24. Successful end-to-end Gemini generation with valid structured output', () async {
      final mockProvider = MockGeminiAiProvider(
        forcedResponseText: '''
{
  "answer": "Sarah Chen is the VP of AI at Mosaic AI.",
  "confidence": 0.90,
  "evidenceIds": ["act_1"],
  "mentionedPeople": [{"personId": "p_1", "name": "Sarah Chen"}],
  "suggestedActions": ["View profile"]
}
''',
      );

      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'valid-key'),
        provider: mockProvider,
      );

      final answer = await generator.generateAnswer(request: request, context: context);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, equals('Sarah Chen is the VP of AI at Mosaic AI.'));
      expect(answer.evidence.length, equals(1));
      expect(answer.evidence.any((e) => e.sourceId == 'act_1'), isTrue);
      expect(mockProvider.generateCalls, equals(1));
    });

    test('25. Fallback Guarantee: Provider timeout triggers deterministic fallback', () async {
      final mockProvider = MockGeminiAiProvider(shouldTimeout: true);
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'valid-key'),
        provider: mockProvider,
      );

      final answer = await generator.generateAnswer(request: request, context: context);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, contains('Sarah Chen'));
      expect(answer.answer, contains('VP of AI'));
    });

    test('26. Fallback Guarantee: HTTP 429 Rate Limit triggers deterministic fallback', () async {
      final mockProvider = MockGeminiAiProvider(shouldRateLimit: true);
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'valid-key'),
        provider: mockProvider,
      );

      final answer = await generator.generateAnswer(request: request, context: context);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, contains('Sarah Chen'));
    });

    test('27. Fallback Guarantee: Malformed model JSON triggers deterministic fallback', () async {
      final mockProvider = MockGeminiAiProvider(shouldReturnMalformedJson: true);
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'valid-key'),
        provider: mockProvider,
      );

      final answer = await generator.generateAnswer(request: request, context: context);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, contains('Sarah Chen'));
    });

    test('28. Fallback Guarantee: Provider unavailable triggers deterministic fallback', () async {
      final mockProvider = MockGeminiAiProvider(shouldBeUnavailable: true);
      final generator = GeminiGroundedAnswerGenerator(
        configuration: const GeminiAiConfiguration(apiKey: 'valid-key'),
        provider: mockProvider,
      );

      final answer = await generator.generateAnswer(request: request, context: context);
      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, contains('Sarah Chen'));
    });
  });

  group('Phase 13E-03: AskScreen Integration with Gemini Provider Tests', () {
    Widget createTestWidget(Widget child, {RecallrDependencies? dependencies}) {
      final deps = dependencies ?? RecallrDependencies.mock();
      return RecallrScope(
        dependencies: deps,
        child: MaterialApp(
          theme: RecallrTheme.darkTheme,
          routes: {
            '/person/per_priya_01': (context) => const Scaffold(body: Text('Person Details Priya')),
          },
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('29. AskScreen queries Gemini generator via AiAnswerService', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockProvider = MockGeminiAiProvider(
        forcedResponseText: '''
{
  "answer": "You discussed embedded RISC-V kernels with Priya Sharma.",
  "confidence": 0.90,
  "evidenceIds": ["act_priya_01"],
  "mentionedPeople": [{"personId": "per_priya_01", "name": "Dr. Priya Sharma"}],
  "suggestedActions": ["Review full profile"]
}
''',
      );

      final deps = RecallrDependencies.mock(
        geminiAiProvider: mockProvider,
      );

      await tester.pumpWidget(createTestWidget(
        const AskScreen(initialQuery: 'What did I discuss with Priya about RISC-V?'),
        dependencies: deps,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
    });

    testWidgets('30. AskScreen renders gracefully on Gemini fallback without crashing', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockProvider = MockGeminiAiProvider(shouldTimeout: true);
      final deps = RecallrDependencies.mock(
        geminiAiProvider: mockProvider,
      );

      await tester.pumpWidget(createTestWidget(
        const AskScreen(initialQuery: 'What did I discuss with Priya about RISC-V?'),
        dependencies: deps,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
    });
  });
}