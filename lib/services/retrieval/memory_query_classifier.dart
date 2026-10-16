import '../../features/ask/models/memory_retrieval_models.dart';

/// Deterministic natural language query parser and intent classifier.
/// Operates with zero LLM dependencies or external network calls.
class MemoryQueryClassifier {
  const MemoryQueryClassifier();

  MemoryQuery classify(String rawQuery, {int maxResults = 20}) {
    final trimmed = rawQuery.trim();
    final lower = trimmed.toLowerCase();

    // 1. Extract Temporal Constraint
    final temporalConstraint = _extractTemporal(lower);

    // 2. Classify Intent
    final intent = _determineIntent(lower);

    // 3. Extract Named Targets (Person / Company / Topic)
    final targetPerson = _extractTargetPerson(trimmed, lower);
    final targetCompany = _extractTargetCompany(trimmed, lower);
    final targetTopic = _extractTargetTopic(trimmed, lower);

    return MemoryQuery(
      rawQuery: trimmed,
      intent: intent,
      targetPersonName: targetPerson,
      targetCompanyName: targetCompany,
      targetTopic: targetTopic,
      temporalConstraint: temporalConstraint,
      maxResults: maxResults,
    );
  }

  MemoryQueryIntent _determineIntent(String lower) {
    if (lower.contains('promise') ||
        lower.contains('owe') ||
        lower.contains('follow up') ||
        lower.contains('follow-up') ||
        lower.contains('commitment') ||
        lower.contains('action item') ||
        lower.contains('deliverable') ||
        lower.contains('pending task')) {
      return MemoryQueryIntent.followUpLookup;
    }

    if (lower.startsWith('who did i meet') ||
        lower.startsWith('who have i met') ||
        lower.contains('recent meeting') ||
        lower.contains('latest interaction') ||
        lower.contains('met recently') ||
        lower.contains('last met')) {
      return MemoryQueryIntent.recentInteraction;
    }

    if (lower.contains('everything about') ||
        lower.contains('full background') ||
        lower.contains('dossier for') ||
        lower.contains('relationship overview') ||
        lower.contains('360 profile')) {
      return MemoryQueryIntent.relationshipOverview;
    }

    if (lower.contains('discuss') ||
        lower.contains('meeting with') ||
        lower.contains('talked about') ||
        lower.contains('conversation with') ||
        lower.contains('when did i meet') ||
        lower.contains('notes from call')) {
      return MemoryQueryIntent.interactionLookup;
    }

    if (lower.contains('who works at') ||
        lower.contains('people at') ||
        lower.contains('team at') ||
        lower.contains('company background') ||
        lower.contains('about the company')) {
      return MemoryQueryIntent.companyLookup;
    }

    if (lower.contains('who is') ||
        lower.contains('what is the role of') ||
        lower.contains('contact info for') ||
        lower.contains('tell me about') ||
        lower.contains('background on')) {
      return MemoryQueryIntent.personLookup;
    }

    if (lower.contains('remember about') ||
        lower.contains('what do i know about') ||
        lower.contains('facts on') ||
        lower.contains('notes on')) {
      return MemoryQueryIntent.memoryLookup;
    }

    if (lower.contains('project') || lower.contains('tapeout') || lower.contains('architecture')) {
      return MemoryQueryIntent.projectLookup;
    }

    return MemoryQueryIntent.generalSearch;
  }

  String? _extractTemporal(String lower) {
    if (lower.contains('today')) return 'today';
    if (lower.contains('yesterday')) return 'yesterday';
    if (lower.contains('this week')) return 'this week';
    if (lower.contains('last week')) return 'last week';
    if (lower.contains('this month')) return 'this month';
    if (lower.contains('recently') || lower.contains('recent')) return 'recently';
    if (lower.contains('latest')) return 'latest';
    return null;
  }

  String? _extractTargetPerson(String raw, String lower) {
    final patterns = [
      RegExp(r'who is ([a-zA-Z\.\s]+?)(?:\?|\s+at|\s+from|\s+and|$)', caseSensitive: false),
      RegExp(r'tell me (?:everything )?about ([a-zA-Z\.\s]+?)(?:\?|\s+at|\s+from|\s+and|$)', caseSensitive: false),
      RegExp(r'discuss(?:ed)? with ([a-zA-Z\.\s]+?)(?:\?|\s+at|\s+about|\s+on|$)', caseSensitive: false),
      RegExp(r'promise(?:d)? ([a-zA-Z\.\s]+?)(?:\?|\s+to|\s+that|$)', caseSensitive: false),
      RegExp(r'meeting with ([a-zA-Z\.\s]+?)(?:\?|\s+at|\s+about|\s+on|$)', caseSensitive: false),
      RegExp(r'follow up with ([a-zA-Z\.\s]+?)(?:\?|\s+on|\s+about|$)', caseSensitive: false),
      RegExp(r'(?:dossier|background|overview|profile|info)\s+(?:for|on|about)\s+([a-zA-Z\.\s]+?)(?:\?|$)', caseSensitive: false),
    ];

    final genericNouns = {'people', 'someone', 'anyone', 'everyone', 'team', 'person', 'folks', 'friends', 'colleagues', 'partners', 'leads'};
    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final candidate = match.group(1)?.trim();
        if (candidate != null && candidate.isNotEmpty && candidate.length > 2) {
          final lowerCand = candidate.toLowerCase();
          final candTokens = lowerCand.split(RegExp(r'\s+'));
          final isGeneric = genericNouns.contains(lowerCand) ||
              candTokens.any((t) => genericNouns.contains(t) && (lowerCand.startsWith('someone') || lowerCand.startsWith('anyone') || lowerCand.startsWith('people')));
          if (!isGeneric) {
            return candidate;
          }
        }
      }
    }
    return null;
  }

  String? _extractTargetCompany(String raw, String lower) {
    final patterns = [
      RegExp(r'(?:at|from|company)\s+([a-zA-Z0-9\s]+?)(?:\?|\s+about|\s+and|$)', caseSensitive: false),
      RegExp(r'who works at ([a-zA-Z0-9\s]+?)(?:\?|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null && match.groupCount >= 1) {
        final candidate = match.group(1)?.trim();
        if (candidate != null && candidate.isNotEmpty && candidate.length > 2) {
          return candidate;
        }
      }
    }
    return null;
  }

  String? _extractTargetTopic(String raw, String lower) {
    final match = RegExp(r'about\s+([a-zA-Z0-9\s]+?)(?:\?|$)', caseSensitive: false).firstMatch(raw);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }
}