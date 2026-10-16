import 'package:cloud_firestore/cloud_firestore.dart';
import '../../people/models/person_item.dart';

/// Supported deterministic match types for entity resolution.
enum EntityMatchType {
  explicitId,
  exactEmail,
  exactPhone,
  strongNameCompany,
  contextualName,
  ambiguous,
  none;

  String get label {
    switch (this) {
      case EntityMatchType.explicitId:
        return 'Explicit ID Match';
      case EntityMatchType.exactEmail:
        return 'Exact Email Match';
      case EntityMatchType.exactPhone:
        return 'Exact Phone Match';
      case EntityMatchType.strongNameCompany:
        return 'Name & Company Match';
      case EntityMatchType.contextualName:
        return 'Contextual Name Match';
      case EntityMatchType.ambiguous:
        return 'Ambiguous Multiple Candidates';
      case EntityMatchType.none:
        return 'No Match (New Person)';
    }
  }
}

/// Lifecycle status of the entity resolution pipeline for a capture.
enum EntityResolutionStatus {
  pending,
  resolving,
  resolvedExisting,
  resolvedNew,
  requiresReview,
  failed,
  skipped;

  String get label {
    switch (this) {
      case EntityResolutionStatus.pending:
        return 'Pending Resolution';
      case EntityResolutionStatus.resolving:
        return 'Resolving Identity...';
      case EntityResolutionStatus.resolvedExisting:
        return 'Matched Existing Person';
      case EntityResolutionStatus.resolvedNew:
        return 'Created New Person';
      case EntityResolutionStatus.requiresReview:
        return 'Possible Matches · Review Required';
      case EntityResolutionStatus.failed:
        return 'Resolution Failed';
      case EntityResolutionStatus.skipped:
        return 'Resolution Skipped';
    }
  }
}

/// Represents a field-level conflict between existing verified data and new incoming capture data.
class EntityConflict {
  final String fieldName;
  final dynamic existingValue;
  final dynamic incomingValue;
  final double confidence;

  const EntityConflict({
    required this.fieldName,
    required this.existingValue,
    required this.incomingValue,
    this.confidence = 0.5,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'existingValue': existingValue,
      'incomingValue': incomingValue,
      'confidence': confidence,
    };
  }

