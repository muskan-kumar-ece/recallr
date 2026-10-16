import 'package:cloud_firestore/cloud_firestore.dart';
import '../../follow_ups/models/follow_up_models.dart';
import 'person_profile_model.dart';

/// Processing lifecycle status of relationship memory enrichment.
enum RelationshipMemoryStatus {
  pending,
  enriching,
  completed,
  failed,
  skipped;

  String get label {
    switch (this) {
      case RelationshipMemoryStatus.pending:
        return 'Pending Relationship Enrichment';
      case RelationshipMemoryStatus.enriching:
        return 'Building Relationship Memory...';
      case RelationshipMemoryStatus.completed:
        return 'Relationship Memory Updated';
      case RelationshipMemoryStatus.failed:
        return 'Memory Enrichment Failed';
      case RelationshipMemoryStatus.skipped:
        return 'Enrichment Skipped';
    }
  }
}

/// Structured package of memory and timeline updates for a canonical Person Profile.
class RelationshipMemoryUpdate {
  final String personId;
  final String captureId;
  final String? activityId;
  final TimelineItem? timelineItem;
  final List<MemoryItem> memories;
  final FollowUpItem? followUpCandidate;
  final List<String> newCapabilities;
  final String? relationshipStrength;
  final int? totalInteractions;
  final String? lastInteraction;
  final int? sharedEventsCount;

  const RelationshipMemoryUpdate({
    required this.personId,
    required this.captureId,
    this.activityId,
    this.timelineItem,
    this.memories = const [],
    this.followUpCandidate,
    this.newCapabilities = const [],
    this.relationshipStrength,
    this.totalInteractions,
    this.lastInteraction,
    this.sharedEventsCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'captureId': captureId,
      'activityId': activityId,
      'timelineItem': timelineItem?.toMap(),
      'memories': memories.map((m) => m.toMap()).toList(),
      'followUpCandidate': followUpCandidate?.toMap(),
      'newCapabilities': newCapabilities,
      'relationshipStrength': relationshipStrength,
      'totalInteractions': totalInteractions,
      'lastInteraction': lastInteraction,
      'sharedEventsCount': sharedEventsCount,
    };
  }

  factory RelationshipMemoryUpdate.fromMap(Map<String, dynamic> map) {
    final rawTimeline = map['timelineItem'] is Map
        ? Map<String, dynamic>.from(map['timelineItem'] as Map)
        : null;

    final rawMemories = map['memories'] as List? ?? const [];
    final parsedMemories = rawMemories
        .whereType<Map>()
        .map((m) => MemoryItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawFollowUp = map['followUpCandidate'] is Map
        ? Map<String, dynamic>.from(map['followUpCandidate'] as Map)
        : null;

    return RelationshipMemoryUpdate(
      personId: map['personId']?.toString() ?? '',
      captureId: map['captureId']?.toString() ?? '',
      activityId: map['activityId']?.toString(),
      timelineItem: rawTimeline != null ? TimelineItem.fromMap(rawTimeline) : null,
      memories: parsedMemories,
      followUpCandidate: rawFollowUp != null ? FollowUpItem.fromMap(rawFollowUp) : null,
      newCapabilities: (map['newCapabilities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relationshipStrength: map['relationshipStrength']?.toString(),
      totalInteractions: (map['totalInteractions'] as num?)?.toInt(),
      lastInteraction: map['lastInteraction']?.toString(),
      sharedEventsCount: (map['sharedEventsCount'] as num?)?.toInt(),
    );
  }
}

/// Structured canonical result of a relationship memory enrichment pass.
class RelationshipMemoryResult {
  final String personId;
  final String captureId;
  final RelationshipMemoryStatus status;
  final TimelineItem? createdTimelineItem;
  final List<MemoryItem> createdMemories;
  final FollowUpItem? createdFollowUp;
  final PersonProfile? updatedProfile;
  final String? errorMessage;
  final DateTime? processedAt;

  const RelationshipMemoryResult({
    required this.personId,
    required this.captureId,
    this.status = RelationshipMemoryStatus.pending,
    this.createdTimelineItem,
    this.createdMemories = const [],
    this.createdFollowUp,
    this.updatedProfile,
    this.errorMessage,
    this.processedAt,
  });

  bool get isSuccessful => status == RelationshipMemoryStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'captureId': captureId,
      'status': status.name,
      'createdTimelineItem': createdTimelineItem?.toMap(),
      'createdMemories': createdMemories.map((m) => m.toMap()).toList(),
      'createdFollowUp': createdFollowUp?.toMap(),
      'updatedProfile': updatedProfile?.toMap(),
      'errorMessage': errorMessage,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  factory RelationshipMemoryResult.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawTimeline = map['createdTimelineItem'] is Map
        ? Map<String, dynamic>.from(map['createdTimelineItem'] as Map)
        : null;

    final rawMemories = map['createdMemories'] as List? ?? const [];
    final parsedMemories = rawMemories
        .whereType<Map>()
        .map((m) => MemoryItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawFollowUp = map['createdFollowUp'] is Map
        ? Map<String, dynamic>.from(map['createdFollowUp'] as Map)
        : null;

    final rawProfile = map['updatedProfile'] is Map
        ? Map<String, dynamic>.from(map['updatedProfile'] as Map)
        : null;

    return RelationshipMemoryResult(
      personId: map['personId']?.toString() ?? '',
      captureId: map['captureId']?.toString() ?? '',
      status: RelationshipMemoryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RelationshipMemoryStatus.pending,
      ),
      createdTimelineItem: rawTimeline != null ? TimelineItem.fromMap(rawTimeline) : null,
      createdMemories: parsedMemories,
      createdFollowUp: rawFollowUp != null ? FollowUpItem.fromMap(rawFollowUp) : null,
      updatedProfile: rawProfile != null ? PersonProfile.fromMap(rawProfile) : null,
      errorMessage: map['errorMessage']?.toString(),
      processedAt: parseDate(map['processedAt']),
    );
  }

  RelationshipMemoryResult copyWith({
    String? personId,
    String? captureId,
    RelationshipMemoryStatus? status,
    TimelineItem? createdTimelineItem,
    List<MemoryItem>? createdMemories,
    FollowUpItem? createdFollowUp,
    PersonProfile? updatedProfile,
    String? errorMessage,
    DateTime? processedAt,
  }) {
    return RelationshipMemoryResult(
      personId: personId ?? this.personId,
      captureId: captureId ?? this.captureId,
      status: status ?? this.status,
      createdTimelineItem: createdTimelineItem ?? this.createdTimelineItem,
      createdMemories: createdMemories ?? this.createdMemories,
      createdFollowUp: createdFollowUp ?? this.createdFollowUp,
      updatedProfile: updatedProfile ?? this.updatedProfile,
      errorMessage: errorMessage ?? this.errorMessage,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}