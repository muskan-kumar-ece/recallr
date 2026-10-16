import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/security/environment_config.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/services/ai/gemini/grounded_answer_validator.dart';
import 'package:recaller/services/ai/gemini/gemini_prompt_builder.dart';
import 'package:recaller/services/ai/gemini/gemini_response_parser.dart';
import 'package:recaller/services/retrieval/query_normalizer.dart';
import 'package:recaller/services/retrieval/memory_query_classifier.dart';

import 'package:recaller/features/people/models/person_item.dart';

void main() {
  group('Phase 13H-08.4 Hardening Verification Tests', () {
    test('EnvironmentConfig sanitizes bare JWTs, auth headers, and query tokens', () {
      const rawLog = 'User error with Bearer somesecretbearer and eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.doNotLeakThisToken and https://firebasestorage.googleapis.com/v0/b/app?token=secret123456789 and Authorization: Basic dXNlcjpwYXNz';
      final sanitized = EnvironmentConfig.sanitizeForLog(rawLog);

      expect(sanitized, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
      expect(sanitized, isNot(contains('secret123456789')));
      expect(sanitized, isNot(contains('dXNlcjpwYXNz')));
      expect(sanitized, contains('[REDACTED_JWT]'));
      expect(sanitized, contains('[REDACTED_TOKEN]'));
      expect(sanitized, contains('[REDACTED_BASIC_AUTH]'));
    });

    test('QueryNormalizer tokenizes conversational questions accurately', () {
      const query = 'What did I discuss with people about AI projects recently?';
      final tokens = QueryNormalizer.extractTokens(query);

      expect(tokens, contains('ai'));
      expect(tokens, contains('projects'));
      expect(tokens, isNot(contains('what')));
      expect(tokens, isNot(contains('with')));
      expect(tokens, isNot(contains('people')));
      expect(tokens, isNot(contains('recently')));

      expect(QueryNormalizer.matches('Working on next-gen AI systems', query, precomputedTokens: tokens), isTrue);
      expect(QueryNormalizer.matches('Unrelated topic about gardening', query, precomputedTokens: tokens), isFalse);
    });

    test('MemoryQueryClassifier does not mistake collective nouns for person names', () {
      const classifier = MemoryQueryClassifier();
      final q1 = classifier.classify('What did I discuss with people about AI?');
      expect(q1.targetPersonName, isNull);

      final q2 = classifier.classify('What did I discuss with someone from the team?');
      expect(q2.targetPersonName, isNull);

      final q3 = classifier.classify('What did I discuss with Sarah Chen?');
      expect(q3.targetPersonName, equals('Sarah Chen'));
    });

    test('GroundedAnswerValidator fails closed on hallucinated evidence or entities', () {
      const validator = GroundedAnswerValidator();
      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Tell me about quantum sensors'),
        assembledAt: DateTime(2026, 1, 1),
      );

      final fakeAnswer = ParsedGeminiAnswer(
        isSuccess: true,
        answer: 'We met with Bob Vance who built quantum sensors.',
        confidence: 0.95,
        evidenceIds: const ['fake_ev_999'],
        mentionedPeople: const [{'personId': 'fake_p_1', 'name': 'Bob Vance'}],
        suggestedActions: const ['Call Bob'],
      );

      final result = validator.validate(
        parsed: fakeAnswer,
        context: context,
        request: const AiAnswerRequest(query: 'Tell me about quantum sensors'),
      );

      expect(result.status, equals(AiAnswerStatus.empty));
      expect(result.evidence, isEmpty);
      expect(result.mentionedPeople, isEmpty);
      expect(result.confidence, equals(0.0));
      expect(result.errorType, equals(AiErrorType.insufficientEvidence));
    });

    test('GeminiPromptBuilder includes the most recent conversation turns', () {
      const builder = GeminiPromptBuilder();
      final turns = List.generate(
        8,
        (i) => AiAnswerTurn(
          id: 'turn_$i',
          query: 'Query $i',
          answer: 'Answer $i',
          timestamp: DateTime(2026, 1, 1, 10, i),
        ),
      );

      final prompt = builder.build(
        request: AiAnswerRequest(
          query: 'Latest query',
          conversationHistory: turns,
        ),
        context: MemoryContext(
          query: const MemoryQuery(rawQuery: 'Latest query'),
          assembledAt: DateTime(2026, 1, 1),
        ),
      );

      expect(prompt.userPrompt, contains('Query 7'));
      expect(prompt.userPrompt, contains('Query 6'));
      expect(prompt.userPrompt, contains('Query 5'));
      expect(prompt.userPrompt, contains('Query 4'));
      expect(prompt.userPrompt, contains('Query 3'));
      expect(prompt.userPrompt, isNot(contains('Query 0')));
      expect(prompt.userPrompt, isNot(contains('Query 1')));
    });

    test('AiErrorType enum covers all semantic error classes', () {
      expect(AiErrorType.insufficientEvidence.defaultMessage, isNotEmpty);
      expect(AiErrorType.networkUnavailable.defaultMessage, isNotEmpty);
      expect(AiErrorType.rateLimited.defaultMessage, isNotEmpty);
      expect(AiErrorType.unauthenticated.defaultMessage, isNotEmpty);
      expect(AiErrorType.timeout.defaultMessage, isNotEmpty);
    });

    test('GroundedAnswerValidator fails closed when Gemini invents entity despite known contacts in context', () {
      const validator = GroundedAnswerValidator();
      final alice = PersonItem(
        id: 'p_alice',
        name: 'Alice Smith',
        role: 'Founder',
        company: 'Acme',
        initials: 'AS',
        relationshipType: RelationshipContextType.mentor,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Who leads Acme?'),
        relevantPeople: [alice],
        evidenceItems: [
          const MemoryEvidence(
            id: 'ev_1',
            sourceType: MemorySourceType.person,
            sourceId: 'p_alice',
            content: 'Alice Smith is the founder of Acme',
            relevanceScore: 0.9,
            matchReason: 'Person match',
          ),
        ],
        assembledAt: DateTime(2026, 1, 1),
      );

      // Gemini hallucinated Bob Vance who is NOT in context, with fake person ID
      final hallucinatedAnswer = ParsedGeminiAnswer(
        isSuccess: true,
        answer: 'Bob Vance is leading Acme.',
        confidence: 0.95,
        evidenceIds: const ['ev_1'],
        mentionedPeople: const [{'personId': 'p_fake', 'name': 'Bob Vance'}],
        suggestedActions: const ['Contact Bob'],
      );

      final result = validator.validate(
        parsed: hallucinatedAnswer,
        context: context,
        request: const AiAnswerRequest(query: 'Who leads Acme?'),
      );

      // Must fail closed because the entity mentioned is 100% a hallucination
      expect(result.status, equals(AiAnswerStatus.empty));
      expect(result.evidence, isEmpty);
      expect(result.mentionedPeople, isEmpty);
      expect(result.confidence, equals(0.0));
      expect(result.errorType, equals(AiErrorType.insufficientEvidence));
    });
  });
}
