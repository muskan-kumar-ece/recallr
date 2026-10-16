import 'package:flutter/foundation.dart';
import 'network_connection.dart';
import 'network_graph.dart';
import 'network_pattern.dart';
import 'relationship_cluster.dart';

/// Canonical aggregate model for Phase 13H-06 Network Connections & Pattern Intelligence.
@immutable
class NetworkConnectionIntelligence {
  final NetworkGraph graph;
  final List<NetworkConnection> connections;
  final List<RelationshipCluster> clusters;
  final List<NetworkPattern> patterns;
  final int totalNodes;
  final int totalConnections;
  final int connectedPeople;
  final int isolatedPeople;
  final int clusterCount;
  final NetworkConnection? strongestConnection;
  final RelationshipCluster? strongestCluster;
  final List<String> bridgeContacts;
  final double networkDensity; // Actual / possible edges (0.0 to 1.0)
  final double crossCompanyConnectivity; // 0.0 to 100.0
  final double concentrationScore; // 0.0 to 100.0
  final DateTime generatedAt;

  NetworkConnectionIntelligence({
    required this.graph,
    required List<NetworkConnection> connections,
    required List<RelationshipCluster> clusters,
    required List<NetworkPattern> patterns,
    required this.totalNodes,
    required this.totalConnections,
    required this.connectedPeople,
    required this.isolatedPeople,
    required this.clusterCount,
    this.strongestConnection,
    this.strongestCluster,
    required List<String> bridgeContacts,
    required double networkDensity,
    required double crossCompanyConnectivity,
    required double concentrationScore,
    DateTime? generatedAt,
  })  : connections = List.unmodifiable(List<NetworkConnection>.from(connections)..sort((a, b) => b.connectionScore.compareTo(a.connectionScore))),
        clusters = List.unmodifiable(List<RelationshipCluster>.from(clusters)..sort((a, b) => b.clusterStrength.compareTo(a.clusterStrength))),
        patterns = List.unmodifiable(List<NetworkPattern>.from(patterns)..sort((a, b) => b.impactScore.compareTo(a.impactScore))),
        bridgeContacts = List.unmodifiable(List<String>.from(bridgeContacts)..sort()),
        networkDensity = networkDensity.clamp(0.0, 1.0),
        crossCompanyConnectivity = crossCompanyConnectivity.clamp(0.0, 100.0),
        concentrationScore = concentrationScore.clamp(0.0, 100.0),
        generatedAt = generatedAt ?? DateTime.now();

  /// Creates a truthful empty state for empty networks.
  factory NetworkConnectionIntelligence.empty() {
    return NetworkConnectionIntelligence(
      graph: NetworkGraph.empty(),
      connections: const [],
      clusters: const [],
      patterns: const [],
      totalNodes: 0,
      totalConnections: 0,
      connectedPeople: 0,
      isolatedPeople: 0,
      clusterCount: 0,
      bridgeContacts: const [],
      networkDensity: 0.0,
      crossCompanyConnectivity: 0.0,
      concentrationScore: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  /// Whether the network contains sufficient connections to form clusters.
  bool get hasClusters => clusters.isNotEmpty;

  /// Whether any bridge contacts link distinct clusters.
  bool get hasBridges => bridgeContacts.isNotEmpty;

  /// Density as a percentage string (e.g. "12.4%").
  String get densityPercentageString => '${(networkDensity * 100.0).toStringAsFixed(1)}%';

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'totalNodes': totalNodes,
        'totalConnections': totalConnections,
        'connectedPeople': connectedPeople,
        'isolatedPeople': isolatedPeople,
        'clusterCount': clusterCount,
        'networkDensity': networkDensity,
        'crossCompanyConnectivity': crossCompanyConnectivity,
        'concentrationScore': concentrationScore,
        'bridgeContacts': bridgeContacts,
        'strongestConnection': strongestConnection?.toJson(),
        'strongestCluster': strongestCluster?.toJson(),
        'connections': connections.map((c) => c.toJson()).toList(),
        'clusters': clusters.map((cl) => cl.toJson()).toList(),
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'graph': graph.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory NetworkConnectionIntelligence.fromMap(Map<String, dynamic> map) {
    final rawConns = (map['connections'] as List<dynamic>?)
            ?.map((e) => NetworkConnection.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final rawClusters = (map['clusters'] as List<dynamic>?)
            ?.map((e) => RelationshipCluster.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final rawPatterns = (map['patterns'] as List<dynamic>?)
            ?.map((e) => NetworkPattern.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final rawGraph = map['graph'] != null
        ? NetworkGraph.fromMap(map['graph'] as Map<String, dynamic>)
        : NetworkGraph.empty();

    return NetworkConnectionIntelligence(
      graph: rawGraph,
      connections: rawConns,
      clusters: rawClusters,
      patterns: rawPatterns,
      totalNodes: (map['totalNodes'] as num?)?.toInt() ?? 0,
      totalConnections: (map['totalConnections'] as num?)?.toInt() ?? 0,
      connectedPeople: (map['connectedPeople'] as num?)?.toInt() ?? 0,
      isolatedPeople: (map['isolatedPeople'] as num?)?.toInt() ?? 0,
      clusterCount: (map['clusterCount'] as num?)?.toInt() ?? 0,
      strongestConnection: map['strongestConnection'] != null
          ? NetworkConnection.fromMap(map['strongestConnection'] as Map<String, dynamic>)
          : null,
      strongestCluster: map['strongestCluster'] != null
          ? RelationshipCluster.fromMap(map['strongestCluster'] as Map<String, dynamic>)
          : null,
      bridgeContacts: (map['bridgeContacts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      networkDensity: (map['networkDensity'] as num?)?.toDouble() ?? 0.0,
      crossCompanyConnectivity: (map['crossCompanyConnectivity'] as num?)?.toDouble() ?? 0.0,
      concentrationScore: (map['concentrationScore'] as num?)?.toDouble() ?? 0.0,
      generatedAt: map['generatedAt'] != null ? DateTime.tryParse(map['generatedAt'].toString()) : null,
    );
  }

  factory NetworkConnectionIntelligence.fromJson(Map<String, dynamic> json) =>
      NetworkConnectionIntelligence.fromMap(json);
}
