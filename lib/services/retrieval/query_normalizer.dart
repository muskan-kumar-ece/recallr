/// Normalizes natural language queries into meaningful search tokens by stripping
/// common question phrases, stop words, and punctuation.
class QueryNormalizer {
  const QueryNormalizer();

  /// Stop words common in conversational question phrasing and general English.
  static const Set<String> _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
    'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
    'to', 'was', 'were', 'will', 'with', 'about', 'what', 'when', 'where',
    'which', 'who', 'why', 'how', 'did', 'do', 'does', 'have', 'had',
    'having', 'me', 'my', 'i', 'we', 'our', 'you', 'your', 'them', 'their',
    'they', 'us', 'any', 'some', 'recent', 'recently', 'latest', 'tell',
    'know', 'remember', 'discuss', 'discussed', 'discussing', 'talk',
    'talked', 'talking', 'meet', 'meeting', 'met', 'show', 'find', 'get',
    'look', 'give', 'could', 'would', 'should', 'can', 'please', 'all',
    'people', 'person', 'someone', 'anyone', 'team', 'company',
  };

  /// Extract normalized search tokens of minimum length 2.
  static List<String> extractTokens(String query) {
    if (query.trim().isEmpty) return const [];

    // Replace non-alphanumeric characters with spaces
    final cleaned = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final rawTokens = cleaned.split(RegExp(r'\s+'));

    final tokens = <String>[];
    for (final t in rawTokens) {
      final token = t.trim();
      if (token.length >= 2 && !_stopWords.contains(token)) {
        if (!tokens.contains(token)) {
          tokens.add(token);
        }
      }
    }

    // Fallback: If all tokens were stripped as stop words, return original alphanumeric words >= 2 chars
    if (tokens.isEmpty) {
      for (final t in rawTokens) {
        final token = t.trim();
        if (token.length >= 2 && !tokens.contains(token)) {
          tokens.add(token);
        }
      }
    }

    return tokens;
  }

  /// Determines if a target text matches the search query either by full substring
  /// or by matching any of the normalized query tokens.
  static bool matches(String text, String query, {List<String>? precomputedTokens}) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.isNotEmpty && lowerText.contains(lowerQuery)) {
      return true;
    }

    final tokens = precomputedTokens ?? extractTokens(query);
    if (tokens.isEmpty) {
      return false;
    }

    for (final token in tokens) {
      if (lowerText.contains(token)) {
        return true;
      }
    }

    return false;
  }
}
