import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'network_connection.dart';
import 'network_pattern.dart';
import 'relationship_action.dart';
import 'relationship_attention.dart';
import 'relationship_momentum.dart';
import 'relationship_signals.dart';
import 'relationship_state.dart';
import 'relationship_strength.dart';
import 'relationship_intelligence.dart';

/// Fully composed, unified relationship intelligence model for a single person.
///
/// Unifies 13H-01 (Signals, Strength, State), 13H-02 (Action), 13H-03 (Attention),
/// 13H-05 (Momentum), and 13H-06 (Connections, Patterns) into a single deterministic entity.
@immutable
class UnifiedPersonRelationshipIntelligence {
  final String personId;
  final String personName;
  final String company;
  final RelationshipSignals relationshipSignals;
  final RelationshipStrength relationshipStrength;
  final RelationshipState relationshipState;
  final RelationshipAction? relationshipAction;
  final RelationshipAttention? relationshipAttention;
  final RelationshipMomentum? relationshipMomentum;
  final List<NetworkConnection> networkConnections;
  final List<NetworkPattern> networkPatterns;
  final bool isBridge;
  final List<String> clusterIds;
  final DateTime generatedAt;

  UnifiedPersonRelationshipIntelligence({
    required this.personId,
    this.personName = '',
    this.company = '',
    required this.relationshipSignals,
    required this.relationshipStrength,
    required this.relationshipState,
    this.relationshipAction,
    this.relationshipAttention,
    this.relationshipMomentum,
    List<NetworkConnection> networkConnections = const [],
    List<NetworkPattern> networkPatterns = const [],
    this.isBridge = false,
    List<String> clusterIds = const [],
    DateTime? generatedAt,
  })  : networkConnections = List.unmodifiable(
          List<NetworkConnection>.from(networkConnections)
            ..sort((a, b) => b.connectionScore.compareTo(a.connectionScore)),
        ),
        networkPatterns = List.unmodifiable(
          List<NetworkPattern>.from(networkPatterns)
            ..sort((a, b) => b.impactScore.compareTo(a.impactScore)),
        ),
        clusterIds = List.unmodifiable(List<String>.from(clusterIds)..sort()),
        generatedAt = generatedAt ?? DateTime.now();

