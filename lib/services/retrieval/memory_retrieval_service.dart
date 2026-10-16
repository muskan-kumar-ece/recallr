import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../repositories/memory_retrieval_repository.dart';
import 'memory_query_classifier.dart';
import 'memory_relevance_ranker.dart';
import 'relationship_context_assembler.dart';

/// Abstract service contract for personal memory search, intent parsing, and context assembly.
abstract class MemoryRetrievalService {
  /// Retrieve structured memory evidence and assembled context for a natural language query.
  Future<MemorySearchResult> retrieve(String rawQuery, {int maxEvidence = 20});

  /// Assemble complete 360-degree relationship context for a specific person.
  Future<MemoryContext> assemblePersonContext(String personId, {int maxEvidence = 20});
}

/// Deterministic, production-ready implementation of MemoryRetrievalService.
class DeterministicMemoryRetrievalService implements MemoryRetrievalService {
  final MemoryRetrievalRepository repository;
  final RelationshipContextAssembler assembler;
  final MemoryQueryClassifier classifier;
  final MemoryRelevanceRanker ranker;
  final Duration simulatedLatency;

  const DeterministicMemoryRetrievalService({
    required this.repository,
    required this.assembler,
    this.classifier = const MemoryQueryClassifier(),
    this.ranker = const MemoryRelevanceRanker(),
    this.simulatedLatency = Duration.zero,
  });

  @override
  Future<MemorySearchResult> retrieve(String rawQuery, {int maxEvidence = 20}) async {
    final stopwatch = Stopwatch()..start();

    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    try {
      final query = classifier.classify(rawQuery, maxResults: maxEvidence);

      // Branch 1: Person-specific intent with detected target name
      if (query.targetPersonName != null && query.targetPersonName!.isNotEmpty) {
        final people = await repository.searchPeople(query.targetPersonName!, limit: 5);
        if (people.isNotEmpty) {
          final matchedPerson = people.first;
          final context = await assembler.assembleForPerson(
            personId: matchedPerson.id,
            query: query,
            maxEvidence: maxEvidence,
          );

          stopwatch.stop();
          return MemorySearchResult(
            query: query,
            status: context.isNotEmpty ? MemoryRetrievalStatus.completed : MemoryRetrievalStatus.empty,
            context: context,
            searchDurationMs: stopwatch.elapsedMilliseconds,
          );
        }
      }

      // Branch 2: Recent interaction query
      if (query.intent == MemoryQueryIntent.recentInteraction) {
        final recentEvidence = await repository.getRecentInteractions(limit: maxEvidence);
        final context = await assembler.assembleGeneralContext(
          query: query,
          candidateEvidence: recentEvidence,
          maxEvidence: maxEvidence,
        );

        stopwatch.stop();
        return MemorySearchResult(
          query: query,
          status: context.isNotEmpty ? MemoryRetrievalStatus.completed : MemoryRetrievalStatus.empty,
          context: context,
          searchDurationMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Branch 3: Multi-source search across repositories
      final candidateEvidence = await repository.searchEvidence(query, limit: maxEvidence * 2);
      final context = await assembler.assembleGeneralContext(
        query: query,
        candidateEvidence: candidateEvidence,
        maxEvidence: maxEvidence,
      );

      stopwatch.stop();
      return MemorySearchResult(
        query: query,
        status: context.isNotEmpty ? MemoryRetrievalStatus.completed : MemoryRetrievalStatus.empty,
        context: context,
        searchDurationMs: stopwatch.elapsedMilliseconds,
      );
    } on RecallrDataException catch (e) {
      stopwatch.stop();
      if (e.type == DataErrorType.unauthenticated) {
        rethrow;
      }
      return MemorySearchResult(
        query: MemoryQuery(rawQuery: rawQuery),
        status: MemoryRetrievalStatus.failed,
        context: MemoryContext(
          query: MemoryQuery(rawQuery: rawQuery),
          assembledAt: DateTime.now(),
        ),
        errorMessage: e.message,
        errorType: e.type,
        searchDurationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return MemorySearchResult(
        query: MemoryQuery(rawQuery: rawQuery),
        status: MemoryRetrievalStatus.failed,
        context: MemoryContext(
          query: MemoryQuery(rawQuery: rawQuery),
          assembledAt: DateTime.now(),
        ),
        errorMessage: e.toString(),
        errorType: DataErrorType.unknown,
        searchDurationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  @override
  Future<MemoryContext> assemblePersonContext(String personId, {int maxEvidence = 20}) async {
    final query = MemoryQuery(
      rawQuery: 'Dossier for person $personId',
      intent: MemoryQueryIntent.relationshipOverview,
      maxResults: maxEvidence,
    );

    return assembler.assembleForPerson(
      personId: personId,
      query: query,
      maxEvidence: maxEvidence,
    );
  }
}