import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'network_connection.dart';
import 'network_connection_intelligence.dart';
import 'network_graph.dart';
import 'network_insight.dart';
import 'network_intelligence.dart';
import 'network_pattern.dart';
import 'network_trend.dart';
import 'relationship_attention.dart';
import 'relationship_cluster.dart';
import 'relationship_momentum.dart';

/// Fully composed, unified relationship intelligence model for the entire professional network.
///
/// Unifies 13H-04 (Health, Trends, Insights), 13H-06 (Connections, Clusters, Graph, Patterns),
/// Top Attention (13H-03), and Top Momentum (13H-05).
@immutable
class UnifiedNetworkRelationshipIntelligence {
  final NetworkHealth health;
  final List<NetworkTrend> trends;
  final List<NetworkInsight> insights;
  final List<NetworkConnection> connections;
  final List<RelationshipCluster> clusters;
  final List<NetworkPattern> patterns;
  final List<RelationshipAttention> topAttention;
  final List<RelationshipMomentum> topMomentum;
  final NetworkGraph graph;
  final List<String> bridgeContacts;
  final double networkDensity;
  final double crossCompanyConnectivity;
  final double concentrationScore;
  final DateTime generatedAt;

  UnifiedNetworkRelationshipIntelligence({
    required this.health,
    List<NetworkTrend> trends = const [],
    List<NetworkInsight> insights = const [],
    List<NetworkConnection> connections = const [],
    List<RelationshipCluster> clusters = const [],
    List<NetworkPattern> patterns = const [],
    List<RelationshipAttention> topAttention = const [],
    List<RelationshipMomentum> topMomentum = const [],
    NetworkGraph? graph,
    List<String> bridgeContacts = const [],
    this.networkDensity = 0.0,
    this.crossCompanyConnectivity = 0.0,
    this.concentrationScore = 0.0,
    DateTime? generatedAt,
  })  : trends = List.unmodifiable(List<NetworkTrend>.from(trends)),
        insights = List.unmodifiable(
          List<NetworkInsight>.from(insights)
            ..sort((a, b) => b.value.compareTo(a.value)),
        ),
        connections = List.unmodifiable(
          List<NetworkConnection>.from(connections)
            ..sort((a, b) => b.connectionScore.compareTo(a.connectionScore)),
        ),
        clusters = List.unmodifiable(
          List<RelationshipCluster>.from(clusters)
            ..sort((a, b) => b.clusterStrength.compareTo(a.clusterStrength)),
        ),
        patterns = List.unmodifiable(
          List<NetworkPattern>.from(patterns)
            ..sort((a, b) => b.impactScore.compareTo(a.impactScore)),
        ),
        topAttention = List.unmodifiable(
          List<RelationshipAttention>.from(topAttention)
            ..sort((a, b) => b.attentionScore.compareTo(a.attentionScore)),
        ),
        topMomentum = List.unmodifiable(
          List<RelationshipMomentum>.from(topMomentum)
            ..sort((a, b) => b.momentumScore.compareTo(a.momentumScore)),
        ),
        graph = graph ?? NetworkGraph.empty(),
        bridgeContacts = List.unmodifiable(List<String>.from(bridgeContacts)..sort()),
        generatedAt = generatedAt ?? DateTime.now();

