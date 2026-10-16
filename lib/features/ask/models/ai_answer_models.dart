import 'package:cloud_firestore/cloud_firestore.dart';
import 'ask_models.dart';
import 'memory_retrieval_models.dart';

/// Standard semantic classification for AI answer generation and retrieval errors.
enum AiErrorType {
  none,
  insufficientEvidence,
  networkUnavailable,
  timeout,
  rateLimited,
  aiUnavailable,
  unauthenticated,
  invalidData;

  String get defaultMessage {
    switch (this) {
      case AiErrorType.none:
        return '';
      case AiErrorType.insufficientEvidence:
        return 'Not enough evidence in your Recallr memory to answer confidently.';
      case AiErrorType.networkUnavailable:
        return 'Network is unavailable. Please check your connection and try again.';
      case AiErrorType.timeout:
        return 'Request timed out. Please try again.';
      case AiErrorType.rateLimited:
        return 'AI service rate limit exceeded. Please wait a moment and try again.';
      case AiErrorType.aiUnavailable:
        return 'AI synthesis is temporarily unavailable. Please try again later.';
      case AiErrorType.unauthenticated:
        return 'You must be signed in to query your personal memory.';
      case AiErrorType.invalidData:
        return 'Failed to parse memory records. Please try again.';
    }
  }
}

/// Lifecycle status of AI answer generation.
enum AiAnswerStatus {
  idle,
  generating,
  completed,
  empty,
  failed;

  String get label {
    switch (this) {
      case AiAnswerStatus.idle:
        return 'Ready';
      case AiAnswerStatus.generating:
        return 'Synthesizing Answer...';
      case AiAnswerStatus.completed:
        return 'Answer Grounded';
      case AiAnswerStatus.empty:
        return 'No Memory Found';
      case AiAnswerStatus.failed:
        return 'Generation Failed';
    }
  }
}

/// A structured piece of evidence used by the AI answer generator.
class AiAnswerEvidence {
  final MemorySourceType sourceType;
  final String sourceId;
  final String? personId;
  final String? personName;
  final String title;
  final String content;
  final String? timestamp;
  final double relevanceScore;
  final String matchReason;
  final String? targetRoute;

  const AiAnswerEvidence({
    required this.sourceType,
    required this.sourceId,
    this.personId,
    this.personName,
    required this.title,
    required this.content,
    this.timestamp,
    required this.relevanceScore,
    required this.matchReason,
    this.targetRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'personId': personId,
      'personName': personName,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'relevanceScore': relevanceScore,
      'matchReason': matchReason,
      'targetRoute': targetRoute,
    };
  }

  factory AiAnswerEvidence.fromMap(Map<String, dynamic> map) {
    return AiAnswerEvidence(
      sourceType: MemorySourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => MemorySourceType.memory,
      ),
      sourceId: map['sourceId']?.toString() ?? '',
      personId: map['personId']?.toString(),
      personName: map['personName']?.toString(),
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp']?.toString(),
      relevanceScore: (map['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      matchReason: map['matchReason']?.toString() ?? '',
      targetRoute: map['targetRoute']?.toString(),
    );
  }
}

/// A conversation turn for multi-turn personal memory Q&A.
class AiAnswerTurn {
  final String id;
  final String query;
  final String answer;
  final List<AiAnswerEvidence> evidence;
  final DateTime timestamp;

