import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/models/relationship_memory_models.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart' as pds_ri;
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_clusters_section.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_connections_summary.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_patterns_section.dart';
import 'package:recaller/repositories/activity_repository.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/repositories/people_repository.dart';
import 'package:recaller/repositories/person_detail_repository.dart';
import 'package:recaller/screens/network/network_dashboard_screen.dart';
import 'package:recaller/services/relationship/network_cluster_detector.dart';
import 'package:recaller/services/relationship/network_connection_calculator.dart';
import 'package:recaller/services/relationship/network_connection_intelligence_service.dart';
import 'package:recaller/services/relationship/network_pattern_engine.dart';

void main() {
  final refDate = DateTime(2026, 8, 30, 10, 0, 0);

  PersonProfile _buildProfile({
    required String id,
    required String name,
    required String company,
    int totalInteractions = 2,
    String relationshipStrength = 'Active',
    List<ConnectedEntity> connectedEntities = const [],
    List<MemoryItem> memories = const [],
  }) {
    return PersonProfile(
      id: id,
      name: name,
      role: 'Role for $name',
      company: company,
      location: 'Bangalore',
      initials: name.isNotEmpty ? name[0] : '?',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: relationshipStrength,
      firstMet: '2025-01-10',
      lastInteraction: '2026-08-15',
      totalInteractions: totalInteractions,
      sharedEventsCount: 1,
      aiSummary: 'Summary for $name',
      connectedEntities: connectedEntities,
      memories: memories,
    );
  }

  group('Phase 13H-06 Group 1 — Connection Detection', () {
    const calc = DeterministicNetworkConnectionCalculator();

    test('1. Zero people returns 0 connections', () {
      final conns = calc.calculateConnections(profiles: const []);
      expect(conns, isEmpty);
    });

    test('2. Single person returns 0 connections', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme Corp');
      final conns = calc.calculateConnections(profiles: [p1]);
      expect(conns, isEmpty);
    });

    test('3. Two people with same company creates sharedCompany connection', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme Corp');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme Corp');
      final conns = calc.calculateConnections(profiles: [p1, p2]);

      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedCompany));
      expect(conns.first.sharedCompany, equals('Acme Corp'));
      expect(conns.first.personAId, equals('p1'));
      expect(conns.first.personBId, equals('p2'));
    });

    test('4. Two people with different companies creates 0 connections when no other evidence', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme Corp');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Beta Labs');
      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns, isEmpty);
    });

    test('5. Case-insensitive company matching matches Acme Corp and acme corp', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme Corp');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: '  acme corp  ');
      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedCompany));
    });

    test('6. Empty or unknown company strings are ignored as connection evidence', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: '');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Unknown');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'N/A');
      final conns = calc.calculateConnections(profiles: [p1, p2, p3]);
      expect(conns, isEmpty);
    });

    test('7. Shared activity creates sharedInteraction connection', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Beta');
      final act = ActivityItem(
        id: 'act_1',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '10:00 AM',
        title: 'Strategy Sync',
        summary: 'Met with Alice and Bob',
        personId: 'p1',
        targetRoute: '/activity',
        actionLabel: 'View',
        metadata: {'relatedPersonIds': ['p2']},
      );

      final conns = calc.calculateConnections(profiles: [p1, p2], activities: [act]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedInteraction));
      expect(conns.first.evidenceIds, contains('act_act_1'));
    });

    test('8. Shared project in connectedEntities creates sharedProject connection', () {
      final proj = const ConnectedEntity(
        id: 'proj_ai',
        type: EntityType.file,
        title: 'Project Nebula',
        subtitle: 'Core Architecture',
        targetRoute: '/file/proj_ai',
      );
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme', connectedEntities: [proj]);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Beta', connectedEntities: [proj]);

      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedProject));
      expect(conns.first.sharedContext, equals('project nebula'));
    });

    test('9. Shared capture creates sharedCapture connection', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Beta');
      final cap = const CaptureItem(
        id: 'cap_1',
        type: CaptureType.businessCard,
        title: 'Conference Card',
        description: 'Meeting notes',
        timestamp: '2026-08-20',
        targetRoute: '/capture/cap_1',
        personId: 'p1',
        resolvedPersonId: 'p2',
      );

      final conns = calc.calculateConnections(profiles: [p1, p2], captures: [cap]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedCapture));
    });

    test('10. Multiple evidence types merge into single canonical edge with incremented count', () {
      final proj = const ConnectedEntity(
        id: 'proj_ai',
        type: EntityType.event,
        title: 'Nebula',
        subtitle: 'Sprint',
        targetRoute: '/event/1',
      );
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme', connectedEntities: [proj]);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme', connectedEntities: [proj]);

      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns.length, equals(1));
      expect(conns.first.evidenceCount, greaterThanOrEqualTo(2));
      expect(conns.first.sharedCompany, equals('Acme'));
      expect(conns.first.sharedContext, equals('nebula'));
    });

    test('11. Self-connection prevention throws assertion if attempted', () {
      expect(
        () => NetworkConnection(
          personAId: 'p1',
          personBId: 'p1',
          personAName: 'Alice',
          personBName: 'Alice',
          connectionType: NetworkConnectionType.sharedCompany,
          connectionScore: 80.0,
          evidenceCount: 1,
          evidenceIds: const ['ev1'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('12. Canonical pair normalization ensures min(A,B) and max(A,B) order', () {
      final conn1 = NetworkConnection(
        personAId: 'z_person',
        personBId: 'a_person',
        personAName: 'Zoe',
        personBName: 'Alice',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 50.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );

      expect(conn1.personAId, equals('a_person'));
      expect(conn1.personBId, equals('z_person'));
      expect(conn1.edgeId, equals('conn_a_person_z_person'));
    });

    test('13. otherPersonId returns correct counter-party', () {
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice',
        personBName: 'Bob',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 50.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );

      expect(conn.otherPersonId('p1'), equals('p2'));
      expect(conn.otherPersonId('p2'), equals('p1'));
      expect(() => conn.otherPersonId('p3'), throwsArgumentError);
    });
  });

  group('Phase 13H-06 Group 2 — Connection Strength & Math Bounds', () {
    const calc = DeterministicNetworkConnectionCalculator();

    test('14. Shared company alone contributes 30% baseline score plus strength/volume', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');

      final conns = calc.calculateConnections(
        profiles: [p1, p2],
        strengths: {
          'p1': const RelationshipStrength(score: 50.0, summary: '', factors: [], level: 'Medium'),
          'p2': const RelationshipStrength(score: 50.0, summary: '', factors: [], level: 'Medium'),
        },
      );

      expect(conns.length, equals(1));
      // comp: 30, vol: 1/3 * 10 = 3.33, str: 50/100 * 10 = 5.0 -> ~38.33
      expect(conns.first.connectionScore, closeTo(38.33, 1.0));
    });

    test('15. All evidence types combined reaches high connection score', () {
      final proj = const ConnectedEntity(
        id: 'p',
        type: EntityType.file,
        title: 'Project Alpha',
        subtitle: '',
        targetRoute: '',
      );
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme', connectedEntities: [proj]);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme', connectedEntities: [proj]);
      final act = ActivityItem(
        id: 'act1',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '10:00 AM',
        title: 'Meeting',
        summary: 'Sync',
        personId: 'p1',
        targetRoute: '',
        actionLabel: '',
        metadata: {'relatedPersonIds': ['p2']},
      );

      final conns = calc.calculateConnections(
        profiles: [p1, p2],
        activities: [act],
        strengths: {
          'p1': const RelationshipStrength(score: 90.0, summary: '', factors: [], level: 'High'),
          'p2': const RelationshipStrength(score: 90.0, summary: '', factors: [], level: 'High'),
        },
      );

      expect(conns.first.connectionScore, greaterThan(80.0));
      expect(conns.first.connectionScore, lessThanOrEqualTo(100.0));
    });

    test('16. Score is strictly clamped between 0.0 and 100.0', () {
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'A',
        personBName: 'B',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 150.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );
      expect(conn.connectionScore, equals(100.0));

      final conn2 = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'A',
        personBName: 'B',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: -25.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );
      expect(conn2.connectionScore, equals(0.0));
    });

    test('17. Deterministic sorting: connectionScore DESC, edgeId ASC', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Acme');

      final act = ActivityItem(
        id: 'act1',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '',
        title: '',
        summary: '',
        personId: 'p1',
        targetRoute: '',
        actionLabel: '',
        metadata: {'relatedPersonIds': ['p2']},
      );

      final conns = calc.calculateConnections(profiles: [p1, p2, p3], activities: [act]);
      expect(conns.length, equals(3));
      // p1-p2 has shared company + shared activity -> highest score
      expect(conns.first.involves('p1') && conns.first.involves('p2'), isTrue);
    });

    test('18. Memory claim project extraction creates project evidence', () {
      final mem = const MemoryItem(
        id: 'm1',
        category: 'Project Work',
        text: 'Developing Hyperion Engine',
        source: 'Note',
      );
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'A', memories: [mem]);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'B', memories: [mem]);

      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedProject));
      expect(conns.first.sharedContext, equals('developing hyperion engine'));
    });

    test('19. Mutual ConnectedEntity person reference establishes interaction edge', () {
      final entityRef = const ConnectedEntity(
        id: 'p2',
        type: EntityType.person,
        title: 'Bob Builder',
        subtitle: 'Colleague',
        targetRoute: '/person/p2',
      );
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'A', connectedEntities: [entityRef]);
      final p2 = _buildProfile(id: 'p2', name: 'Bob Builder', company: 'B');

      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns.length, equals(1));
      expect(conns.first.connectionType, equals(NetworkConnectionType.sharedInteraction));
    });

    test('20. Empty evidence handles gracefully with zero connections', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: '');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: '');
      final conns = calc.calculateConnections(profiles: [p1, p2]);
      expect(conns, isEmpty);
    });

    test('21. Score calculation is deterministic across multiple calls', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Alpha');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Alpha');

      final r1 = calc.calculateConnections(profiles: [p1, p2]);
      final r2 = calc.calculateConnections(profiles: [p1, p2]);

      expect(r1.first.connectionScore, equals(r2.first.connectionScore));
      expect(r1.first.edgeId, equals(r2.first.edgeId));
    });

    test('22. Handles 10 interconnected people without quadratic explosion', () {
      final profiles = List.generate(
        10,
        (i) => _buildProfile(id: 'p_$i', name: 'Person $i', company: 'MegaCorp'),
      );
      final conns = calc.calculateConnections(profiles: profiles);
      // 10 * 9 / 2 = 45 connections
      expect(conns.length, equals(45));
    });

    test('23. ConnectionType extension labels and tags', () {
      expect(NetworkConnectionType.sharedCompany.label, equals('Shared Company'));
      expect(NetworkConnectionType.sharedInteraction.label, equals('Shared Interaction'));
      expect(NetworkConnectionType.sharedProject.label, equals('Shared Project'));
      expect(NetworkConnectionType.sharedCapture.label, equals('Shared Capture'));
      expect(NetworkConnectionType.sharedContext.label, equals('Shared Context'));

      expect(NetworkConnectionType.sharedCompany.shortTag, equals('Company'));
      expect(NetworkConnectionType.sharedInteraction.shortTag, equals('Interaction'));
    });
  });

  group('Phase 13H-06 Group 3 — Cluster Detection & Small-N Rules', () {
    const detector = DeterministicNetworkClusterDetector();

    test('24. 0 people produces 0 clusters', () {
      final clusters = detector.detectClusters(profiles: const [], connections: const []);
      expect(clusters, isEmpty);
    });

    test('25. 1 person produces 0 clusters', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final clusters = detector.detectClusters(profiles: [p1], connections: const []);
      expect(clusters, isEmpty);
    });

    test('26. 2 people in same company produces emerging cluster', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice',
        personBName: 'Bob',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 60.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
        sharedCompany: 'Acme',
      );

      final clusters = detector.detectClusters(profiles: [p1, p2], connections: [conn]);
      expect(clusters.length, equals(1));
      expect(clusters.first.type, equals(RelationshipClusterType.emerging));
      expect(clusters.first.id, equals('cluster_company_acme'));
      expect(clusters.first.memberCount, equals(2));
      expect(clusters.first.isEstablished, isFalse);
    });

    test('27. 3+ people in same company produces established company cluster', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Acme');

      final clusters = detector.detectClusters(profiles: [p1, p2, p3], connections: const []);
      expect(clusters.length, equals(1));
      expect(clusters.first.type, equals(RelationshipClusterType.company));
      expect(clusters.first.id, equals('cluster_company_acme'));
      expect(clusters.first.memberCount, equals(3));
      expect(clusters.first.isEstablished, isTrue);
    });

    test('28. Deterministic slug generation for company names with special characters', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Google X & Alphabet!');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Google X & Alphabet!');

      final clusters = detector.detectClusters(profiles: [p1, p2], connections: const []);
      expect(clusters.first.id, equals('cluster_company_google_x_alphabet'));
    });

    test('29. Shared context / project clusters detected from connection sharedContext', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Company A');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Company B');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Company C');

      final conn1 = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice',
        personBName: 'Bob',
        connectionType: NetworkConnectionType.sharedProject,
        connectionScore: 70.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
        sharedContext: 'Project Orion',
      );
      final conn2 = NetworkConnection(
        personAId: 'p1',
        personBId: 'p3',
        personAName: 'Alice',
        personBName: 'Charlie',
        connectionType: NetworkConnectionType.sharedProject,
        connectionScore: 70.0,
        evidenceCount: 1,
        evidenceIds: const ['ev2'],
        sharedContext: 'Project Orion',
      );

      final clusters = detector.detectClusters(
        profiles: [p1, p2, p3],
        connections: [conn1, conn2],
      );

      expect(clusters.any((c) => c.id == 'cluster_project_project_orion'), isTrue);
      final orion = clusters.firstWhere((c) => c.id == 'cluster_project_project_orion');
      expect(orion.memberCount, equals(3));
      expect(orion.type, equals(RelationshipClusterType.project));
    });

    test('30. Average relationship strength and attention scores computed accurately', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');

      final clusters = detector.detectClusters(
        profiles: [p1, p2],
        connections: const [],
        strengths: {
          'p1': const RelationshipStrength(score: 80.0, summary: '', factors: [], level: 'High'),
          'p2': const RelationshipStrength(score: 60.0, summary: '', factors: [], level: 'Medium'),
        },
        attentionScores: {
          'p1': 40.0,
          'p2': 20.0,
        },
      );

      expect(clusters.first.averageRelationshipStrength, equals(70.0));
      expect(clusters.first.averageAttentionScore, equals(30.0));
    });

    test('31. Total interactions aggregated across cluster members', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme', totalInteractions: 5);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme', totalInteractions: 7);

      final clusters = detector.detectClusters(profiles: [p1, p2], connections: const []);
      expect(clusters.first.interactionCount, equals(12));
    });

    test('32. ClusterStrength composite formula bounded between 0.0 and 100.0', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme', totalInteractions: 10);
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme', totalInteractions: 10);
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Acme', totalInteractions: 10);

      final clusters = detector.detectClusters(
        profiles: [p1, p2, p3],
        connections: const [],
        strengths: {
          'p1': const RelationshipStrength(score: 90.0, summary: '', factors: [], level: 'High'),
          'p2': const RelationshipStrength(score: 90.0, summary: '', factors: [], level: 'High'),
          'p3': const RelationshipStrength(score: 90.0, summary: '', factors: [], level: 'High'),
        },
      );

      expect(clusters.first.clusterStrength, greaterThan(70.0));
      expect(clusters.first.clusterStrength, lessThanOrEqualTo(100.0));
      expect(clusters.first.isStrong, isTrue);
    });

    test('33. RelationshipClusterType extensions provide icons and color tokens', () {
      expect(RelationshipClusterType.company.label, equals('Company Cluster'));
      expect(RelationshipClusterType.project.label, equals('Project Cluster'));
      expect(RelationshipClusterType.emerging.label, equals('Emerging Cluster'));
      expect(RelationshipClusterType.company.icon, equals(Icons.business_outlined));
      expect(RelationshipClusterType.project.icon, equals(Icons.rocket_launch_outlined));
    });
  });

  group('Phase 13H-06 Group 4 — Graph Integrity & Topology', () {
    test('34. NetworkGraph sorts nodes by personId ASC and connections by edgeId ASC', () {
      final n1 = const NetworkGraphNode(
        personId: 'z_person',
        personName: 'Zoe',
        company: 'Z Corp',
        relationshipStrength: 50.0,
        relationshipState: RelationshipState.active,
        momentumDirection: MomentumDirection.stable,
      );
      final n2 = const NetworkGraphNode(
        personId: 'a_person',
        personName: 'Alice',
        company: 'A Corp',
        relationshipStrength: 80.0,
        relationshipState: RelationshipState.strong,
        momentumDirection: MomentumDirection.strengthening,
      );

      final conn = NetworkConnection(
        personAId: 'a_person',
        personBId: 'z_person',
        personAName: 'Alice',
        personBName: 'Zoe',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 70.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );

      final graph = NetworkGraph(nodes: [n1, n2], connections: [conn]);
      expect(graph.nodes.first.personId, equals('a_person'));
      expect(graph.nodes.last.personId, equals('z_person'));
      expect(graph.connections.first.edgeId, equals('conn_a_person_z_person'));
    });

    test('35. isolatedPersonIds accurately identifies contacts with 0 connections', () {
      final n1 = const NetworkGraphNode(
        personId: 'p1',
        personName: 'P1',
        company: 'C1',
        relationshipStrength: 50.0,
        relationshipState: RelationshipState.active,
        momentumDirection: MomentumDirection.stable,
      );
      final n2 = const NetworkGraphNode(
        personId: 'p2',
        personName: 'P2',
        company: 'C1',
        relationshipStrength: 50.0,
        relationshipState: RelationshipState.active,
        momentumDirection: MomentumDirection.stable,
      );
      final n3 = const NetworkGraphNode(
        personId: 'p3_isolated',
        personName: 'P3',
        company: 'C2',
        relationshipStrength: 50.0,
        relationshipState: RelationshipState.active,
        momentumDirection: MomentumDirection.stable,
      );

      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'P1',
        personBName: 'P2',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 50.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );

      final graph = NetworkGraph(nodes: [n1, n2, n3], connections: [conn]);
      expect(graph.isIsolated('p3_isolated'), isTrue);
      expect(graph.isIsolated('p1'), isFalse);
      expect(graph.isolatedPersonIds, equals(['p3_isolated']));
    });

    test('36. neighborIdsFor returns adjacent neighbors', () {
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final n3 = const NetworkGraphNode(personId: 'p3', personName: 'P3', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);

      final c1 = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'P1', personBName: 'P2', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);
      final c2 = NetworkConnection(personAId: 'p1', personBId: 'p3', personAName: 'P1', personBName: 'P3', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e2']);

      final graph = NetworkGraph(nodes: [n1, n2, n3], connections: [c1, c2]);
      expect(graph.neighborIdsFor('p1'), equals({'p2', 'p3'}));
      expect(graph.neighborIdsFor('p2'), equals({'p1'}));
    });

    test('37. connectionsFor returns all incident connections', () {
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final c1 = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'P1', personBName: 'P2', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);

      final graph = NetworkGraph(nodes: [n1, n2], connections: [c1]);
      expect(graph.connectionsFor('p1').length, equals(1));
      expect(graph.connectionsFor('p3'), isEmpty);
    });

    test('38. NetworkGraph.empty() produces safe empty object', () {
      final g = NetworkGraph.empty();
      expect(g.nodeCount, equals(0));
      expect(g.edgeCount, equals(0));
      expect(g.isEmpty, isTrue);
      expect(g.isNotEmpty, isFalse);
    });

    test('39. Node serialization preserves all properties', () {
      final node = const NetworkGraphNode(
        personId: 'p_ser',
        personName: 'Ser Person',
        company: 'Ser Corp',
        relationshipStrength: 88.5,
        relationshipState: RelationshipState.strong,
        momentumDirection: MomentumDirection.strengthening,
      );

      final map = node.toMap();
      final revived = NetworkGraphNode.fromMap(map);

      expect(revived.personId, equals('p_ser'));
      expect(revived.personName, equals('Ser Person'));
      expect(revived.company, equals('Ser Corp'));
      expect(revived.relationshipStrength, equals(88.5));
      expect(revived.relationshipState, equals(RelationshipState.strong));
      expect(revived.momentumDirection, equals(MomentumDirection.strengthening));
    });

    test('40. Graph serialization round-trip', () {
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'C1', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final c1 = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'P1', personBName: 'P2', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);
      final graph = NetworkGraph(nodes: [n1], connections: [c1]);

      final map = graph.toMap();
      final revived = NetworkGraph.fromMap(map);

      expect(revived.nodeCount, equals(1));
      expect(revived.edgeCount, equals(1));
    });

    test('41. Node equality based on personId', () {
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'A', company: '', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final n2 = const NetworkGraphNode(personId: 'p1', personName: 'B', company: '', relationshipStrength: 60, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable);
      expect(n1, equals(n2));
    });
  });

  group('Phase 13H-06 Group 5 — Network Math & Density Safety', () {
    test('42. Network density for N=0 returns 0.0', () {
      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: const []);

      expect(intel.networkDensity, equals(0.0));
      expect(intel.densityPercentageString, equals('0.0%'));
    });

    test('43. Network density for N=1 returns 0.0 without divide-by-zero error', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1]);

      expect(intel.networkDensity, equals(0.0));
      expect(intel.totalNodes, equals(1));
      expect(intel.totalConnections, equals(0));
    });

    test('44. Network density for N=2 with 1 edge returns 1.0 (100%)', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');

      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1, p2]);

      expect(intel.networkDensity, equals(1.0));
      expect(intel.densityPercentageString, equals('100.0%'));
    });

    test('45. Network density for N=3 with 1 edge returns 0.333', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Beta');

      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1, p2, p3]);

      // 3 nodes -> max edges = 3 * 2 / 2 = 3. Actual = 1. Density = 1/3 = 0.3333...
      expect(intel.networkDensity, closeTo(0.333, 0.01));
    });

    test('46. Cross-company connectivity calculates percentage of inter-company edges', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Beta');

      final act = ActivityItem(
        id: 'act1',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '',
        title: '',
        summary: '',
        personId: 'p1',
        targetRoute: '',
        actionLabel: '',
        metadata: {'relatedPersonIds': ['p3']},
      );

      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1, p2, p3], activities: [act]);

      // Total conns: p1-p2 (Acme-Acme), p1-p3 (Acme-Beta). Cross-company = 1 / 2 = 50.0%
      expect(intel.crossCompanyConnectivity, equals(50.0));
    });

    test('47. Concentration score calculates max company share', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Acme');
      final p4 = _buildProfile(id: 'p4', name: 'David', company: 'Beta');

      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1, p2, p3, p4]);

      // 3 of 4 in Acme = 75.0%
      expect(intel.concentrationScore, equals(75.0));
    });

    test('48. All mathematical properties are non-negative and bounded', () {
      final intel = NetworkConnectionIntelligence.empty();
      expect(intel.networkDensity >= 0.0 && intel.networkDensity <= 1.0, isTrue);
      expect(intel.crossCompanyConnectivity >= 0.0 && intel.crossCompanyConnectivity <= 100.0, isTrue);
      expect(intel.concentrationScore >= 0.0 && intel.concentrationScore <= 100.0, isTrue);
    });

    test('49. Connected vs isolated contact counts sum to totalNodes', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Beta');

      final intel = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      ).computeIntelligenceSync(profiles: [p1, p2, p3]);

      expect(intel.connectedPeople + intel.isolatedPeople, equals(intel.totalNodes));
      expect(intel.connectedPeople, equals(2));
      expect(intel.isolatedPeople, equals(1));
    });
  });

  group('Phase 13H-06 Group 6 — Pattern Detection & Precedence', () {
    const engine = DeterministicNetworkPatternEngine();

    test('50. Strong cluster pattern detected for established clusters with high strength', () {
      final cluster = RelationshipCluster(
        id: 'cluster_company_mega',
        name: 'MegaCorp',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2', 'p3'],
        averageRelationshipStrength: 85.0,
        averageAttentionScore: 10.0,
        interactionCount: 15,
        sharedContextCount: 1,
        clusterStrength: 88.0,
        description: 'Established cluster',
      );

      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'MegaCorp', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'MegaCorp', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n3 = const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'MegaCorp', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final graph = NetworkGraph(nodes: [n1, n2, n3], connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      expect(patterns.any((p) => p.type == NetworkPatternType.strongCluster), isTrue);
      final strong = patterns.firstWhere((p) => p.type == NetworkPatternType.strongCluster);
      expect(strong.title, contains('MegaCorp'));
      expect(strong.severity, equals(NetworkPatternSeverity.high));
    });

    test('51. Emerging cluster pattern detected for emerging cluster type', () {
      final cluster = RelationshipCluster(
        id: 'cluster_company_startup',
        name: 'Startup Inc',
        type: RelationshipClusterType.emerging,
        personIds: const ['p1', 'p2'],
        averageRelationshipStrength: 60.0,
        averageAttentionScore: 20.0,
        interactionCount: 4,
        sharedContextCount: 1,
        clusterStrength: 50.0,
        description: 'Emerging cluster',
      );
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'Startup Inc', relationshipStrength: 60, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'Startup Inc', relationshipStrength: 60, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable);
      final graph = NetworkGraph(nodes: [n1, n2], connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      expect(patterns.any((p) => p.type == NetworkPatternType.emergingCluster), isTrue);
      final emerging = patterns.firstWhere((p) => p.type == NetworkPatternType.emergingCluster);
      expect(emerging.severity, equals(NetworkPatternSeverity.info));
    });

    test('52. Cooling cluster pattern detected when >= 50% members are cooling', () {
      final cluster = RelationshipCluster(
        id: 'cluster_company_cool',
        name: 'Cooling Inc',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2'],
        averageRelationshipStrength: 40.0,
        averageAttentionScore: 70.0,
        interactionCount: 4,
        sharedContextCount: 1,
        clusterStrength: 40.0,
        description: 'Cooling cluster',
      );
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'Cooling Inc', relationshipStrength: 40, relationshipState: RelationshipState.cooling, momentumDirection: MomentumDirection.cooling);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'Cooling Inc', relationshipStrength: 40, relationshipState: RelationshipState.neglected, momentumDirection: MomentumDirection.declining);
      final graph = NetworkGraph(nodes: [n1, n2], connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      expect(patterns.any((p) => p.type == NetworkPatternType.coolingCluster), isTrue);
      final cooling = patterns.firstWhere((p) => p.type == NetworkPatternType.coolingCluster);
      expect(cooling.severity, equals(NetworkPatternSeverity.critical));
    });

    test('53. Company concentration pattern detected when >= 35% contacts in one company', () {
      final nodes = [
        const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'OmniCorp', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'OmniCorp', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'OmniCorp', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p4', personName: 'P4', company: 'OtherCorp', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
      ];
      final graph = NetworkGraph(nodes: nodes, connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: const []);
      expect(patterns.any((p) => p.type == NetworkPatternType.companyConcentration), isTrue);
      final conc = patterns.firstWhere((p) => p.type == NetworkPatternType.companyConcentration);
      expect(conc.description, contains('75.0%'));
    });

    test('54. Relationship bridge pattern detected when contact belongs to 2+ clusters', () {
      final c1 = RelationshipCluster(
        id: 'c1',
        name: 'Cluster A',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p_bridge'],
        averageRelationshipStrength: 60,
        averageAttentionScore: 10,
        interactionCount: 5,
        sharedContextCount: 1,
        clusterStrength: 60,
        description: '',
      );
      final c2 = RelationshipCluster(
        id: 'c2',
        name: 'Cluster B',
        type: RelationshipClusterType.project,
        personIds: const ['p2', 'p_bridge'],
        averageRelationshipStrength: 60,
        averageAttentionScore: 10,
        interactionCount: 5,
        sharedContextCount: 1,
        clusterStrength: 60,
        description: '',
      );

      final nodes = [
        const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'A', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'B', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p_bridge', personName: 'Bridge Bob', company: 'A', relationshipStrength: 75, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable),
      ];
      final graph = NetworkGraph(nodes: nodes, connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: [c1, c2]);
      expect(patterns.any((p) => p.type == NetworkPatternType.relationshipBridge), isTrue);
      final bridge = patterns.firstWhere((p) => p.type == NetworkPatternType.relationshipBridge);
      expect(bridge.title, contains('Bridge Bob'));
    });

    test('55. Isolated contacts pattern detected when contacts have 0 connections', () {
      final nodes = [
        const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'A', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'B', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'C', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
      ];
      final graph = NetworkGraph(nodes: nodes, connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: const []);
      expect(patterns.any((p) => p.type == NetworkPatternType.isolatedContact), isTrue);
      final iso = patterns.firstWhere((p) => p.type == NetworkPatternType.isolatedContact);
      expect(iso.evidencePersonIds.length, equals(3));
    });

    test('56. Network gap pattern detected when distinct clusters have 0 cross-connections', () {
      final c1 = RelationshipCluster(id: 'c1', name: 'Cluster A', type: RelationshipClusterType.company, personIds: const ['p1', 'p2'], averageRelationshipStrength: 50, averageAttentionScore: 10, interactionCount: 2, sharedContextCount: 1, clusterStrength: 50, description: '');
      final c2 = RelationshipCluster(id: 'c2', name: 'Cluster B', type: RelationshipClusterType.company, personIds: const ['p3', 'p4'], averageRelationshipStrength: 50, averageAttentionScore: 10, interactionCount: 2, sharedContextCount: 1, clusterStrength: 50, description: '');

      final nodes = [
        const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'A', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'A', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'B', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p4', personName: 'P4', company: 'B', relationshipStrength: 50, relationshipState: RelationshipState.active, momentumDirection: MomentumDirection.stable),
      ];
      final conn1 = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'P1', personBName: 'P2', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);
      final conn2 = NetworkConnection(personAId: 'p3', personBId: 'p4', personAName: 'P3', personBName: 'P4', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e2']);

      final graph = NetworkGraph(nodes: nodes, connections: [conn1, conn2]);

      final patterns = engine.detectPatterns(graph: graph, connections: [conn1, conn2], clusters: [c1, c2]);
      expect(patterns.any((p) => p.type == NetworkPatternType.networkGap), isTrue);
    });

    test('57. Balanced network pattern detected when network is interconnected and healthy', () {
      final c1 = RelationshipCluster(id: 'c1', name: 'Cluster A', type: RelationshipClusterType.company, personIds: const ['p1', 'p2'], averageRelationshipStrength: 70, averageAttentionScore: 10, interactionCount: 5, sharedContextCount: 1, clusterStrength: 70, description: '');
      final c2 = RelationshipCluster(id: 'c2', name: 'Cluster B', type: RelationshipClusterType.company, personIds: const ['p3', 'p4'], averageRelationshipStrength: 70, averageAttentionScore: 10, interactionCount: 5, sharedContextCount: 1, clusterStrength: 70, description: '');

      final nodes = [
        const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'A', relationshipStrength: 70, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'A', relationshipStrength: 70, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'B', relationshipStrength: 70, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable),
        const NetworkGraphNode(personId: 'p4', personName: 'P4', company: 'B', relationshipStrength: 70, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.stable),
      ];
      final c12 = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'P1', personBName: 'P2', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);
      final c34 = NetworkConnection(personAId: 'p3', personBId: 'p4', personAName: 'P3', personBName: 'P4', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e2']);
      final c23 = NetworkConnection(personAId: 'p2', personBId: 'p3', personAName: 'P2', personBName: 'P3', connectionType: NetworkConnectionType.sharedInteraction, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e3']);

      final graph = NetworkGraph(nodes: nodes, connections: [c12, c34, c23]);
      final patterns = engine.detectPatterns(graph: graph, connections: [c12, c34, c23], clusters: [c1, c2]);

      expect(patterns.any((p) => p.type == NetworkPatternType.balancedNetwork), isTrue);
    });

    test('58. Deterministic pattern ordering: severity DESC -> impactScore DESC -> id ASC', () {
      final p1 = NetworkPattern(id: 'p_crit', type: NetworkPatternType.coolingCluster, severity: NetworkPatternSeverity.critical, title: 'Crit', description: '', evidencePersonIds: const [], evidenceConnectionIds: const [], impactScore: 50, recommendedAction: '');
      final p2 = NetworkPattern(id: 'p_high_high_impact', type: NetworkPatternType.strongCluster, severity: NetworkPatternSeverity.high, title: 'High High', description: '', evidencePersonIds: const [], evidenceConnectionIds: const [], impactScore: 90, recommendedAction: '');
      final p3 = NetworkPattern(id: 'p_high_low_impact', type: NetworkPatternType.strongCluster, severity: NetworkPatternSeverity.high, title: 'High Low', description: '', evidencePersonIds: const [], evidenceConnectionIds: const [], impactScore: 40, recommendedAction: '');
      final p4 = NetworkPattern(id: 'p_info', type: NetworkPatternType.emergingCluster, severity: NetworkPatternSeverity.info, title: 'Info', description: '', evidencePersonIds: const [], evidenceConnectionIds: const [], impactScore: 20, recommendedAction: '');

      final list = [p4, p3, p1, p2]..sort();

      expect(list[0].id, equals('p_crit'));
      expect(list[1].id, equals('p_high_high_impact'));
      expect(list[2].id, equals('p_high_low_impact'));
      expect(list[3].id, equals('p_info'));
    });

    test('59. NetworkPatternSeverity ranking order and color tokens', () {
      expect(NetworkPatternSeverity.critical.rankOrder, equals(5));
      expect(NetworkPatternSeverity.high.rankOrder, equals(4));
      expect(NetworkPatternSeverity.medium.rankOrder, equals(3));
      expect(NetworkPatternSeverity.low.rankOrder, equals(2));
      expect(NetworkPatternSeverity.info.rankOrder, equals(1));
    });

    test('60. Every pattern provides non-empty recommended action', () {
      final cluster = RelationshipCluster(id: 'c1', name: 'Mega', type: RelationshipClusterType.company, personIds: const ['p1', 'p2', 'p3'], averageRelationshipStrength: 80, averageAttentionScore: 10, interactionCount: 10, sharedContextCount: 1, clusterStrength: 80, description: '');
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'Mega', relationshipStrength: 80, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'Mega', relationshipStrength: 80, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n3 = const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'Mega', relationshipStrength: 80, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final graph = NetworkGraph(nodes: [n1, n2, n3], connections: const []);

      final patterns = engine.detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      for (final p in patterns) {
        expect(p.recommendedAction.isNotEmpty, isTrue);
      }
    });

    test('61. Empty graph produces zero patterns', () {
      final patterns = engine.detectPatterns(graph: NetworkGraph.empty(), connections: const [], clusters: const []);
      expect(patterns, isEmpty);
    });
  });

  group('Phase 13H-06 Group 7 — Grounded Explanations & Privacy Verification', () {
    test('62. Descriptions contain zero subjective emotional adjectives', () {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Venture Corp',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2'],
        averageRelationshipStrength: 30,
        averageAttentionScore: 80,
        interactionCount: 2,
        sharedContextCount: 1,
        clusterStrength: 30,
        description: 'Cooling',
      );
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'Venture Corp', relationshipStrength: 30, relationshipState: RelationshipState.cooling, momentumDirection: MomentumDirection.cooling);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'Venture Corp', relationshipStrength: 30, relationshipState: RelationshipState.cooling, momentumDirection: MomentumDirection.cooling);
      final graph = NetworkGraph(nodes: [n1, n2], connections: const []);

      final patterns = const DeterministicNetworkPatternEngine().detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      for (final p in patterns) {
        final d = p.description.toLowerCase();
        expect(d.contains('feels'), isFalse);
        expect(d.contains('sad'), isFalse);
        expect(d.contains('lonely'), isFalse);
        expect(d.contains('worried'), isFalse);
      }
    });

    test('63. Exact integer quantities cited for contacts and interactions', () {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Nexus Labs',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2', 'p3'],
        averageRelationshipStrength: 85,
        averageAttentionScore: 10,
        interactionCount: 24,
        sharedContextCount: 1,
        clusterStrength: 85,
        description: 'Established',
      );
      final n1 = const NetworkGraphNode(personId: 'p1', personName: 'P1', company: 'Nexus Labs', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n2 = const NetworkGraphNode(personId: 'p2', personName: 'P2', company: 'Nexus Labs', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final n3 = const NetworkGraphNode(personId: 'p3', personName: 'P3', company: 'Nexus Labs', relationshipStrength: 85, relationshipState: RelationshipState.strong, momentumDirection: MomentumDirection.strengthening);
      final graph = NetworkGraph(nodes: [n1, n2, n3], connections: const []);

      final patterns = const DeterministicNetworkPatternEngine().detectPatterns(graph: graph, connections: const [], clusters: [cluster]);
      final strong = patterns.firstWhere((p) => p.type == NetworkPatternType.strongCluster);
      expect(strong.description, contains('3 strongly connected contacts'));
      expect(strong.description, contains('24 interactions'));
    });

    test('64. Serialization contains zero passwords or API keys', () {
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'A',
        personBName: 'B',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 50.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );
      final mapStr = conn.toMap().toString().toLowerCase();
      expect(mapStr.contains('apikey'), isFalse);
      expect(mapStr.contains('token'), isFalse);
      expect(mapStr.contains('secret'), isFalse);
    });

    test('65. Cluster serialization contains zero secret leaks', () {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Nexus',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2'],
        averageRelationshipStrength: 50,
        averageAttentionScore: 10,
        interactionCount: 5,
        sharedContextCount: 1,
        clusterStrength: 50,
        description: 'Nexus',
      );
      final mapStr = cluster.toMap().toString().toLowerCase();
      expect(mapStr.contains('apikey'), isFalse);
      expect(mapStr.contains('password'), isFalse);
    });

    test('66. Pattern serialization contains zero secret leaks', () {
      final pattern = NetworkPattern(
        id: 'p1',
        type: NetworkPatternType.strongCluster,
        severity: NetworkPatternSeverity.high,
        title: 'Title',
        description: 'Desc',
        evidencePersonIds: const ['p1'],
        evidenceConnectionIds: const ['e1'],
        impactScore: 50,
        recommendedAction: 'Action',
      );
      final mapStr = pattern.toMap().toString().toLowerCase();
      expect(mapStr.contains('apikey'), isFalse);
      expect(mapStr.contains('secret'), isFalse);
    });

    test('67. NetworkConnectionIntelligence serialization contains zero secret leaks', () {
      final intel = NetworkConnectionIntelligence.empty();
      final mapStr = intel.toMap().toString().toLowerCase();
      expect(mapStr.contains('apikey'), isFalse);
      expect(mapStr.contains('bearertoken'), isFalse);
    });

    test('68. Evidence person IDs are deterministically sorted on construction', () {
      final pattern = NetworkPattern(
        id: 'p1',
        type: NetworkPatternType.isolatedContact,
        severity: NetworkPatternSeverity.info,
        title: 'Title',
        description: 'Desc',
        evidencePersonIds: ['z_person', 'a_person'],
        evidenceConnectionIds: ['conn_z', 'conn_a'],
        impactScore: 50,
        recommendedAction: 'Action',
      );

      expect(pattern.evidencePersonIds, equals(['a_person', 'z_person']));
      expect(pattern.evidenceConnectionIds, equals(['conn_a', 'conn_z']));
    });

    test('69. Cluster person IDs are deterministically sorted on construction', () {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Nexus',
        type: RelationshipClusterType.company,
        personIds: ['z_person', 'b_person', 'a_person'],
        averageRelationshipStrength: 50,
        averageAttentionScore: 10,
        interactionCount: 5,
        sharedContextCount: 1,
        clusterStrength: 50,
        description: 'Nexus',
      );

      expect(cluster.personIds, equals(['a_person', 'b_person', 'z_person']));
    });
  });

  group('Phase 13H-06 Group 8 — Multi-Tenant Security & Serialization', () {
    test('70. NetworkConnection round-trip serialization', () {
      final original = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice',
        personBName: 'Bob',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 75.5,
        evidenceCount: 2,
        evidenceIds: const ['ev1', 'ev2'],
        sharedCompany: 'Acme',
        sharedContext: 'Project 1',
        generatedAt: refDate,
      );

      final map = original.toMap();
      final revived = NetworkConnection.fromMap(map);

      expect(revived.personAId, equals(original.personAId));
      expect(revived.personBId, equals(original.personBId));
      expect(revived.personAName, equals(original.personAName));
      expect(revived.personBName, equals(original.personBName));
      expect(revived.connectionType, equals(original.connectionType));
      expect(revived.connectionScore, equals(original.connectionScore));
      expect(revived.evidenceCount, equals(original.evidenceCount));
      expect(revived.evidenceIds, equals(original.evidenceIds));
      expect(revived.sharedCompany, equals(original.sharedCompany));
      expect(revived.sharedContext, equals(original.sharedContext));
    });

    test('71. RelationshipCluster round-trip serialization', () {
      final original = RelationshipCluster(
        id: 'cluster_company_acme',
        name: 'Acme',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2', 'p3'],
        averageRelationshipStrength: 82.5,
        averageAttentionScore: 15.0,
        interactionCount: 18,
        sharedContextCount: 2,
        clusterStrength: 85.0,
        description: 'Established cluster',
        generatedAt: refDate,
      );

      final map = original.toMap();
      final revived = RelationshipCluster.fromMap(map);

      expect(revived.id, equals(original.id));
      expect(revived.name, equals(original.name));
      expect(revived.type, equals(original.type));
      expect(revived.personIds, equals(original.personIds));
      expect(revived.averageRelationshipStrength, equals(original.averageRelationshipStrength));
      expect(revived.averageAttentionScore, equals(original.averageAttentionScore));
      expect(revived.interactionCount, equals(original.interactionCount));
      expect(revived.sharedContextCount, equals(original.sharedContextCount));
      expect(revived.clusterStrength, equals(original.clusterStrength));
      expect(revived.description, equals(original.description));
    });

    test('72. NetworkPattern round-trip serialization', () {
      final original = NetworkPattern(
        id: 'pattern_1',
        type: NetworkPatternType.companyConcentration,
        severity: NetworkPatternSeverity.high,
        title: 'High Concentration',
        description: '75% in Acme',
        evidencePersonIds: const ['p1', 'p2'],
        evidenceConnectionIds: const ['e1'],
        impactScore: 68.5,
        recommendedAction: 'Diversify network',
        generatedAt: refDate,
      );

      final map = original.toMap();
      final revived = NetworkPattern.fromMap(map);

      expect(revived.id, equals(original.id));
      expect(revived.type, equals(original.type));
      expect(revived.severity, equals(original.severity));
      expect(revived.title, equals(original.title));
      expect(revived.description, equals(original.description));
      expect(revived.evidencePersonIds, equals(original.evidencePersonIds));
      expect(revived.impactScore, equals(original.impactScore));
      expect(revived.recommendedAction, equals(original.recommendedAction));
    });

    test('73. NetworkConnectionIntelligence round-trip serialization', () {
      final conn = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'A', personBName: 'B', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1'], generatedAt: refDate);
      final cluster = RelationshipCluster(id: 'c1', name: 'Nexus', type: RelationshipClusterType.company, personIds: const ['p1', 'p2'], averageRelationshipStrength: 50, averageAttentionScore: 10, interactionCount: 5, sharedContextCount: 1, clusterStrength: 50, description: 'Nexus', generatedAt: refDate);
      final pattern = NetworkPattern(id: 'p1', type: NetworkPatternType.strongCluster, severity: NetworkPatternSeverity.high, title: 'T', description: 'D', evidencePersonIds: const ['p1'], evidenceConnectionIds: const ['e1'], impactScore: 50, recommendedAction: 'A', generatedAt: refDate);

      final original = NetworkConnectionIntelligence(
        graph: NetworkGraph(nodes: const [], connections: [conn]),
        connections: [conn],
        clusters: [cluster],
        patterns: [pattern],
        totalNodes: 2,
        totalConnections: 1,
        connectedPeople: 2,
        isolatedPeople: 0,
        clusterCount: 1,
        strongestConnection: conn,
        strongestCluster: cluster,
        bridgeContacts: const ['p1'],
        networkDensity: 1.0,
        crossCompanyConnectivity: 0.0,
        concentrationScore: 100.0,
        generatedAt: refDate,
      );

      final map = original.toMap();
      final revived = NetworkConnectionIntelligence.fromMap(map);

      expect(revived.totalNodes, equals(2));
      expect(revived.totalConnections, equals(1));
      expect(revived.clusterCount, equals(1));
      expect(revived.networkDensity, equals(1.0));
      expect(revived.bridgeContacts, equals(['p1']));
      expect(revived.strongestConnection?.edgeId, equals(conn.edgeId));
      expect(revived.strongestCluster?.id, equals(cluster.id));
    });

    test('74. Empty intelligence round-trip serialization', () {
      final original = NetworkConnectionIntelligence.empty();
      final map = original.toMap();
      final revived = NetworkConnectionIntelligence.fromMap(map);

      expect(revived.totalNodes, equals(0));
      expect(revived.totalConnections, equals(0));
      expect(revived.connections, isEmpty);
      expect(revived.clusters, isEmpty);
      expect(revived.patterns, isEmpty);
    });

    test('75. Multi-tenant isolation: User A dataset does not produce connections for User B', () {
      final userAProfiles = [
        _buildProfile(id: 'usrA_p1', name: 'Alice A', company: 'Company A'),
        _buildProfile(id: 'usrA_p2', name: 'Bob A', company: 'Company A'),
      ];
      final userBProfiles = [
        _buildProfile(id: 'usrB_p1', name: 'Alice B', company: 'Company B'),
        _buildProfile(id: 'usrB_p2', name: 'Bob B', company: 'Company B'),
      ];

      const calc = DeterministicNetworkConnectionCalculator();
      final connsA = calc.calculateConnections(profiles: userAProfiles);
      final connsB = calc.calculateConnections(profiles: userBProfiles);

      expect(connsA.every((c) => c.personAId.startsWith('usrA_')), isTrue);
      expect(connsB.every((c) => c.personAId.startsWith('usrB_')), isTrue);
    });

    test('76. Cross-tenant pair comparison produces independent isolated graphs', () {
      final userAProfiles = [_buildProfile(id: 'usrA_p1', name: 'Alice', company: 'Alpha')];
      final userBProfiles = [_buildProfile(id: 'usrB_p1', name: 'Bob', company: 'Beta')];

      const calc = DeterministicNetworkConnectionCalculator();
      final connsA = calc.calculateConnections(profiles: userAProfiles);
      final connsB = calc.calculateConnections(profiles: userBProfiles);

      expect(connsA, isEmpty);
      expect(connsB, isEmpty);
    });

    test('77. JSON factory methods handle Map and json decoding', () {
      final conn = NetworkConnection(personAId: 'p1', personBId: 'p2', personAName: 'A', personBName: 'B', connectionType: NetworkConnectionType.sharedCompany, connectionScore: 50, evidenceCount: 1, evidenceIds: const ['e1']);
      final json = conn.toJson();
      final revived = NetworkConnection.fromJson(json);
      expect(revived.edgeId, equals(conn.edgeId));
    });
  });

  group('Phase 13H-06 Group 9 — UI Widgets & Screen Integration', () {
    testWidgets('78. NetworkConnectionsSummary renders metrics, density, clusters, and isolated contacts', (tester) async {
      final intel = NetworkConnectionIntelligence(
        graph: NetworkGraph.empty(),
        connections: const [],
        clusters: const [],
        patterns: const [],
        totalNodes: 5,
        totalConnections: 3,
        connectedPeople: 4,
        isolatedPeople: 1,
        clusterCount: 1,
        networkDensity: 0.3,
        crossCompanyConnectivity: 33.3,
        concentrationScore: 60.0,
        bridgeContacts: const [],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NetworkConnectionsSummary(intelligence: intel),
        ),
      ));

      expect(find.text('NETWORK GRAPH & CONNECTIONS'), findsOneWidget);
      expect(find.text('TOTAL CONNECTIONS'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('NETWORK DENSITY'), findsOneWidget);
      expect(find.text('30.0%'), findsOneWidget);
      expect(find.text('RELATIONSHIP CLUSTERS'), findsOneWidget);
      expect(find.text('ISOLATED CONTACTS'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('79. NetworkClustersSection renders cluster cards with members and strength', (tester) async {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Vertex Ventures',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2', 'p3'],
        averageRelationshipStrength: 80.0,
        averageAttentionScore: 15.0,
        interactionCount: 12,
        sharedContextCount: 1,
        clusterStrength: 82.0,
        description: 'Organizational cluster across Vertex Ventures with 3 contacts.',
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NetworkClustersSection(clusters: [cluster]),
        ),
      ));

      expect(find.text('RELATIONSHIP CLUSTERS (1)'), findsOneWidget);
      expect(find.text('Vertex Ventures'), findsOneWidget);
      expect(find.text('3 members • 12 total interactions'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('STRENGTH'), findsOneWidget);
    });

    testWidgets('80. NetworkPatternsSection renders pattern cards with severity chips and recommendations', (tester) async {
      final pattern = NetworkPattern(
        id: 'p1',
        type: NetworkPatternType.companyConcentration,
        severity: NetworkPatternSeverity.high,
        title: 'Company Concentration: Apex Corp',
        description: '60.0% of your network is concentrated in Apex Corp.',
        evidencePersonIds: const ['p1', 'p2', 'p3'],
        evidenceConnectionIds: const [],
        impactScore: 75.0,
        recommendedAction: 'Diversify relationships across other key industry partners.',
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NetworkPatternsSection(patterns: [pattern]),
        ),
      ));

      expect(find.text('DETECTED PATTERNS (1)'), findsOneWidget);
      expect(find.text('Company Concentration: Apex Corp'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('60.0% of your network is concentrated in Apex Corp.'), findsOneWidget);
      expect(find.text('Diversify relationships across other key industry partners.'), findsOneWidget);
    });

    testWidgets('81. NetworkDashboardScreen renders connections, clusters, and patterns with initialData', (tester) async {
      final sampleHealth = NetworkHealth(
        score: 80.0,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.high,
        totalPeople: 4,
        activeRelationships: 3,
        strongRelationships: 2,
        coolingRelationships: 1,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 1,
        overdueFollowUps: 0,
        interactionCount: 10,
        recentInteractionCount: 5,
        followUpCompletionRate: 0.9,
        relationshipCoverage: 0.9,
        generatedAt: refDate,
      );

      final sampleIntel = NetworkIntelligence(
        health: sampleHealth,
        trends: const [],
        insights: const [],
        topAttention: const [],
        generatedAt: refDate,
      );

      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Nexus Corp',
        type: RelationshipClusterType.company,
        personIds: const ['p1', 'p2'],
        averageRelationshipStrength: 75.0,
        averageAttentionScore: 10.0,
        interactionCount: 8,
        sharedContextCount: 1,
        clusterStrength: 78.0,
        description: 'Cluster across Nexus Corp',
        generatedAt: refDate,
      );

      final pattern = NetworkPattern(
        id: 'p1',
        type: NetworkPatternType.strongCluster,
        severity: NetworkPatternSeverity.high,
        title: 'Strong Cluster: Nexus Corp',
        description: 'Strong connections developing.',
        evidencePersonIds: const ['p1', 'p2'],
        evidenceConnectionIds: const [],
        impactScore: 80.0,
        recommendedAction: 'Engage proactively.',
        generatedAt: refDate,
      );

      final sampleConnIntel = NetworkConnectionIntelligence(
        graph: NetworkGraph.empty(),
        connections: const [],
        clusters: [cluster],
        patterns: [pattern],
        totalNodes: 4,
        totalConnections: 2,
        connectedPeople: 3,
        isolatedPeople: 1,
        clusterCount: 1,
        networkDensity: 0.33,
        crossCompanyConnectivity: 50.0,
        concentrationScore: 50.0,
        bridgeContacts: const [],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: NetworkDashboardScreen(
          initialData: sampleIntel,
          initialConnectionData: sampleConnIntel,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Network Intelligence'), findsOneWidget);
      expect(find.text('NETWORK GRAPH & CONNECTIONS'), findsOneWidget);
      expect(find.text('RELATIONSHIP CLUSTERS (1)'), findsOneWidget);
      expect(find.text('Nexus Corp'), findsOneWidget);
      expect(find.text('DETECTED PATTERNS (1)'), findsOneWidget);
    });

    testWidgets('82. NetworkDashboardScreen filter pills toggle active filter state', (tester) async {
      final sampleHealth = NetworkHealth(
        score: 80.0,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.high,
        totalPeople: 4,
        activeRelationships: 3,
        strongRelationships: 2,
        coolingRelationships: 1,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 1,
        overdueFollowUps: 0,
        interactionCount: 10,
        recentInteractionCount: 5,
        followUpCompletionRate: 0.9,
        relationshipCoverage: 0.9,
        generatedAt: refDate,
      );

      final sampleIntel = NetworkIntelligence(
        health: sampleHealth,
        trends: const [],
        insights: const [],
        topAttention: const [],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: NetworkDashboardScreen(initialData: sampleIntel),
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Clusters'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Cooling'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Bridges'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Clusters'));
      await tester.pumpAndSettle();
    });

    testWidgets('83. Person Dossier RelationshipIntelligence renders Connected Through section', (tester) async {
      final profile = _buildProfile(id: 'p1', name: 'Alice Connor', company: 'Cyberdyne');
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice Connor',
        personBName: 'Bob Reese',
        connectionType: NetworkConnectionType.sharedCompany,
        connectionScore: 70.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
        sharedCompany: 'Cyberdyne',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: pds_ri.RelationshipIntelligence(
              profile: profile,
              connections: [conn],
            ),
          ),
        ),
      ));

      expect(find.text('CONNECTED THROUGH'), findsOneWidget);
      expect(find.text('Shared Company'), findsOneWidget);
      expect(find.text('with Bob Reese (Cyberdyne)'), findsOneWidget);
      expect(find.text('70/100'), findsOneWidget);
    });

    testWidgets('84. Person Dossier renders NETWORK BRIDGE badge when isBridge is true', (tester) async {
      final profile = _buildProfile(id: 'p1', name: 'Alice Connor', company: 'Cyberdyne');
      final conn = NetworkConnection(
        personAId: 'p1',
        personBId: 'p2',
        personAName: 'Alice Connor',
        personBName: 'Bob Reese',
        connectionType: NetworkConnectionType.sharedInteraction,
        connectionScore: 65.0,
        evidenceCount: 1,
        evidenceIds: const ['ev1'],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: pds_ri.RelationshipIntelligence(
              profile: profile,
              connections: [conn],
              isBridge: true,
              bridgeExplanation: 'Connects Cyberdyne and Resistance clusters.',
            ),
          ),
        ),
      ));

      expect(find.text('NETWORK BRIDGE'), findsOneWidget);
      expect(find.text('Connects Cyberdyne and Resistance clusters.'), findsOneWidget);
    });

    testWidgets('85. Person Dossier renders truthful empty connection message when isolated', (tester) async {
      final profile = _buildProfile(id: 'p_iso', name: 'Isolated Contact', company: 'Solo');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: pds_ri.RelationshipIntelligence(
              profile: profile,
              connections: const [],
            ),
          ),
        ),
      ));

      expect(find.text('CONNECTED THROUGH'), findsOneWidget);
      expect(find.text('No recorded network connections yet.'), findsOneWidget);
    });

    testWidgets('86. Responsive layout renders across 360dp, 768dp, 1024dp viewports without overflow', (tester) async {
      final sampleHealth = NetworkHealth(
        score: 80.0,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.high,
        totalPeople: 4,
        activeRelationships: 3,
        strongRelationships: 2,
        coolingRelationships: 1,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 1,
        overdueFollowUps: 0,
        interactionCount: 10,
        recentInteractionCount: 5,
        followUpCompletionRate: 0.9,
        relationshipCoverage: 0.9,
        generatedAt: refDate,
      );

      final sampleIntel = NetworkIntelligence(
        health: sampleHealth,
        trends: const [],
        insights: const [],
        topAttention: const [],
        generatedAt: refDate,
      );

      final viewports = [
        const Size(360, 800),
        const Size(768, 1024),
        const Size(1024, 768),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(MaterialApp(
          home: NetworkDashboardScreen(initialData: sampleIntel),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('87. NetworkClustersSection and NetworkPatternsSection handle empty lists gracefully', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NetworkClustersSection(clusters: []),
              NetworkPatternsSection(patterns: []),
            ],
          ),
        ),
      ));

      expect(find.text('RELATIONSHIP CLUSTERS'), findsNothing);
      expect(find.text('DETECTED PATTERNS'), findsNothing);
    });
  });

  group('Phase 13H-06 Group 10 — Composition, DI Wiring & Golden Journey', () {
    test('88. DI Container RecallrDependencies provides non-null connection calculators and service', () {
      final deps = RecallrDependencies.mock();
      expect(deps.networkConnectionCalculator, isNotNull);
      expect(deps.networkClusterDetector, isNotNull);
      expect(deps.networkPatternEngine, isNotNull);
      expect(deps.networkConnectionIntelligenceService, isNotNull);
    });

    test('89. Production DI Container resolves connection service', () {
      final deps = RecallrDependencies.production();
      expect(deps.networkConnectionIntelligenceService, isNotNull);
    });

    test('90. Direct async getNetworkConnectionIntelligence matches computeIntelligenceSync output', () async {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');

      final service = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([
          PersonItem(id: 'p1', name: 'Alice', role: '', company: 'Acme', initials: 'A'),
          PersonItem(id: 'p2', name: 'Bob', role: '', company: 'Acme', initials: 'B'),
        ]),
        personDetailRepository: _MockPersonDetailRepo({'p1': p1, 'p2': p2}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      );

      final asyncIntel = await service.getNetworkConnectionIntelligence(referenceDate: refDate);
      final syncIntel = service.computeIntelligenceSync(profiles: [p1, p2], referenceDate: refDate);

      expect(asyncIntel.totalConnections, equals(syncIntel.totalConnections));
      expect(asyncIntel.networkDensity, equals(syncIntel.networkDensity));
      expect(asyncIntel.clusterCount, equals(syncIntel.clusterCount));
    });

    test('91. Stream method emits valid intelligence snapshot', () async {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Acme');

      final service = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([
          PersonItem(id: 'p1', name: 'Alice', role: '', company: 'Acme', initials: 'A'),
          PersonItem(id: 'p2', name: 'Bob', role: '', company: 'Acme', initials: 'B'),
        ]),
        personDetailRepository: _MockPersonDetailRepo({'p1': p1, 'p2': p2}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      );

      final emission = await service.streamNetworkConnectionIntelligence(referenceDate: refDate).first;
      expect(emission.totalNodes, equals(2));
      expect(emission.totalConnections, equals(1));
    });

    test('92. Golden User Journey: Multi-company network with 6 contacts evaluates complete graph', () {
      final p1 = _buildProfile(id: 'p1', name: 'Alice', company: 'Alpha Corp', totalInteractions: 6, relationshipStrength: 'Strong');
      final p2 = _buildProfile(id: 'p2', name: 'Bob', company: 'Alpha Corp', totalInteractions: 5, relationshipStrength: 'Strong');
      final p3 = _buildProfile(id: 'p3', name: 'Charlie', company: 'Alpha Corp', totalInteractions: 4, relationshipStrength: 'Strong');
      final p4 = _buildProfile(id: 'p4', name: 'David', company: 'Beta Labs', totalInteractions: 4, relationshipStrength: 'Active');
      final p5 = _buildProfile(id: 'p5', name: 'Eve', company: 'Beta Labs', totalInteractions: 3, relationshipStrength: 'Active');
      final p6 = _buildProfile(id: 'p6_bridge', name: 'Frank Bridge', company: 'Alpha Corp', totalInteractions: 5, relationshipStrength: 'Strong');

      final crossAct = ActivityItem(
        id: 'act_cross',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '',
        title: 'Joint Workshop',
        summary: 'Alpha meets Beta',
        personId: 'p6_bridge',
        targetRoute: '',
        actionLabel: '',
        metadata: {'relatedPersonIds': ['p4']},
      );

      final service = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      );

      final intel = service.computeIntelligenceSync(
        profiles: [p1, p2, p3, p4, p5, p6],
        activities: [crossAct],
        referenceDate: refDate,
      );

      expect(intel.totalNodes, equals(6));
      expect(intel.clusterCount, greaterThanOrEqualTo(2));
      expect(intel.clusters.any((c) => c.name.toLowerCase().contains('alpha')), isTrue);
      expect(intel.clusters.any((c) => c.name.toLowerCase().contains('beta')), isTrue);
      expect(intel.patterns.isNotEmpty, isTrue);
      expect(intel.networkDensity, greaterThan(0.0));
      expect(intel.networkDensity, lessThanOrEqualTo(1.0));
    });

    test('93. Edge cases: Single person, all isolated, single company networks evaluate safely', () {
      final service = DeterministicNetworkConnectionIntelligenceService(
        peopleRepository: _MockPeopleRepo([]),
        personDetailRepository: _MockPersonDetailRepo({}),
        activityRepository: _MockActivityRepo([]),
        captureRepository: _MockCaptureRepo([]),
      );

      final solo = service.computeIntelligenceSync(
        profiles: [_buildProfile(id: 'solo', name: 'Solo', company: 'One')],
        referenceDate: refDate,
      );
      expect(solo.totalNodes, equals(1));
      expect(solo.totalConnections, equals(0));
      expect(solo.clusterCount, equals(0));

      final isolated = service.computeIntelligenceSync(
        profiles: [
          _buildProfile(id: 'iso1', name: 'I1', company: 'C1'),
          _buildProfile(id: 'iso2', name: 'I2', company: 'C2'),
          _buildProfile(id: 'iso3', name: 'I3', company: 'C3'),
        ],
        referenceDate: refDate,
      );
      expect(isolated.totalNodes, equals(3));
      expect(isolated.totalConnections, equals(0));
      expect(isolated.isolatedPeople, equals(3));
    });

    test('94. Complete composition verification: 13H-01 through 13H-06 compose harmoniously', () {
      final deps = RecallrDependencies.mock();
      expect(deps.relationshipStrengthCalculator, isNotNull);
      expect(deps.relationshipActionEngine, isNotNull);
      expect(deps.relationshipAttentionEngine, isNotNull);
      expect(deps.networkIntelligenceService, isNotNull);
      expect(deps.relationshipMomentumService, isNotNull);
      expect(deps.networkConnectionIntelligenceService, isNotNull);
    });
  });
}

