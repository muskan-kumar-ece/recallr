import 'package:flutter/foundation.dart';
import '../../features/activity/models/activity_models.dart';
import '../../repositories/activity_repository.dart';
import '../../features/capture/models/capture_models.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/people_repository.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../repositories/person_detail_repository.dart';
import '../../features/relationship_intelligence/models/network_connection.dart';
import '../../features/relationship_intelligence/models/network_connection_intelligence.dart';
import '../../features/relationship_intelligence/models/network_graph.dart';
import '../../features/relationship_intelligence/models/network_pattern.dart';
import '../../features/relationship_intelligence/models/relationship_cluster.dart';
import '../../features/relationship_intelligence/models/relationship_momentum.dart';
import '../../features/relationship_intelligence/models/relationship_state.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';
import 'network_cluster_detector.dart';
import 'network_connection_calculator.dart';
import 'network_pattern_engine.dart';
import 'relationship_intelligence_service.dart';
import 'relationship_momentum_engine.dart';

/// Contract for Phase 13H-06 Network Connection & Patterns Intelligence Service.
abstract class NetworkConnectionIntelligenceService {
  Future<NetworkConnectionIntelligence> getNetworkConnectionIntelligence({
    DateTime? referenceDate,
  });

  Future<NetworkGraph> getNetworkGraph({
    DateTime? referenceDate,
  });

  Future<List<NetworkConnection>> getConnections({
    DateTime? referenceDate,
  });

  Future<List<RelationshipCluster>> getClusters({
    DateTime? referenceDate,
  });

  Future<List<NetworkPattern>> getPatterns({
    DateTime? referenceDate,
  });

  Stream<NetworkConnectionIntelligence> streamNetworkConnectionIntelligence({
    DateTime? referenceDate,
  });

  /// Synchronous computation engine for deterministic evaluation.
  NetworkConnectionIntelligence computeIntelligenceSync({
    required List<PersonProfile> profiles,
    List<ActivityItem> activities = const [],
    List<CaptureItem> captures = const [],
    DateTime? referenceDate,
  });
}

/// Production implementation of NetworkConnectionIntelligenceService.
@immutable
class DeterministicNetworkConnectionIntelligenceService implements NetworkConnectionIntelligenceService {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository activityRepository;
  final CaptureRepository captureRepository;
  final RelationshipIntelligenceService? relationshipIntelligenceService;
  final RelationshipMomentumEngine? momentumEngine;
  final NetworkConnectionCalculator connectionCalculator;
  final NetworkClusterDetector clusterDetector;
  final NetworkPatternEngine patternEngine;

  const DeterministicNetworkConnectionIntelligenceService({
    required this.peopleRepository,
    required this.personDetailRepository,
    required this.activityRepository,
    required this.captureRepository,
    this.relationshipIntelligenceService,
    this.momentumEngine,
    this.connectionCalculator = const DeterministicNetworkConnectionCalculator(),
    this.clusterDetector = const DeterministicNetworkClusterDetector(),
    this.patternEngine = const DeterministicNetworkPatternEngine(),
  });

  @override
  Future<NetworkConnectionIntelligence> getNetworkConnectionIntelligence({
    DateTime? referenceDate,
  }) async {
    final people = await peopleRepository.streamPeople().first;
    if (people.isEmpty) {
      return NetworkConnectionIntelligence.empty();
    }

    final profilesList = await Future.wait(
      people.map((p) => personDetailRepository.getProfile(p.id)),
    );
    final profiles = profilesList.whereType<PersonProfile>().toList();

    final activities = await activityRepository.streamActivities().first;
    final captures = await captureRepository.streamRecentCaptures(limit: 100).first;

    return computeIntelligenceSync(
      profiles: profiles,
      activities: activities,
      captures: captures,
      referenceDate: referenceDate,
    );
  }

  @override
  Future<NetworkGraph> getNetworkGraph({DateTime? referenceDate}) async {
    final intel = await getNetworkConnectionIntelligence(referenceDate: referenceDate);
    return intel.graph;
  }

  @override
  Future<List<NetworkConnection>> getConnections({DateTime? referenceDate}) async {
    final intel = await getNetworkConnectionIntelligence(referenceDate: referenceDate);
    return intel.connections;
  }

  @override
  Future<List<RelationshipCluster>> getClusters({DateTime? referenceDate}) async {
    final intel = await getNetworkConnectionIntelligence(referenceDate: referenceDate);
    return intel.clusters;
  }

  @override
  Future<List<NetworkPattern>> getPatterns({DateTime? referenceDate}) async {
    final intel = await getNetworkConnectionIntelligence(referenceDate: referenceDate);
    return intel.patterns;
  }

  @override
  Stream<NetworkConnectionIntelligence> streamNetworkConnectionIntelligence({
    DateTime? referenceDate,
  }) {
    return peopleRepository.streamPeople().asyncMap((people) async {
      if (people.isEmpty) {
        return NetworkConnectionIntelligence.empty();
      }
      final profilesList = await Future.wait(
        people.map((p) => personDetailRepository.getProfile(p.id)),
      );
      final profiles = profilesList.whereType<PersonProfile>().toList();
      final activities = await activityRepository.streamActivities().first;
      final captures = await captureRepository.streamRecentCaptures(limit: 100).first;

      return computeIntelligenceSync(
        profiles: profiles,
        activities: activities,
        captures: captures,
        referenceDate: referenceDate,
      );
    });
  }