  /// Creates an empty/fallback intelligence object for unauthenticated or sparse states.
  factory UnifiedPersonRelationshipIntelligence.empty(
    String personId, {
    String personName = '',
    String company = '',
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    return UnifiedPersonRelationshipIntelligence(
      personId: personId,
      personName: personName,
      company: company,
      relationshipSignals: RelationshipSignals.empty(),
      relationshipStrength: RelationshipStrength.empty(),
      relationshipState: RelationshipState.newRelationship,
      relationshipAction: null,
      relationshipAttention: null,
      relationshipMomentum: RelationshipMomentum.insufficientHistory(
        personId: personId,
        referenceDate: now,
      ),
      networkConnections: const [],
      networkPatterns: const [],
      isBridge: false,
      clusterIds: const [],
      generatedAt: now,
    );
  }

  // --- Convenience Properties ---

  double get strengthScore => relationshipStrength.score;
  double get attentionScore => relationshipAttention?.score ?? 0.0;
  AttentionPriority get attentionPriority =>
      relationshipAttention?.priority ?? AttentionPriority.none;
  bool get needsAttention => relationshipAttention?.needsAttention ?? false;
  MomentumDirection get momentumDirection =>
      relationshipMomentum?.direction ?? MomentumDirection.insufficientHistory;
  double get momentumScore => relationshipMomentum?.momentumScore ?? 0.0;
  RelationshipAction? get primaryAction => relationshipAction;
  bool get hasAction => relationshipAction != null;
  bool get isIsolated => networkConnections.isEmpty;
  int get connectionCount => networkConnections.length;

  /// Returns backwards-compatible PersonRelationshipIntelligence view.
  PersonRelationshipIntelligence get baseIntelligence => PersonRelationshipIntelligence(
        personId: personId,
        signals: relationshipSignals,
        strength: relationshipStrength,
        state: relationshipState,
        generatedAt: generatedAt,
        explanations: relationshipStrength.factors.map((f) => f.explanation).toList(),
        topFactors: relationshipStrength.factors.take(3).toList(),
      );

  /// Returns connections involving a specific partner contact.
  NetworkConnection? connectionWith(String otherPersonId) {
    for (final conn in networkConnections) {
      if (conn.involves(otherPersonId)) return conn;
    }
    return null;
  }

  UnifiedPersonRelationshipIntelligence copyWith({
    String? personId,
    String? personName,
    String? company,
    RelationshipSignals? relationshipSignals,
    RelationshipStrength? relationshipStrength,
    RelationshipState? relationshipState,
    RelationshipAction? relationshipAction,
    RelationshipAttention? relationshipAttention,
    RelationshipMomentum? relationshipMomentum,
    List<NetworkConnection>? networkConnections,
    List<NetworkPattern>? networkPatterns,
    bool? isBridge,
    List<String>? clusterIds,
    DateTime? generatedAt,
  }) {
    return UnifiedPersonRelationshipIntelligence(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      company: company ?? this.company,
      relationshipSignals: relationshipSignals ?? this.relationshipSignals,
      relationshipStrength: relationshipStrength ?? this.relationshipStrength,
      relationshipState: relationshipState ?? this.relationshipState,
      relationshipAction: relationshipAction ?? this.relationshipAction,
      relationshipAttention: relationshipAttention ?? this.relationshipAttention,
      relationshipMomentum: relationshipMomentum ?? this.relationshipMomentum,
      networkConnections: networkConnections ?? this.networkConnections,
      networkPatterns: networkPatterns ?? this.networkPatterns,
      isBridge: isBridge ?? this.isBridge,
      clusterIds: clusterIds ?? this.clusterIds,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'personName': personName,
      'company': company,
      'relationshipSignals': relationshipSignals.toMap(),
      'relationshipStrength': relationshipStrength.toMap(),
      'relationshipState': relationshipState.name,
      'relationshipAction': relationshipAction?.toMap(),
      'relationshipAttention': relationshipAttention?.toMap(),
      'relationshipMomentum': relationshipMomentum?.toMap(),
      'networkConnections': networkConnections.map((c) => c.toMap()).toList(),
      'networkPatterns': networkPatterns.map((p) => p.toMap()).toList(),
      'isBridge': isBridge,
      'clusterIds': clusterIds,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory UnifiedPersonRelationshipIntelligence.fromMap(Map<String, dynamic> map) {
    return UnifiedPersonRelationshipIntelligence(
      personId: map['personId'] as String? ?? '',
      personName: map['personName'] as String? ?? '',
      company: map['company'] as String? ?? '',
      relationshipSignals: map['relationshipSignals'] is Map<String, dynamic>
          ? RelationshipSignals.fromMap(map['relationshipSignals'] as Map<String, dynamic>)
          : RelationshipSignals.empty(),
      relationshipStrength: map['relationshipStrength'] is Map<String, dynamic>
          ? RelationshipStrength.fromMap(map['relationshipStrength'] as Map<String, dynamic>)
          : RelationshipStrength.empty(),
      relationshipState: RelationshipState.values.firstWhere(
        (s) => s.name == map['relationshipState'],
        orElse: () => RelationshipState.newRelationship,
      ),
      relationshipAction: map['relationshipAction'] is Map<String, dynamic>
          ? RelationshipAction.fromMap(map['relationshipAction'] as Map<String, dynamic>)
          : null,
      relationshipAttention: map['relationshipAttention'] is Map<String, dynamic>
          ? RelationshipAttention.fromMap(map['relationshipAttention'] as Map<String, dynamic>)
          : null,
      relationshipMomentum: map['relationshipMomentum'] is Map<String, dynamic>
          ? RelationshipMomentum.fromMap(map['relationshipMomentum'] as Map<String, dynamic>)
          : null,
      networkConnections: map['networkConnections'] is List
          ? (map['networkConnections'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkConnection.fromMap)
              .toList()
          : const [],
      networkPatterns: map['networkPatterns'] is List
          ? (map['networkPatterns'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkPattern.fromMap)
              .toList()
          : const [],
      isBridge: map['isBridge'] as bool? ?? false,
      clusterIds: map['clusterIds'] is List
          ? List<String>.from(map['clusterIds'] as List)
          : const [],
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UnifiedPersonRelationshipIntelligence.fromJson(String source) =>
      UnifiedPersonRelationshipIntelligence.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedPersonRelationshipIntelligence &&
          runtimeType == other.runtimeType &&
          personId == other.personId &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => personId.hashCode ^ generatedAt.hashCode;
}