  factory EntityConflict.fromMap(Map<String, dynamic> map) {
    return EntityConflict(
      fieldName: map['fieldName']?.toString() ?? '',
      existingValue: map['existingValue'],
      incomingValue: map['incomingValue'],
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  String toString() =>
      'EntityConflict($fieldName: existing="$existingValue" vs incoming="$incomingValue")';
}

/// Represents a candidate person match during ambiguous or multi-signal resolution.
class EntityResolutionCandidate {
  final String personId;
  final PersonItem person;
  final EntityMatchType matchType;
  final double confidence;
  final List<String> matchedFields;

  const EntityResolutionCandidate({
    required this.personId,
    required this.person,
    required this.matchType,
    required this.confidence,
    this.matchedFields = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'person': person.toMap(),
      'matchType': matchType.name,
      'confidence': confidence,
      'matchedFields': matchedFields,
    };
  }

  factory EntityResolutionCandidate.fromMap(Map<String, dynamic> map) {
    final rawPerson = map['person'] is Map ? Map<String, dynamic>.from(map['person'] as Map) : <String, dynamic>{};
    return EntityResolutionCandidate(
      personId: map['personId']?.toString() ?? '',
      person: PersonItem.fromMap(rawPerson, map['personId']?.toString()),
      matchType: EntityMatchType.values.firstWhere(
        (e) => e.name == map['matchType'],
        orElse: () => EntityMatchType.none,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      matchedFields: (map['matchedFields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// Structured canonical result of an entity resolution pass.
class EntityResolutionResult {
  final String? matchedPersonId;
  final EntityMatchType matchType;
  final EntityResolutionStatus status;
  final double confidence;
  final bool isNewPerson;
  final bool requiresReview;
  final PersonItem? resolvedPerson;
  final List<EntityResolutionCandidate> candidates;
  final List<EntityConflict> conflicts;
  final List<String> matchedFields;
  final Map<String, dynamic> extractedFields;
  final String? createdActivityId;
  final String? errorMessage;
  final DateTime? resolvedAt;

  const EntityResolutionResult({
    this.matchedPersonId,
    this.matchType = EntityMatchType.none,
    this.status = EntityResolutionStatus.pending,
    this.confidence = 0.0,
    this.isNewPerson = false,
    this.requiresReview = false,
    this.resolvedPerson,
    this.candidates = const [],
    this.conflicts = const [],
    this.matchedFields = const [],
    this.extractedFields = const {},
    this.createdActivityId,
    this.errorMessage,
    this.resolvedAt,
  });

  bool get isSuccessful =>
      status == EntityResolutionStatus.resolvedExisting ||
      status == EntityResolutionStatus.resolvedNew;

  Map<String, dynamic> toMap() {
    return {
      'matchedPersonId': matchedPersonId,
      'matchType': matchType.name,
      'status': status.name,
      'confidence': confidence,
      'isNewPerson': isNewPerson,
      'requiresReview': requiresReview,
      'resolvedPerson': resolvedPerson?.toMap(),
      'candidates': candidates.map((c) => c.toMap()).toList(),
      'conflicts': conflicts.map((c) => c.toMap()).toList(),
      'matchedFields': matchedFields,
      'extractedFields': extractedFields,
      'createdActivityId': createdActivityId,
      'errorMessage': errorMessage,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory EntityResolutionResult.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawPerson = map['resolvedPerson'] is Map
        ? Map<String, dynamic>.from(map['resolvedPerson'] as Map)
        : null;

    final rawCandidates = map['candidates'] as List? ?? const [];
    final parsedCandidates = rawCandidates
        .whereType<Map>()
        .map((m) => EntityResolutionCandidate.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawConflicts = map['conflicts'] as List? ?? const [];
    final parsedConflicts = rawConflicts
        .whereType<Map>()
        .map((m) => EntityConflict.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    return EntityResolutionResult(
      matchedPersonId: map['matchedPersonId']?.toString(),
      matchType: EntityMatchType.values.firstWhere(
        (e) => e.name == map['matchType'],
        orElse: () => EntityMatchType.none,
      ),
      status: EntityResolutionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EntityResolutionStatus.pending,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      isNewPerson: map['isNewPerson'] == true,
      requiresReview: map['requiresReview'] == true,
      resolvedPerson: rawPerson != null ? PersonItem.fromMap(rawPerson, map['matchedPersonId']?.toString()) : null,
      candidates: parsedCandidates,
      conflicts: parsedConflicts,
      matchedFields: (map['matchedFields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      extractedFields: map['extractedFields'] is Map ? Map<String, dynamic>.from(map['extractedFields'] as Map) : const {},
      createdActivityId: map['createdActivityId']?.toString(),
      errorMessage: map['errorMessage']?.toString(),
      resolvedAt: parseDate(map['resolvedAt']),
    );
  }

  EntityResolutionResult copyWith({
    String? matchedPersonId,
    EntityMatchType? matchType,
    EntityResolutionStatus? status,
    double? confidence,
    bool? isNewPerson,
    bool? requiresReview,
    PersonItem? resolvedPerson,
    List<EntityResolutionCandidate>? candidates,
    List<EntityConflict>? conflicts,
    List<String>? matchedFields,
    Map<String, dynamic>? extractedFields,
    String? createdActivityId,
    String? errorMessage,
    DateTime? resolvedAt,
  }) {
    return EntityResolutionResult(
      matchedPersonId: matchedPersonId ?? this.matchedPersonId,
      matchType: matchType ?? this.matchType,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      isNewPerson: isNewPerson ?? this.isNewPerson,
      requiresReview: requiresReview ?? this.requiresReview,
      resolvedPerson: resolvedPerson ?? this.resolvedPerson,
      candidates: candidates ?? this.candidates,
      conflicts: conflicts ?? this.conflicts,
      matchedFields: matchedFields ?? this.matchedFields,
      extractedFields: extractedFields ?? this.extractedFields,
      createdActivityId: createdActivityId ?? this.createdActivityId,
      errorMessage: errorMessage ?? this.errorMessage,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}