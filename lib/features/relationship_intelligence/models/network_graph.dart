import 'package:flutter/foundation.dart';
import 'network_connection.dart';
import 'relationship_momentum.dart';
import 'relationship_state.dart';

/// Node representing an individual contact inside the in-memory relationship graph.
@immutable
class NetworkGraphNode {
  final String personId;
  final String personName;
  final String company;
  final double relationshipStrength; // 0.0 to 100.0
  final RelationshipState relationshipState;
  final MomentumDirection momentumDirection;

  const NetworkGraphNode({
    required this.personId,
    required this.personName,
    required this.company,
    required this.relationshipStrength,
    required this.relationshipState,
    required this.momentumDirection,
  });

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'personName': personName,
        'company': company,
        'relationshipStrength': relationshipStrength,
        'relationshipState': relationshipState.name,
        'momentumDirection': momentumDirection.name,
      };

  factory NetworkGraphNode.fromMap(Map<String, dynamic> map) {
    return NetworkGraphNode(
      personId: map['personId']?.toString() ?? '',
      personName: map['personName']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      relationshipStrength: (map['relationshipStrength'] as num?)?.toDouble() ?? 0.0,
      relationshipState: RelationshipState.values.firstWhere(
        (e) => e.name == map['relationshipState'],
        orElse: () => RelationshipState.newRelationship,
      ),
      momentumDirection: MomentumDirection.values.firstWhere(
        (e) => e.name == map['momentumDirection'],
        orElse: () => MomentumDirection.insufficientHistory,
      ),
    );
  }

  factory NetworkGraphNode.fromJson(Map<String, dynamic> json) => NetworkGraphNode.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkGraphNode &&
          runtimeType == other.runtimeType &&
          personId == other.personId;

  @override
  int get hashCode => personId.hashCode;
}

/// In-memory graph structure representing the user's professional network.
@immutable
class NetworkGraph {
  final List<NetworkGraphNode> nodes;
  final List<NetworkConnection> connections;

  NetworkGraph({
    required List<NetworkGraphNode> nodes,
    required List<NetworkConnection> connections,
  })  : nodes = List.unmodifiable(List<NetworkGraphNode>.from(nodes)..sort((a, b) => a.personId.compareTo(b.personId))),
        connections = List.unmodifiable(List<NetworkConnection>.from(connections)..sort((a, b) => a.edgeId.compareTo(b.edgeId)));

  factory NetworkGraph.empty() => NetworkGraph(nodes: const [], connections: const []);

  int get nodeCount => nodes.length;
  int get edgeCount => connections.length;
  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;

  /// Returns all connections for a specific person ID.
  List<NetworkConnection> connectionsFor(String personId) {
    return connections.where((c) => c.involves(personId)).toList();
  }

  /// Returns all neighbor person IDs for a specific contact.
  Set<String> neighborIdsFor(String personId) {
    final result = <String>{};
    for (final conn in connections) {
      if (conn.personAId == personId) {
        result.add(conn.personBId);
      } else if (conn.personBId == personId) {
        result.add(conn.personAId);
      }
    }
    return result;
  }

  /// Returns whether a contact has zero connections in the graph.
  bool isIsolated(String personId) => neighborIdsFor(personId).isEmpty;

  /// Returns all isolated node person IDs.
  List<String> get isolatedPersonIds {
    final connectedSet = <String>{};
    for (final conn in connections) {
      connectedSet.add(conn.personAId);
      connectedSet.add(conn.personBId);
    }
    return nodes.where((n) => !connectedSet.contains(n.personId)).map((n) => n.personId).toList();
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'nodeCount': nodeCount,
        'edgeCount': edgeCount,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'connections': connections.map((c) => c.toJson()).toList(),
      };

  factory NetworkGraph.fromMap(Map<String, dynamic> map) {
    final rawNodes = (map['nodes'] as List<dynamic>?)
            ?.map((e) => NetworkGraphNode.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final rawConns = (map['connections'] as List<dynamic>?)
            ?.map((e) => NetworkConnection.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return NetworkGraph(nodes: rawNodes, connections: rawConns);
  }

  factory NetworkGraph.fromJson(Map<String, dynamic> json) => NetworkGraph.fromMap(json);
}