  const AiAnswerTurn({
    required this.id,
    required this.query,
    required this.answer,
    this.evidence = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'answer': answer,
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AiAnswerTurn.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawEvidence = map['evidence'] as List? ?? const [];
    return AiAnswerTurn(
      id: map['id']?.toString() ?? '',
      query: map['query']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      evidence: rawEvidence
          .whereType<Map>()
          .map((e) => AiAnswerEvidence.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      timestamp: parseDate(map['timestamp']),
    );
  }
}

/// Request payload for generating an AI answer over personal memory.
class AiAnswerRequest {
  final String query;
  final List<AiAnswerTurn>? conversationHistory;
  final String? targetPersonId;
  final int maxEvidence;
  final String? answerStyle;

  const AiAnswerRequest({
    required this.query,
    this.conversationHistory,
    this.targetPersonId,
    this.maxEvidence = 15,
    this.answerStyle,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'conversationHistory': conversationHistory?.map((h) => h.toMap()).toList(),
      'targetPersonId': targetPersonId,
      'maxEvidence': maxEvidence,
      'answerStyle': answerStyle,
    };
  }

  factory AiAnswerRequest.fromMap(Map<String, dynamic> map) {
    final rawHistory = map['conversationHistory'] as List?;
    return AiAnswerRequest(
      query: map['query']?.toString() ?? '',
      conversationHistory: rawHistory
          ?.whereType<Map>()
          .map((h) => AiAnswerTurn.fromMap(Map<String, dynamic>.from(h)))
          .toList(),
      targetPersonId: map['targetPersonId']?.toString(),
      maxEvidence: (map['maxEvidence'] as num?)?.toInt() ?? 15,
      answerStyle: map['answerStyle']?.toString(),
    );
  }
}

/// Safety limits and configuration for the AI answer generator.
class AiAnswerConfiguration {
  final int maxEvidenceItems;
  final int maxContextChars;
  final int maxAnswerLength;
  final double minConfidenceThreshold;

  const AiAnswerConfiguration({
    this.maxEvidenceItems = 15,
    this.maxContextChars = 8000,
    this.maxAnswerLength = 2000,
    this.minConfidenceThreshold = 0.40,
  });
}

/// Grounded AI answer response backed by structured personal memory evidence.
class AiAnswer {
  final String answer;
  final AiAnswerStatus status;
  final String query;
  final MemoryQueryIntent? intent;
  final double confidence; // Normalized 0.0 to 1.0
  final List<AiAnswerEvidence> evidence;
  final List<PersonReference> mentionedPeople;
  final List<String> mentionedCompanies;
  final List<String> suggestedActions;
  final DateTime generatedAt;
  final String? errorMessage;
  final AiErrorType errorType;
  final bool wasTruncated;

  const AiAnswer({
    required this.answer,
    this.status = AiAnswerStatus.completed,
    required this.query,
    this.intent,
    this.confidence = 1.0,
    this.evidence = const [],
    this.mentionedPeople = const [],
    this.mentionedCompanies = const [],
    this.suggestedActions = const [],
    required this.generatedAt,
    this.errorMessage,
    this.errorType = AiErrorType.none,
    this.wasTruncated = false,
  });

  bool get isSuccessful => status == AiAnswerStatus.completed;
  bool get isEmpty => status == AiAnswerStatus.empty || answer.isEmpty;
  bool get hasEvidence => evidence.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'answer': answer,
      'status': status.name,
      'query': query,
      'intent': intent?.name,
      'confidence': confidence,
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'mentionedPeople': mentionedPeople.map((p) => p.toMap()).toList(),
      'mentionedCompanies': mentionedCompanies,
      'suggestedActions': suggestedActions,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'errorMessage': errorMessage,
      'errorType': errorType.name,
      'wasTruncated': wasTruncated,
    };
  }

  factory AiAnswer.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawEvidence = map['evidence'] as List? ?? const [];
    final rawPeople = map['mentionedPeople'] as List? ?? const [];

    return AiAnswer(
      answer: map['answer']?.toString() ?? '',
      status: AiAnswerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AiAnswerStatus.completed,
      ),
      query: map['query']?.toString() ?? '',
      intent: map['intent'] != null
          ? MemoryQueryIntent.values.firstWhere(
              (e) => e.name == map['intent'],
              orElse: () => MemoryQueryIntent.generalSearch,
            )
          : null,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      evidence: rawEvidence
          .whereType<Map>()
          .map((e) => AiAnswerEvidence.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      mentionedPeople: rawPeople
          .whereType<Map>()
          .map((p) => PersonReference.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      mentionedCompanies: (map['mentionedCompanies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      suggestedActions: (map['suggestedActions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      generatedAt: parseDate(map['generatedAt']),
      errorMessage: map['errorMessage']?.toString(),
      errorType: AiErrorType.values.firstWhere(
        (e) => e.name == map['errorType'],
        orElse: () => AiErrorType.none,
      ),
      wasTruncated: map['wasTruncated'] == true,
    );
  }

  AiAnswer copyWith({
    String? answer,
    AiAnswerStatus? status,
    String? query,
    MemoryQueryIntent? intent,
    double? confidence,
    List<AiAnswerEvidence>? evidence,
    List<PersonReference>? mentionedPeople,
    List<String>? mentionedCompanies,
    List<String>? suggestedActions,
    DateTime? generatedAt,
    String? errorMessage,
    bool? wasTruncated,
  }) {
    return AiAnswer(
      answer: answer ?? this.answer,
      status: status ?? this.status,
      query: query ?? this.query,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      evidence: evidence ?? this.evidence,
      mentionedPeople: mentionedPeople ?? this.mentionedPeople,
      mentionedCompanies: mentionedCompanies ?? this.mentionedCompanies,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      generatedAt: generatedAt ?? this.generatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      wasTruncated: wasTruncated ?? this.wasTruncated,
    );
  }
}