import 'package:flutter/foundation.dart';

/// Supported types of explicit network connections between two people.
enum NetworkConnectionType {
  sharedCompany,
  sharedInteraction,
  sharedProject,
  sharedCapture,
  sharedContext,
}

extension NetworkConnectionTypeExt on NetworkConnectionType {
  String get label {
    switch (this) {
      case NetworkConnectionType.sharedCompany:
        return 'Shared Company';
      case NetworkConnectionType.sharedInteraction:
        return 'Shared Interaction';
      case NetworkConnectionType.sharedProject:
        return 'Shared Project';
      case NetworkConnectionType.sharedCapture:
        return 'Shared Capture';
      case NetworkConnectionType.sharedContext:
        return 'Shared Context';
    }
  }

  String get shortTag {
    switch (this) {
      case NetworkConnectionType.sharedCompany:
        return 'Company';
      case NetworkConnectionType.sharedInteraction:
        return 'Interaction';
      case NetworkConnectionType.sharedProject:
        return 'Project';
      case NetworkConnectionType.sharedCapture:
        return 'Capture';
      case NetworkConnectionType.sharedContext:
        return 'Context';
    }
  }
}

/// A deterministic, evidence-grounded connection between two contacts in Recallr.
@immutable
class NetworkConnection {
  final String personAId;
  final String personBId;
  final String personAName;
  final String personBName;
  final NetworkConnectionType connectionType;
  final double connectionScore; // Strictly bounded 0.0 to 100.0
  final int evidenceCount;
  final List<String> evidenceIds;
  final String? sharedCompany;
  final String? sharedContext;
  final DateTime generatedAt;

  NetworkConnection({
    required String personAId,
    required String personBId,
    required this.personAName,
    required this.personBName,
    required this.connectionType,
    required double connectionScore,
    required this.evidenceCount,
    required List<String> evidenceIds,
    this.sharedCompany,
    this.sharedContext,
    DateTime? generatedAt,
  })  : assert(personAId != personBId, 'Self-connections are strictly prohibited: personA cannot be personB'),
        personAId = personAId.compareTo(personBId) <= 0 ? personAId : personBId,
        personBId = personAId.compareTo(personBId) <= 0 ? personBId : personAId,
        connectionScore = connectionScore.clamp(0.0, 100.0),
        evidenceIds = List.unmodifiable(List<String>.from(evidenceIds)),
        generatedAt = generatedAt ?? DateTime.now();

  /// Canonical edge ID ensuring (A, B) and (B, A) resolve to the exact same key.
  String get edgeId => 'conn_${personAId}_$personBId';

  /// Whether this connection involves the specified personId.
  bool involves(String personId) => personAId == personId || personBId == personId;

  /// Returns the other person's ID in this connection.
  String otherPersonId(String currentPersonId) {
    if (personAId == currentPersonId) return personBId;
    if (personBId == currentPersonId) return personAId;
    throw ArgumentError('Person $currentPersonId is not part of connection $edgeId');
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'edgeId': edgeId,
        'personAId': personAId,
        'personBId': personBId,
        'personAName': personAName,
        'personBName': personBName,
        'connectionType': connectionType.name,
        'connectionScore': connectionScore,
        'evidenceCount': evidenceCount,
        'evidenceIds': evidenceIds,
        if (sharedCompany != null) 'sharedCompany': sharedCompany,
        if (sharedContext != null) 'sharedContext': sharedContext,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory NetworkConnection.fromMap(Map<String, dynamic> map) {
    return NetworkConnection(
      personAId: map['personAId']?.toString() ?? '',
      personBId: map['personBId']?.toString() ?? '',
      personAName: map['personAName']?.toString() ?? '',
      personBName: map['personBName']?.toString() ?? '',
      connectionType: NetworkConnectionType.values.firstWhere(
        (e) => e.name == map['connectionType'],
        orElse: () => NetworkConnectionType.sharedContext,
      ),
      connectionScore: (map['connectionScore'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: (map['evidenceCount'] as num?)?.toInt() ?? 0,
      evidenceIds: (map['evidenceIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      sharedCompany: map['sharedCompany']?.toString(),
      sharedContext: map['sharedContext']?.toString(),
      generatedAt: map['generatedAt'] != null ? DateTime.tryParse(map['generatedAt'].toString()) : null,
    );
  }

  factory NetworkConnection.fromJson(Map<String, dynamic> json) => NetworkConnection.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkConnection &&
          runtimeType == other.runtimeType &&
          personAId == other.personAId &&
          personBId == other.personBId &&
          connectionType == other.connectionType;

  @override
  int get hashCode => personAId.hashCode ^ personBId.hashCode ^ connectionType.hashCode;
}
