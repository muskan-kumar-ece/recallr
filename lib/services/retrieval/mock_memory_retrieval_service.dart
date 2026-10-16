import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../features/people/models/person_item.dart';
import 'memory_retrieval_service.dart';

/// Deterministic mock service for Memory Retrieval testing and offline widget mocks.
class MockMemoryRetrievalService implements MemoryRetrievalService {
  bool shouldFail;
  RecallrDataException? failureException;
  String errorMessage;
  Duration simulatedDelay;
  MemorySearchResult? forcedResult;
  int retrieveCalls = 0;

  MockMemoryRetrievalService({
    this.shouldFail = false,
    this.failureException,
    this.errorMessage = 'Simulated memory retrieval failure',
    this.simulatedDelay = Duration.zero,
    this.forcedResult,
  });

  @override
  Future<MemorySearchResult> retrieve(String rawQuery, {int maxEvidence = 20}) async {
    retrieveCalls++;

    if (shouldFail) {
      throw failureException ?? RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (forcedResult != null) {
      return forcedResult!;
    }

    final query = MemoryQuery(rawQuery: rawQuery, maxResults: maxEvidence);

    final mockEvidence = [
      MemoryEvidence(
        id: 'ev_mock_1',
        sourceType: MemorySourceType.person,
        sourceId: 'per_sarah_01',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        content: 'Sarah Chen · VP of System Architecture at Mosaic Neuromorphic.',
        relevanceScore: 0.95,
        matchReason: 'Direct person match',
      ),
      MemoryEvidence(
        id: 'ev_mock_2',
        sourceType: MemorySourceType.followUp,
        sourceId: 'fu_sarah_01',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        timestamp: 'Tomorrow',
        content: 'I PROMISED: Send proposal deliverables to Sarah Chen. Due: Tomorrow.',
        relevanceScore: 0.90,
        matchReason: 'Active commitment match',
      ),
    ];

    final context = MemoryContext(
      query: query,
      targetPerson: PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Neuromorphic',
        initials: 'SC',
      ),
      evidenceItems: mockEvidence,
      returnedCount: mockEvidence.length,
      originalCount: mockEvidence.length,
      assembledAt: DateTime.now(),
    );

    return MemorySearchResult(
      query: query,
      status: MemoryRetrievalStatus.completed,
      context: context,
      searchDurationMs: 12,
    );
  }

  @override
  Future<MemoryContext> assemblePersonContext(String personId, {int maxEvidence = 20}) async {
    final query = MemoryQuery(rawQuery: 'Person $personId', maxResults: maxEvidence);
    return MemoryContext(
      query: query,
      targetPerson: PersonItem(
        id: personId,
        name: 'Mock Person $personId',
        role: 'Role',
        company: 'Company',
        initials: 'MP',
      ),
      assembledAt: DateTime.now(),
    );
  }
}