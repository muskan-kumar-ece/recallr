import '../../features/ask/models/memory_retrieval_models.dart';

/// Deterministic ranking and relevance scoring engine for retrieved memory evidence.
class MemoryRelevanceRanker {
  const MemoryRelevanceRanker();

  List<MemoryEvidence> rank({
    required MemoryQuery query,
    required List<MemoryEvidence> candidateEvidence,
    int maxResults = 20,
  }) {
    if (candidateEvidence.isEmpty) return const [];

    final scored = <MemoryEvidence>[];
    final seenIds = <String>{};

    final queryLower = query.rawQuery.toLowerCase();
    final queryTokens = queryLower
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !_stopWords.contains(t))
        .toSet();

    for (final evidence in candidateEvidence) {
      if (seenIds.contains(evidence.id)) continue;
      seenIds.add(evidence.id);

      double score = 0.20; // Base score

      final contentLower = evidence.content.toLowerCase();
      final personLower = evidence.personName?.toLowerCase() ?? '';

      // 1. Target Person Match
      if (query.targetPersonName != null && query.targetPersonName!.isNotEmpty) {
        final target = query.targetPersonName!.toLowerCase();
        if (personLower.contains(target) || contentLower.contains(target)) {
          score += 0.35;
        }
      }

      // 2. Target Company Match
      if (query.targetCompanyName != null && query.targetCompanyName!.isNotEmpty) {
        final company = query.targetCompanyName!.toLowerCase();
        if (contentLower.contains(company)) {
          score += 0.25;
        }
      }

      // 3. Keyword Overlap
      int matchedTokens = 0;
      for (final token in queryTokens) {
        if (contentLower.contains(token) || personLower.contains(token)) {
          matchedTokens++;
        }
      }
      if (queryTokens.isNotEmpty) {
        score += (matchedTokens / queryTokens.length) * 0.25;
      }

      // 4. Intent Alignment Boost
      if (_matchesIntent(query.intent, evidence.sourceType)) {
        score += 0.15;
      }

      // 5. Temporal Alignment Boost
      if (query.temporalConstraint != null && evidence.timestamp != null) {
        final timeLower = evidence.timestamp!.toLowerCase();
        if (timeLower.contains(query.temporalConstraint!)) {
          score += 0.10;
        }
      }

      final normalizedScore = score.clamp(0.0, 1.0);

      scored.add(MemoryEvidence(
        id: evidence.id,
        sourceType: evidence.sourceType,
        sourceId: evidence.sourceId,
        personId: evidence.personId,
        personName: evidence.personName,
        captureId: evidence.captureId,
        activityId: evidence.activityId,
        timestamp: evidence.timestamp,
        content: evidence.content,
        relevanceScore: double.parse(normalizedScore.toStringAsFixed(2)),
        matchReason: evidence.matchReason.isNotEmpty
            ? evidence.matchReason
            : 'Matched ${matchedTokens > 0 ? "$matchedTokens query terms" : "contextual keywords"}',
        metadata: evidence.metadata,
      ));
    }

    // Sort descending by relevance score
    scored.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return scored.take(maxResults).toList();
  }

  bool _matchesIntent(MemoryQueryIntent intent, MemorySourceType type) {
    switch (intent) {
      case MemoryQueryIntent.personLookup:
      case MemoryQueryIntent.relationshipOverview:
        return type == MemorySourceType.person || type == MemorySourceType.timeline;
      case MemoryQueryIntent.interactionLookup:
      case MemoryQueryIntent.recentInteraction:
        return type == MemorySourceType.activity || type == MemorySourceType.timeline;
      case MemoryQueryIntent.followUpLookup:
        return type == MemorySourceType.followUp;
      case MemoryQueryIntent.memoryLookup:
      case MemoryQueryIntent.projectLookup:
        return type == MemorySourceType.memory || type == MemorySourceType.capture;
      case MemoryQueryIntent.companyLookup:
      case MemoryQueryIntent.generalSearch:
        return true;
    }
  }

  static const _stopWords = {
    'the', 'and', 'for', 'that', 'with', 'this', 'from', 'what', 'when',
    'where', 'who', 'how', 'did', 'have', 'about', 'tell', 'show', 'know'
  };
}