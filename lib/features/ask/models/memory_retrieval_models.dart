import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/data_exceptions.dart';
import '../../activity/models/activity_models.dart';
import '../../capture/models/capture_models.dart';
import '../../follow_ups/models/follow_up_models.dart';
import '../../people/models/person_item.dart';
import '../../person_detail/models/person_profile_model.dart';

/// Supported types of canonical relationship memory sources.
enum MemorySourceType {
  person,
  activity,
  capture,
  memory,
  followUp,
  timeline;

  String get label {
    switch (this) {
      case MemorySourceType.person:
        return 'Person Profile';
      case MemorySourceType.activity:
        return 'Activity Record';
      case MemorySourceType.capture:
        return 'Omni-Capture';
      case MemorySourceType.memory:
        return 'Memory Claim';
      case MemorySourceType.followUp:
        return 'Follow-up Commitment';
      case MemorySourceType.timeline:
        return 'Timeline Interaction';
    }
  }
}

/// Lifecycle status of a memory retrieval query.
enum MemoryRetrievalStatus {
  pending,
  searching,
  assembling,
  completed,
  failed,
  empty;

  String get label {
    switch (this) {
      case MemoryRetrievalStatus.pending:
        return 'Pending Search';
      case MemoryRetrievalStatus.searching:
        return 'Searching Memory...';
      case MemoryRetrievalStatus.assembling:
        return 'Assembling Relationship Context...';
      case MemoryRetrievalStatus.completed:
        return 'Memory Retrieved';
      case MemoryRetrievalStatus.failed:
        return 'Retrieval Failed';
      case MemoryRetrievalStatus.empty:
        return 'No Matching Memories';
    }
  }
}

/// Classified deterministic user intent for memory search and Q&A.
enum MemoryQueryIntent {
  personLookup,
  companyLookup,
  interactionLookup,
  memoryLookup,
  followUpLookup,
  projectLookup,
  recentInteraction,
  relationshipOverview,
  generalSearch;

  String get description {
    switch (this) {
      case MemoryQueryIntent.personLookup:
        return 'Look up person details, role, or background';
      case MemoryQueryIntent.companyLookup:
        return 'Find people and memories related to a company';
      case MemoryQueryIntent.interactionLookup:
        return 'Retrieve specific conversations or meetings';
      case MemoryQueryIntent.memoryLookup:
        return 'Search atomic facts and claims';
      case MemoryQueryIntent.followUpLookup:
        return 'Find commitments, promises, and follow-ups';
      case MemoryQueryIntent.projectLookup:
        return 'Find context on specific projects or topics';
      case MemoryQueryIntent.recentInteraction:
        return 'Retrieve latest encounters and recent timeline';
      case MemoryQueryIntent.relationshipOverview:
        return 'Full 360 relationship briefing for a person';
      case MemoryQueryIntent.generalSearch:
        return 'Broad keyword search across all memory stores';
    }
  }
}

/// Input query specification with classified intent and extracted entities.
class MemoryQuery {
  final String rawQuery;
  final MemoryQueryIntent intent;
  final String? targetPersonName;
  final String? targetCompanyName;
  final String? targetTopic;
  final String? temporalConstraint;
  final int maxResults;

  const MemoryQuery({
    required this.rawQuery,
    this.intent = MemoryQueryIntent.generalSearch,
    this.targetPersonName,
    this.targetCompanyName,
    this.targetTopic,
    this.temporalConstraint,
    this.maxResults = 20,
  });

  Map<String, dynamic> toMap() {
    return {
      'rawQuery': rawQuery,
      'intent': intent.name,
      'targetPersonName': targetPersonName,
      'targetCompanyName': targetCompanyName,
      'targetTopic': targetTopic,
      'temporalConstraint': temporalConstraint,
      'maxResults': maxResults,
    };
  }

  factory MemoryQuery.fromMap(Map<String, dynamic> map) {
    return MemoryQuery(
      rawQuery: map['rawQuery']?.toString() ?? '',
      intent: MemoryQueryIntent.values.firstWhere(
        (e) => e.name == map['intent'],
        orElse: () => MemoryQueryIntent.generalSearch,
      ),
      targetPersonName: map['targetPersonName']?.toString(),
      targetCompanyName: map['targetCompanyName']?.toString(),
      targetTopic: map['targetTopic']?.toString(),
      temporalConstraint: map['temporalConstraint']?.toString(),
      maxResults: (map['maxResults'] as num?)?.toInt() ?? 20,
    );
  }

  MemoryQuery copyWith({
    String? rawQuery,
    MemoryQueryIntent? intent,
    String? targetPersonName,
    String? targetCompanyName,
    String? targetTopic,
    String? temporalConstraint,
    int? maxResults,
  }) {
    return MemoryQuery(
      rawQuery: rawQuery ?? this.rawQuery,
      intent: intent ?? this.intent,
      targetPersonName: targetPersonName ?? this.targetPersonName,
      targetCompanyName: targetCompanyName ?? this.targetCompanyName,
      targetTopic: targetTopic ?? this.targetTopic,
      temporalConstraint: temporalConstraint ?? this.temporalConstraint,
      maxResults: maxResults ?? this.maxResults,
    );
  }
}