  /// Synchronous computation engine for deterministic evaluation.
  NetworkConnectionIntelligence computeIntelligenceSync({
    required List<PersonProfile> profiles,
    List<ActivityItem> activities = const [],
    List<CaptureItem> captures = const [],
    DateTime? referenceDate,
  }) {
    if (profiles.isEmpty) {
      return NetworkConnectionIntelligence.empty();
    }

    final refDate = referenceDate ?? DateTime.now();

    // 1. Compute strength scores and states for all profiles
    final Map<String, RelationshipStrength> strengths = {};
    final Map<String, RelationshipState> states = {};
    final Map<String, MomentumDirection> momentums = {};

    for (final p in profiles) {
      final strLower = p.relationshipStrength.toLowerCase();
      double score = 50.0;
      RelationshipState state = RelationshipState.active;
      MomentumDirection dir = MomentumDirection.stable;

      if (p.totalInteractions == 0) {
        score = 0.0;
        state = RelationshipState.newRelationship;
        dir = MomentumDirection.insufficientHistory;
      } else if (strLower.contains('strong') || strLower.contains('high') || p.totalInteractions >= 6) {
        score = 85.0;
        state = RelationshipState.strong;
        dir = MomentumDirection.strengthening;
      } else if (strLower.contains('cooling')) {
        score = 45.0;
        state = RelationshipState.cooling;
        dir = MomentumDirection.cooling;
      } else if (strLower.contains('neglected') || strLower.contains('declining')) {
        score = 30.0;
        state = RelationshipState.neglected;
        dir = MomentumDirection.declining;
      } else if (strLower.contains('dormant')) {
        score = 15.0;
        state = RelationshipState.dormant;
        dir = MomentumDirection.declining;
      }

      strengths[p.id] = RelationshipStrength(
        score: score,
        level: state.displayName,
        summary: '\${p.totalInteractions} interactions',
        factors: const [],
      );
      states[p.id] = state;
      momentums[p.id] = dir;
    }

    // 2. Discover Explicit Connections
    final connections = connectionCalculator.calculateConnections(
      profiles: profiles,
      activities: activities,
      captures: captures,
      strengths: strengths,
      referenceDate: refDate,
    );

    // 3. Build In-Memory Network Graph
    final nodes = profiles.map((p) {
      return NetworkGraphNode(
        personId: p.id,
        personName: p.name,
        company: p.company,
        relationshipStrength: strengths[p.id]?.score ?? 50.0,
        relationshipState: states[p.id] ?? RelationshipState.active,
        momentumDirection: momentums[p.id] ?? MomentumDirection.stable,
      );
    }).toList();

    final graph = NetworkGraph(nodes: nodes, connections: connections);

    // 4. Detect Relationship Clusters
    final clusters = clusterDetector.detectClusters(
      profiles: profiles,
      connections: connections,
      strengths: strengths,
      referenceDate: refDate,
    );

    // 5. Detect Network Patterns
    final patterns = patternEngine.detectPatterns(
      graph: graph,
      connections: connections,
      clusters: clusters,
      strengths: strengths,
      referenceDate: refDate,
    );

    // 6. Calculate Network Metrics
    final totalNodes = graph.nodeCount;
    final totalConns = graph.edgeCount;
    final isolatedIds = graph.isolatedPersonIds;
    final isolatedPeople = isolatedIds.length;
    final connectedPeople = totalNodes - isolatedPeople;

    // Density: actual edges / possible edges (n * (n - 1) / 2)
    final double density;
    if (totalNodes < 2) {
      density = 0.0;
    } else {
      final maxPossibleEdges = (totalNodes * (totalNodes - 1)) / 2;
      density = maxPossibleEdges > 0 ? (totalConns / maxPossibleEdges).clamp(0.0, 1.0) : 0.0;
    }

    // Pre-index nodes for O(1) attribute lookup
    final nodeMap = {for (final n in graph.nodes) n.personId: n};

    // Cross-company connectivity
    final crossCompanyConns = connections.where((c) {
      final nA = nodeMap[c.personAId];
      final nB = nodeMap[c.personBId];
      return nA != null && nB != null && nA.company.trim().toLowerCase() != nB.company.trim().toLowerCase();
    }).length;

    final crossCompConnectivity = totalConns > 0 ? ((crossCompanyConns / totalConns) * 100.0).clamp(0.0, 100.0) : 0.0;

    // Concentration score: max members in any single company / total contacts
    int maxCompanyCount = 0;
    final Map<String, int> companyCounts = {};
    for (final p in profiles) {
      final c = p.company.trim().toLowerCase();
      if (c.isNotEmpty && c != 'unknown') {
        companyCounts[c] = (companyCounts[c] ?? 0) + 1;
        if (companyCounts[c]! > maxCompanyCount) {
          maxCompanyCount = companyCounts[c]!;
        }
      }
    }
    final concentration = totalNodes > 0 ? ((maxCompanyCount / totalNodes) * 100.0).clamp(0.0, 100.0) : 0.0;

    // Bridge contacts
    final bridgeContacts = <String>{};
    for (final n in graph.nodes) {
      final linkedClusters = clusters.where((cl) => cl.containsPerson(n.personId)).length;
      if (linkedClusters >= 2) {
        bridgeContacts.add(n.personId);
      }
    }

    final strongestConn = connections.isNotEmpty ? connections.first : null;
    final strongestClust = clusters.isNotEmpty ? clusters.first : null;

    return NetworkConnectionIntelligence(
      graph: graph,
      connections: connections,
      clusters: clusters,
      patterns: patterns,
      totalNodes: totalNodes,
      totalConnections: totalConns,
      connectedPeople: connectedPeople,
      isolatedPeople: isolatedPeople,
      clusterCount: clusters.length,
      strongestConnection: strongestConn,
      strongestCluster: strongestClust,
      bridgeContacts: bridgeContacts.toList(),
      networkDensity: density,
      crossCompanyConnectivity: crossCompConnectivity,
      concentrationScore: concentration,
      generatedAt: refDate,
    );
  }
}