  /// Creates an empty/fallback intelligence object for zero-state or unauthenticated access.
  factory UnifiedNetworkRelationshipIntelligence.empty({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    return UnifiedNetworkRelationshipIntelligence(
      health: NetworkHealth.empty(referenceDate: now),
      trends: const [],
      insights: const [],
      connections: const [],
      clusters: const [],
      patterns: const [],
      topAttention: const [],
      topMomentum: const [],
      graph: NetworkGraph.empty(),
      bridgeContacts: const [],
      networkDensity: 0.0,
      crossCompanyConnectivity: 0.0,
      concentrationScore: 0.0,
      generatedAt: now,
    );
  }

  // --- Aggregate Metrics from Specifications ---

  int get totalPeople => health.totalPeople;
  int get strongRelationships => health.strongRelationships;
  int get activeRelationships => health.activeRelationships;
  int get coolingRelationships => health.coolingRelationships;
  int get neglectedRelationships => health.neglectedRelationships;
  int get dormantRelationships => health.dormantRelationships;
  int get newRelationships => health.newRelationships;

  int get attentionCount => health.relationshipsNeedingAttention;
  int get overdueCount => health.overdueFollowUps;

  double get networkHealthScore => health.score;
  NetworkHealthLevel get networkHealthLevel => health.level;
  NetworkConfidence get networkConfidence => health.confidence;

  int get totalNodes => graph.nodeCount;
  int get totalConnections => connections.length;
  int get connectedPeople => graph.nodes.where((n) => !graph.isIsolated(n.personId)).length;
  int get isolatedPeople => graph.isolatedPersonIds.length;
  int get clusterCount => clusters.length;

  /// Adapts unified network intelligence to 13H-06 NetworkConnectionIntelligence model.
  NetworkConnectionIntelligence toConnectionIntelligence() {
    return NetworkConnectionIntelligence(
      graph: graph,
      connections: connections,
      clusters: clusters,
      patterns: patterns,
      totalNodes: graph.nodeCount,
      totalConnections: connections.length,
      connectedPeople: connectedPeople,
      isolatedPeople: isolatedPeople,
      clusterCount: clusters.length,
      strongestConnection: connections.isNotEmpty ? connections.first : null,
      strongestCluster: clusters.isNotEmpty ? clusters.first : null,
      bridgeContacts: bridgeContacts,
      networkDensity: networkDensity,
      crossCompanyConnectivity: crossCompanyConnectivity,
      concentrationScore: concentrationScore,
      generatedAt: generatedAt,
    );
  }

  int get strengtheningCount =>
      topMomentum.where((m) => m.direction == MomentumDirection.strengthening).length;
  int get stableCount =>
      topMomentum.where((m) => m.direction == MomentumDirection.stable).length;
  int get coolingMomentumCount =>
      topMomentum.where((m) => m.direction == MomentumDirection.cooling).length;
  int get decliningCount =>
      topMomentum.where((m) => m.direction == MomentumDirection.declining).length;
  int get recoveringCount =>
      topMomentum.where((m) => m.direction == MomentumDirection.recovering).length;

  String get densityPercentageString =>
      '${(networkDensity * 100.0).toStringAsFixed(1)}%';

  bool get hasData => totalPeople > 0;
  bool get isEmpty => totalPeople == 0;
  bool get isNotEmpty => totalPeople > 0;

  UnifiedNetworkRelationshipIntelligence copyWith({
    NetworkHealth? health,
    List<NetworkTrend>? trends,
    List<NetworkInsight>? insights,
    List<NetworkConnection>? connections,
    List<RelationshipCluster>? clusters,
    List<NetworkPattern>? patterns,
    List<RelationshipAttention>? topAttention,
    List<RelationshipMomentum>? topMomentum,
    NetworkGraph? graph,
    List<String>? bridgeContacts,
    double? networkDensity,
    double? crossCompanyConnectivity,
    double? concentrationScore,
    DateTime? generatedAt,
  }) {
    return UnifiedNetworkRelationshipIntelligence(
      health: health ?? this.health,
      trends: trends ?? this.trends,
      insights: insights ?? this.insights,
      connections: connections ?? this.connections,
      clusters: clusters ?? this.clusters,
      patterns: patterns ?? this.patterns,
      topAttention: topAttention ?? this.topAttention,
      topMomentum: topMomentum ?? this.topMomentum,
      graph: graph ?? this.graph,
      bridgeContacts: bridgeContacts ?? this.bridgeContacts,
      networkDensity: networkDensity ?? this.networkDensity,
      crossCompanyConnectivity: crossCompanyConnectivity ?? this.crossCompanyConnectivity,
      concentrationScore: concentrationScore ?? this.concentrationScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'health': health.toMap(),
      'trends': trends.map((t) => t.toMap()).toList(),
      'insights': insights.map((i) => i.toMap()).toList(),
      'connections': connections.map((c) => c.toMap()).toList(),
      'clusters': clusters.map((c) => c.toMap()).toList(),
      'patterns': patterns.map((p) => p.toMap()).toList(),
      'topAttention': topAttention.map((a) => a.toMap()).toList(),
      'topMomentum': topMomentum.map((m) => m.toMap()).toList(),
      'graph': graph.toMap(),
      'bridgeContacts': bridgeContacts,
      'networkDensity': networkDensity,
      'crossCompanyConnectivity': crossCompanyConnectivity,
      'concentrationScore': concentrationScore,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory UnifiedNetworkRelationshipIntelligence.fromMap(Map<String, dynamic> map) {
    return UnifiedNetworkRelationshipIntelligence(
      health: map['health'] is Map<String, dynamic>
          ? NetworkHealth.fromMap(map['health'] as Map<String, dynamic>)
          : NetworkHealth.empty(),
      trends: map['trends'] is List
          ? (map['trends'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkTrend.fromMap)
              .toList()
          : const [],
      insights: map['insights'] is List
          ? (map['insights'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkInsight.fromMap)
              .toList()
          : const [],
      connections: map['connections'] is List
          ? (map['connections'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkConnection.fromMap)
              .toList()
          : const [],
      clusters: map['clusters'] is List
          ? (map['clusters'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipCluster.fromMap)
              .toList()
          : const [],
      patterns: map['patterns'] is List
          ? (map['patterns'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NetworkPattern.fromMap)
              .toList()
          : const [],
      topAttention: map['topAttention'] is List
          ? (map['topAttention'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipAttention.fromMap)
              .toList()
          : const [],
      topMomentum: map['topMomentum'] is List
          ? (map['topMomentum'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RelationshipMomentum.fromMap)
              .toList()
          : const [],
      graph: map['graph'] is Map<String, dynamic>
          ? NetworkGraph.fromMap(map['graph'] as Map<String, dynamic>)
          : NetworkGraph.empty(),
      bridgeContacts: map['bridgeContacts'] is List
          ? List<String>.from(map['bridgeContacts'] as List)
          : const [],
      networkDensity: (map['networkDensity'] as num?)?.toDouble() ?? 0.0,
      crossCompanyConnectivity: (map['crossCompanyConnectivity'] as num?)?.toDouble() ?? 0.0,
      concentrationScore: (map['concentrationScore'] as num?)?.toDouble() ?? 0.0,
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UnifiedNetworkRelationshipIntelligence.fromJson(String source) =>
      UnifiedNetworkRelationshipIntelligence.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