// Minimal test mocks
class _MockPeopleRepo implements PeopleRepository {
  final List<PersonItem> items;
  _MockPeopleRepo(this.items);

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) => Stream.value(items);
  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) => Stream.value(items.take(limit).toList());
  @override
  Future<PersonItem?> getPerson(String id) async => items.cast<PersonItem?>().firstWhere((p) => p?.id == id, orElse: () => null);
  @override
  Future<void> addPerson(PersonItem person) async {}
  @override
  Future<void> updatePerson(PersonItem person) async {}
  @override
  Future<void> deletePerson(String id) async {}
  @override
  Future<PersonItem?> findPersonByEmail(String normalizedEmail) async => null;
  @override
  Future<PersonItem?> findPersonByPhone(String normalizedPhone) async => null;
  @override
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async => [];
  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(String normalizedName, String normalizedCompany) async => [];
  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async => person;
  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async => items.firstWhere((p) => p.id == personId);
}

class _MockPersonDetailRepo implements PersonDetailRepository {
  final Map<String, PersonProfile> profiles;
  _MockPersonDetailRepo(this.profiles);

  @override
  Future<PersonProfile?> getProfile(String personId) async => profiles[personId];
  @override
  Stream<PersonProfile?> streamProfile(String personId) => Stream.value(profiles[personId]);
  @override
  Future<List<PersonProfile>> getAllProfiles() async => profiles.values.toList();
  @override
  Future<void> saveProfile(PersonProfile profile) async {}
  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {}
  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {}
  @override
  Future<PersonProfile> enrichRelationshipMemory({required String personId, required RelationshipMemoryUpdate update}) async => profiles[personId]!;
  @override
  Future<void> updateRelationshipStats(String personId, {int? totalInteractions, String? lastInteraction, String? relationshipStrength, int? sharedEventsCount}) async {}
}

class _MockActivityRepo implements ActivityRepository {
  final List<ActivityItem> activities;
  _MockActivityRepo(this.activities);

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) => Stream.value(activities);
  @override
  Future<void> addActivity(ActivityItem activity) async {}
  @override
  Future<ActivityItem?> getActivity(String id) async => activities.cast<ActivityItem?>().firstWhere((a) => a?.id == id, orElse: () => null);
  @override
  Future<void> deleteActivity(String id) async {}
}

class _MockCaptureRepo implements CaptureRepository {
  final List<CaptureItem> captures;
  _MockCaptureRepo(this.captures);

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) => Stream.value(captures.take(limit).toList());
  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async => item;
  @override
  Future<CaptureItem?> getCapture(String id) async => captures.cast<CaptureItem?>().firstWhere((c) => c?.id == id, orElse: () => null);
  @override
  Future<void> deleteCapture(String id) async {}
}
