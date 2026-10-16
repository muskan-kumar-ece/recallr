import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'network_connection.dart';
import 'network_pattern.dart';
import 'relationship_action.dart';
import 'relationship_attention.dart';
import 'relationship_cluster.dart';
import 'relationship_momentum.dart';
import 'unified_network_intelligence.dart';
import 'unified_person_intelligence.dart';

/// The canonical, top-level orchestrated snapshot of all relationship intelligence across Recallr.
///
/// This serves as the single source of truth consumed by Home, Network Dashboard,
/// People Screen, Person Dossier, and Ask context retrieval.
@immutable
class RelationshipIntelligenceSnapshot {
  final DateTime generatedAt;
  final List<UnifiedPersonRelationshipIntelligence> people;
  final UnifiedNetworkRelationshipIntelligence network;
  final List<RelationshipAttention> topAttention;
  final List<RelationshipAction> topActions;
  final List<RelationshipMomentum> topMomentum;
  final List<NetworkPattern> networkPatterns;
  final List<NetworkConnection> networkConnections;
  final List<RelationshipCluster> networkClusters;
  final Map<String, UnifiedPersonRelationshipIntelligence> _peopleById;

  RelationshipIntelligenceSnapshot({
    DateTime? generatedAt,
    List<UnifiedPersonRelationshipIntelligence> people = const [],
    required this.network,
    List<RelationshipAttention> topAttention = const [],
    List<RelationshipAction> topActions = const [],
    List<RelationshipMomentum> topMomentum = const [],
    List<NetworkPattern> networkPatterns = const [],
    List<NetworkConnection> networkConnections = const [],
    List<RelationshipCluster> networkClusters = const [],
  })  : generatedAt = generatedAt ?? DateTime.now(),
        people = List.unmodifiable(
          List<UnifiedPersonRelationshipIntelligence>.from(people)
            ..sort((a, b) => a.personName.compareTo(b.personName)),
        ),
        _peopleById = {for (final p in people) p.personId: p},
        topAttention = List.unmodifiable(
          List<RelationshipAttention>.from(topAttention)
            ..sort((a, b) => b.attentionScore.compareTo(a.attentionScore)),
        ),
        topActions = List.unmodifiable(
          List<RelationshipAction>.from(topActions)
            ..sort((a, b) {
              final pCmp = b.priority.rank.compareTo(a.priority.rank);
              if (pCmp != 0) return pCmp;
              return b.relationshipScore.compareTo(a.relationshipScore);
            }),
        ),
        topMomentum = List.unmodifiable(
          List<RelationshipMomentum>.from(topMomentum)
            ..sort((a, b) => b.momentumScore.compareTo(a.momentumScore)),
        ),
        networkPatterns = List.unmodifiable(
          List<NetworkPattern>.from(networkPatterns)
            ..sort((a, b) => b.impactScore.compareTo(a.impactScore)),
        ),
        networkConnections = List.unmodifiable(
          List<NetworkConnection>.from(networkConnections)
            ..sort((a, b) => b.connectionScore.compareTo(a.connectionScore)),
        ),
        networkClusters = List.unmodifiable(
          List<RelationshipCluster>.from(networkClusters)
            ..sort((a, b) => b.clusterStrength.compareTo(a.clusterStrength)),
        );

  /// Creates a truthful empty snapshot for unauthenticated or 0-contact state.
  factory RelationshipIntelligenceSnapshot.empty({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    return RelationshipIntelligenceSnapshot(
      generatedAt: now,
      people: const [],
      network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: now),
      topAttention: const [],
      topActions: const [],
      topMomentum: const [],
      networkPatterns: const [],
      networkConnections: const [],
      networkClusters: const [],
    );
  }

  // --- Convenience Getters ---

  bool get isEmpty => people.isEmpty;
  bool get isNotEmpty => people.isNotEmpty;
  int get totalPeople => people.length;
  int get needsAttentionCount => topAttention.where((a) => a.needsAttention).length;

  /// Retrieves unified intelligence for a specific person in O(1) time.
  UnifiedPersonRelationshipIntelligence? getPerson(String personId) => _peopleById[personId];

  /// Whether a specific person ID exists in this snapshot in O(1) time.
  bool hasPerson(String personId) => _peopleById.containsKey(personId);

  RelationshipIntelligenceSnapshot copyWith({
    DateTime? generatedAt,
    List<UnifiedPersonRelationshipIntelligence>? people,
    UnifiedNetworkRelationshipIntelligence? network,
    List<RelationshipAttention>? topAttention,
    List<RelationshipAction>? topActions,
    List<RelationshipMomentum>? topMomentum,
    List<NetworkPattern>? networkPatterns,
    List<NetworkConnection>? networkConnections,
    List<RelationshipCluster>? networkClusters,
  }) {
    return RelationshipIntelligenceSnapshot(
      generatedAt: generatedAt ?? this.generatedAt,
      people: people ?? this.people,
      network: network ?? this.network,
      topAttention: topAttention ?? this.topAttention,
      topActions: topActions ?? this.topActions,
      topMomentum: topMomentum ?? this.topMomentum,
      networkPatterns: networkPatterns ?? this.networkPatterns,
      networkConnections: networkConnections ?? this.networkConnections,
      networkClusters: networkClusters ?? this.networkClusters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'people': people.map((p) => p.toMap()).toList(),
      'network': network.toMap(),
      'topAttention': topAttention.map((a) => a.toMap()).toList(),
      'topActions': topActions.map((a) => a.toMap()).toList(),
      'topMomentum': topMomentum.map((m) => m.toMap()).toList(),
      'networkPatterns': networkPatterns.map((p) => p.toMap()).toList(),
      'networkConnections': networkConnections.map((c) => c.toMap()).toList(),
      'networkClusters': networkClusters.map((c) => c.toMap()).toList(),
    };
  }

  factory RelationshipIntelligenceSnapshot.fromMap(Map<String, dynamic> map) {
    return RelationshipIntelligenceSnapshot(
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      people: map['people'] is List
          ? (map['people'] as List)
              .whereType<Map<String, dynamic>>()
              .map(UnifiedPersonRelationshipIntelligence.fromMap)
              .toList()
          : const [],
      network: map['network'] is Map<String, dynamic>
          ? UnifiedNetworkRelationshipIntelligence.fromMap(map['network'] as Map<String, dynamic>)
          : UnifiedNetworkRelationshipIntelligence.empty(),
      topAttention: map['topAttention'] is List
          ? (map['topAttention'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipAttention.fromMap)
              .toList()
          : const [],
      topActions: map['topActions'] is List
          ? (map['topActions'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipAction.fromMap)
              .toList()
          : const [],
      topMomentum: map['topMomentum'] is List
          ? (map['topMomentum'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipMomentum.fromMap)
              .toList()
          : const [],
      networkPatterns: map['networkPatterns'] is List
          ? (map['networkPatterns'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkPattern.fromMap)
              .toList()
          : const [],
      networkConnections: map['networkConnections'] is List
          ? (map['networkConnections'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkConnection.fromMap)
              .toList()
          : const [],
      networkClusters: map['networkClusters'] is List
          ? (map['networkClusters'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipCluster.fromMap)
              .toList()
          : const [],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory RelationshipIntelligenceSnapshot.fromJson(String source) =>
      RelationshipIntelligenceSnapshot.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