/// Traceable unit of memory evidence with explicit source provenance and relevance score.
class MemoryEvidence {
  final String id;
  final MemorySourceType sourceType;
  final String sourceId;
  final String? personId;
  final String? personName;
  final String? captureId;
  final String? activityId;
  final String? timestamp;
  final String content;
  final double relevanceScore;
  final String matchReason;
  final Map<String, dynamic>? metadata;

  const MemoryEvidence({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    this.personId,
    this.personName,
    this.captureId,
    this.activityId,
    this.timestamp,
    required this.content,
    required this.relevanceScore,
    required this.matchReason,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'personId': personId,
      'personName': personName,
      'captureId': captureId,
      'activityId': activityId,
      'timestamp': timestamp,
      'content': content,
      'relevanceScore': relevanceScore,
      'matchReason': matchReason,
      'metadata': metadata,
    };
  }

  factory MemoryEvidence.fromMap(Map<String, dynamic> map) {
    return MemoryEvidence(
      id: map['id']?.toString() ?? '',
      sourceType: MemorySourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => MemorySourceType.memory,
      ),
      sourceId: map['sourceId']?.toString() ?? '',
      personId: map['personId']?.toString(),
      personName: map['personName']?.toString(),
      captureId: map['captureId']?.toString(),
      activityId: map['activityId']?.toString(),
      timestamp: map['timestamp']?.toString(),
      content: map['content']?.toString() ?? '',
      relevanceScore: (map['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      matchReason: map['matchReason']?.toString() ?? '',
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }
}

/// Aggregated, ranked, and budgeted personal context ready for AI reasoning.
class MemoryContext {
  final MemoryQuery query;
  final PersonItem? targetPerson;
  final PersonProfile? targetProfile;
  final List<MemoryEvidence> evidenceItems;
  final List<PersonItem> relevantPeople;
  final List<ActivityItem> relevantActivities;
  final List<CaptureItem> relevantCaptures;
  final List<MemoryItem> relevantMemories;
  final List<FollowUpItem> relevantFollowUps;
  final List<TimelineItem> relevantTimeline;
  final bool wasTruncated;
  final int originalCount;
  final int returnedCount;
  final DateTime assembledAt;

  const MemoryContext({
    required this.query,
    this.targetPerson,
    this.targetProfile,
    this.evidenceItems = const [],
    this.relevantPeople = const [],
    this.relevantActivities = const [],
    this.relevantCaptures = const [],
    this.relevantMemories = const [],
    this.relevantFollowUps = const [],
    this.relevantTimeline = const [],
    this.wasTruncated = false,
    this.originalCount = 0,
    this.returnedCount = 0,
    required this.assembledAt,
  });

  bool get isEmpty => evidenceItems.isEmpty && targetPerson == null;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'query': query.toMap(),
      'targetPerson': targetPerson?.toMap(),
      'targetProfile': targetProfile?.toMap(),
      'evidenceItems': evidenceItems.map((e) => e.toMap()).toList(),
      'relevantPeople': relevantPeople.map((p) => p.toMap()).toList(),
      'relevantActivities': relevantActivities.map((a) => a.toMap()).toList(),
      'relevantCaptures': relevantCaptures.map((c) => c.toMap()).toList(),
      'relevantMemories': relevantMemories.map((m) => m.toMap()).toList(),
      'relevantFollowUps': relevantFollowUps.map((f) => f.toMap()).toList(),
      'relevantTimeline': relevantTimeline.map((t) => t.toMap()).toList(),
      'wasTruncated': wasTruncated,
      'originalCount': originalCount,
      'returnedCount': returnedCount,
      'assembledAt': Timestamp.fromDate(assembledAt),
    };
  }

  factory MemoryContext.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawQuery = map['query'] is Map
        ? Map<String, dynamic>.from(map['query'] as Map)
        : <String, dynamic>{'rawQuery': ''};

    final rawPerson = map['targetPerson'] is Map
        ? Map<String, dynamic>.from(map['targetPerson'] as Map)
        : null;

    final rawProfile = map['targetProfile'] is Map
        ? Map<String, dynamic>.from(map['targetProfile'] as Map)
        : null;

    final rawEvidence = map['evidenceItems'] as List? ?? const [];
    final evidence = rawEvidence
        .whereType<Map>()
        .map((e) => MemoryEvidence.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return MemoryContext(
      query: MemoryQuery.fromMap(rawQuery),
      targetPerson: rawPerson != null ? PersonItem.fromMap(rawPerson) : null,
      targetProfile: rawProfile != null ? PersonProfile.fromMap(rawProfile) : null,
      evidenceItems: evidence,
      wasTruncated: map['wasTruncated'] == true,
      originalCount: (map['originalCount'] as num?)?.toInt() ?? evidence.length,
      returnedCount: (map['returnedCount'] as num?)?.toInt() ?? evidence.length,
      assembledAt: parseDate(map['assembledAt']),
    );
  }
}

/// Final search result returned by the Memory Retrieval Service.
class MemorySearchResult {
  final MemoryQuery query;
  final MemoryRetrievalStatus status;
  final MemoryContext context;
  final String? errorMessage;
  final DataErrorType? errorType;
  final int searchDurationMs;

  const MemorySearchResult({
    required this.query,
    required this.status,
    required this.context,
    this.errorMessage,
    this.errorType,
    this.searchDurationMs = 0,
  });

  bool get isSuccessful => status == MemoryRetrievalStatus.completed;
  bool get hasResults => context.isNotEmpty;
}