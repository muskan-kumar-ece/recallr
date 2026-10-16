import 'dart:convert';

/// Structured parsed answer extracted from Gemini's raw output.
class ParsedGeminiAnswer {
  final String answer;
  final double confidence;
  final List<String> evidenceIds;
  final List<Map<String, String>> mentionedPeople;
  final List<String> suggestedActions;
  final bool isSuccess;
  final String? errorMessage;

  const ParsedGeminiAnswer({
    required this.answer,
    required this.confidence,
    this.evidenceIds = const [],
    this.mentionedPeople = const [],
    this.suggestedActions = const [],
    this.isSuccess = true,
    this.errorMessage,
  });

  factory ParsedGeminiAnswer.failure(String message) {
    return ParsedGeminiAnswer(
      answer: '',
      confidence: 0.0,
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Parser for extracting and validating structured JSON from Gemini responses.
class GeminiResponseParser {
  const GeminiResponseParser();

  /// Parses the raw text into a `ParsedGeminiAnswer`.
  ParsedGeminiAnswer parse(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return ParsedGeminiAnswer.failure('Model response text was empty.');
    }

    try {
      final jsonString = _extractJsonString(trimmed);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        return ParsedGeminiAnswer.failure('Decoded JSON was not a map.');
      }

      final answer = decoded['answer']?.toString().trim() ?? '';
      final rawConfidence = decoded['confidence'];
      double confidence = 0.0;
      if (rawConfidence is num) {
        confidence = rawConfidence.toDouble().clamp(0.0, 1.0);
      }

      final evidenceIds = <String>[];
      if (decoded['evidenceIds'] is List) {
        for (final item in decoded['evidenceIds'] as List) {
          if (item != null && item.toString().trim().isNotEmpty) {
            evidenceIds.add(item.toString().trim());
          }
        }
      }

      final mentionedPeople = <Map<String, String>>[];
      if (decoded['mentionedPeople'] is List) {
        for (final item in decoded['mentionedPeople'] as List) {
          if (item is Map) {
            final personId = item['personId']?.toString().trim() ?? '';
            final name = item['name']?.toString().trim() ?? '';
            if (personId.isNotEmpty || name.isNotEmpty) {
              mentionedPeople.add({
                'personId': personId,
                'name': name,
              });
            }
          }
        }
      }

      final suggestedActions = <String>[];
      if (decoded['suggestedActions'] is List) {
        for (final item in decoded['suggestedActions'] as List) {
          if (item != null && item.toString().trim().isNotEmpty) {
            suggestedActions.add(item.toString().trim());
          }
        }
      }

      return ParsedGeminiAnswer(
        answer: answer,
        confidence: confidence,
        evidenceIds: evidenceIds,
        mentionedPeople: mentionedPeople,
        suggestedActions: suggestedActions,
        isSuccess: true,
      );
    } catch (e) {
      return ParsedGeminiAnswer.failure('Failed to parse model JSON: $e');
    }
  }

  /// Extracts the JSON object substring from raw text, stripping markdown fences or wrapping text.
  String _extractJsonString(String text) {
    var cleaned = text;

    // 1. Remove markdown code fences if present (```json ... ``` or ``` ... ```)
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      final lastFence = cleaned.lastIndexOf('```');
      if (lastFence != -1) {
        cleaned = cleaned.substring(0, lastFence);
      }
    }

    cleaned = cleaned.trim();

    // 2. Find the outermost JSON object bounds { ... }
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    return cleaned;
  }
}