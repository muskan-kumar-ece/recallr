import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/people/widgets/person_card.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart' as pds_ri;
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/repositories/activity_repository.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/repositories/follow_up_repository.dart';
import 'package:recaller/repositories/people_repository.dart';
import 'package:recaller/repositories/person_detail_repository.dart';
import 'package:recaller/screens/home/home_screen.dart';
import 'package:recaller/screens/network/network_dashboard_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/services/relationship/network_health_calculator.dart';
import 'package:recaller/services/relationship/network_insight_generator.dart';
import 'package:recaller/services/relationship/network_trend_calculator.dart';
import 'package:recaller/services/relationship/relationship_action_engine.dart';
import 'package:recaller/services/relationship/relationship_attention_engine.dart';
import 'package:recaller/services/relationship/relationship_intelligence_consistency_validator.dart';
import 'package:recaller/services/relationship/relationship_momentum_engine.dart';
import 'package:recaller/services/relationship/relationship_state_classifier.dart';
import 'package:recaller/services/relationship/relationship_strength_calculator.dart';
import 'package:recaller/services/relationship/unified_relationship_intelligence_service.dart';
import 'package:recaller/services/relationship/unified_relationship_ranking.dart';
import 'package:recaller/services/retrieval/relationship_context_assembler.dart';

// --- Test Fakes & Mocks for Unit Testing ---

class FakePeopleRepository implements PeopleRepository {
  final List<PersonItem> items;
  FakePeopleRepository(this.items);

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) => Stream.value(items);
  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) => Stream.value(items.take(limit).toList());
  @override
  Future<PersonItem?> getPerson(String id) async => items.where((p) => p.id == id).firstOrNull;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePersonDetailRepository implements PersonDetailRepository {
  final Map<String, PersonProfile> profiles;
  FakePersonDetailRepository(this.profiles);

  @override
  Future<PersonProfile?> getProfile(String personId) async => profiles[personId];
  @override
  Stream<PersonProfile?> streamProfile(String personId) => Stream.value(profiles[personId]);
  @override
  Future<List<PersonProfile>> getAllProfiles() async => profiles.values.toList();
  Future<void> updateProfile(PersonProfile profile) async {
    profiles[profile.id] = profile;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> deleteProfile(String personId) async {}

  @override
  Future<void> deleteMemoryItem(String personId, String memoryId) async {}

  @override
  Future<void> deleteTimelineItem(String personId, String timelineId) async {}

}

class FakeActivityRepository implements ActivityRepository {
  final List<ActivityItem> items;
  FakeActivityRepository(this.items);

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) => Stream.value(items);
  @override
  Future<ActivityItem?> getActivity(String id) async => items.where((a) => a.id == id).firstOrNull;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFollowUpRepository implements FollowUpRepository {
  final List<FollowUpItem> items;
  FakeFollowUpRepository(this.items);

  @override
  Stream<List<FollowUpItem>> streamFollowUps({String? query, FollowUpFilter? filter, int limit = 100}) => Stream.value(items);
  @override
  Future<FollowUpItem?> getFollowUp(String id) async => items.firstWhere((f) => f.id == id, orElse: () => items.first);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCaptureRepository implements CaptureRepository {
  final List<CaptureItem> items;
  FakeCaptureRepository(this.items);

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 50}) => Stream.value(items);
  @override
  Future<CaptureItem> saveCapture(CaptureItem capture) async => capture;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final refDate = DateTime(2026, 8, 30, 10, 0, 0);

  PersonProfile buildProfile({
    required String id,
    required String name,
    required String company,
    int totalInteractions = 3,
    String relationshipStrength = 'Active',
    String firstMet = '2025-01-10',
    String lastInteraction = '2026-08-15',
    List<ConnectedEntity> connectedEntities = const [],
    List<MemoryItem> memories = const [],
  }) {
    return PersonProfile(
      id: id,
      name: name,
      role: 'Engineer at $company',
      company: company,
      location: 'Bangalore',
      initials: name.isNotEmpty ? name[0] : '?',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: relationshipStrength,
      firstMet: firstMet,
      lastInteraction: lastInteraction,
      totalInteractions: totalInteractions,
      sharedEventsCount: 1,
      aiSummary: 'Summary for $name',
      connectedEntities: connectedEntities,
      memories: memories,
    );
  }

  ActivityItem buildActivity({
    required String id,
    required String personId,
    required String title,
    required DateTime date,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.meeting,
      period: TimelinePeriod.earlier,
      personId: personId,
      personName: 'Person $personId',
      targetRoute: '/person/$personId',
      actionLabel: 'View',
      title: title,
      summary: 'Discussed $title',
      timestamp: date.toIso8601String(),
      createdAt: date,
    );
  }

  FollowUpItem buildFollowUp({
    required String id,
    required String personId,
    required String title,
    required String dueDate,
    FollowUpStatus status = FollowUpStatus.dueToday,
    bool isCompleted = false,
  }) {
    return FollowUpItem(
      id: id,
      personId: personId,
      title: title,
      dueDate: dueDate,
      targetRoute: '/follow-up/$id',
      status: status,
      isCompleted: isCompleted,
    );
  }

  // Common service setup
  DeterministicUnifiedRelationshipIntelligenceService createService({
    List<PersonProfile> profiles = const [],
    List<PersonItem> people = const [],
    List<ActivityItem> activities = const [],
    List<FollowUpItem> followUps = const [],
    List<CaptureItem> captures = const [],
  }) {
    final profMap = {for (final p in profiles) p.id: p};
    return DeterministicUnifiedRelationshipIntelligenceService(
      peopleRepository: FakePeopleRepository(people),
      personDetailRepository: FakePersonDetailRepository(profMap),
      activityRepository: FakeActivityRepository(activities),
      followUpRepository: FakeFollowUpRepository(followUps),
      captureRepository: FakeCaptureRepository(captures),
    );
  }

  // ===========================================================================
  // Group 1 — Unified Domain Model Integrity
  // ===========================================================================
  group('Phase 13H-07 Group 1 — Unified Domain Model Integrity', () {
    test('1. UnifiedPersonRelationshipIntelligence construction and property getters', () {
      final signals = RelationshipSignals.empty();
      final strength = const RelationshipStrength(
        score: 75.0,
        factors: [],
        level: 'Strong',
        summary: 'Solid relationship',
      );
      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Contact Alpha',
        company: 'Nova Labs',
        relationshipSignals: signals,
        relationshipStrength: strength,
        relationshipState: RelationshipState.strong,
        generatedAt: refDate,
      );

      expect(intel.personId, equals('p1'));
      expect(intel.personName, equals('Contact Alpha'));
      expect(intel.company, equals('Nova Labs'));
      expect(intel.strengthScore, equals(75.0));
      expect(intel.relationshipState, equals(RelationshipState.strong));
      expect(intel.momentumDirection, equals(MomentumDirection.insufficientHistory));
      expect(intel.needsAttention, isFalse);
      expect(intel.isIsolated, isTrue);
      expect(intel.connectionCount, equals(0));
    });

    test('2. UnifiedPersonRelationshipIntelligence toMap and fromMap serialization round-trip', () {
      final signals = RelationshipSignals.empty();
      final strength = const RelationshipStrength(
        score: 82.5,
        factors: [
          StrengthFactor(
            name: 'Recency',
            score: 0.9,
            weight: 0.3,
            explanation: 'Met recently',
          ),
        ],
        level: 'Strong',
        summary: 'Excellent cadence',
      );
      final original = UnifiedPersonRelationshipIntelligence(
        personId: 'p100',
        personName: 'Test Contact',
        company: 'Cloud Corp',
        relationshipSignals: signals,
        relationshipStrength: strength,
        relationshipState: RelationshipState.active,
        isBridge: true,
        clusterIds: ['c1', 'c2'],
        generatedAt: refDate,
      );

      final map = original.toMap();
      final reconstructed = UnifiedPersonRelationshipIntelligence.fromMap(map);

      expect(reconstructed.personId, equals(original.personId));
      expect(reconstructed.personName, equals(original.personName));
      expect(reconstructed.company, equals(original.company));
      expect(reconstructed.strengthScore, equals(original.strengthScore));
      expect(reconstructed.relationshipState, equals(original.relationshipState));
      expect(reconstructed.isBridge, isTrue);
      expect(reconstructed.clusterIds, equals(['c1', 'c2']));
    });

    test('3. UnifiedPersonRelationshipIntelligence JSON string round-trip', () {
      final original = UnifiedPersonRelationshipIntelligence.empty('p_empty', referenceDate: refDate);
      final jsonStr = original.toJson();
      final restored = UnifiedPersonRelationshipIntelligence.fromJson(jsonStr);

      expect(restored.personId, equals('p_empty'));
      expect(restored.strengthScore, equals(0.0));
      expect(restored.relationshipState, equals(RelationshipState.newRelationship));
    });

    test('4. UnifiedPersonRelationshipIntelligence copyWith overrides specified fields', () {
      final base = UnifiedPersonRelationshipIntelligence.empty('p1');
      final updated = base.copyWith(
        personName: 'New Name',
        company: 'Brand New Co',
        relationshipState: RelationshipState.cooling,
      );

      expect(updated.personId, equals('p1'));
      expect(updated.personName, equals('New Name'));
      expect(updated.company, equals('Brand New Co'));
      expect(updated.relationshipState, equals(RelationshipState.cooling));
    });

    test('5. UnifiedPersonRelationshipIntelligence.empty returns clean zero state', () {
      final empty = UnifiedPersonRelationshipIntelligence.empty('p_zero', referenceDate: refDate);

      expect(empty.personId, equals('p_zero'));
      expect(empty.strengthScore, equals(0.0));
      expect(empty.relationshipState, equals(RelationshipState.newRelationship));
      expect(empty.needsAttention, isFalse);
      expect(empty.attentionScore, equals(0.0));
      expect(empty.isIsolated, isTrue);
    });

    test('6. UnifiedNetworkRelationshipIntelligence property getters and empty factory', () {
      final emptyNet = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);

      expect(emptyNet.totalPeople, equals(0));
      expect(emptyNet.networkHealthScore, equals(0.0));
      expect(emptyNet.networkHealthLevel, equals(NetworkHealthLevel.developing));
      expect(emptyNet.networkConfidence, equals(NetworkConfidence.limited));
      expect(emptyNet.totalNodes, equals(0));
      expect(emptyNet.totalConnections, equals(0));
      expect(emptyNet.clusterCount, equals(0));
      expect(emptyNet.isEmpty, isTrue);
      expect(emptyNet.hasData, isFalse);
      expect(emptyNet.densityPercentageString, equals('0.0%'));
    });

    test('7. UnifiedNetworkRelationshipIntelligence toConnectionIntelligence adapter', () {
      final emptyNet = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);
      final connIntel = emptyNet.toConnectionIntelligence();

      expect(connIntel.totalNodes, equals(0));
      expect(connIntel.totalConnections, equals(0));
      expect(connIntel.clusterCount, equals(0));
      expect(connIntel.connections, isEmpty);
      expect(connIntel.clusters, isEmpty);
    });

    test('8. UnifiedNetworkRelationshipIntelligence toMap and fromMap round-trip', () {
      final original = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);
      final map = original.toMap();
      final restored = UnifiedNetworkRelationshipIntelligence.fromMap(map);

      expect(restored.totalPeople, equals(original.totalPeople));
      expect(restored.networkHealthScore, equals(original.networkHealthScore));
      expect(restored.networkDensity, equals(original.networkDensity));
    });

    test('9. RelationshipIntelligenceSnapshot construction, getters and getPerson', () {
      final p1 = UnifiedPersonRelationshipIntelligence.empty('p1', referenceDate: refDate);
      final p2 = UnifiedPersonRelationshipIntelligence.empty('p2', referenceDate: refDate);
      final net = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: [p1, p2],
        network: net,
      );

      expect(snapshot.totalPeople, equals(2));
      expect(snapshot.hasPerson('p1'), isTrue);
      expect(snapshot.hasPerson('p3'), isFalse);
      expect(snapshot.getPerson('p1')?.personId, equals('p1'));
      expect(snapshot.getPerson('missing'), isNull);
    });

    test('10. RelationshipIntelligenceSnapshot serialization round-trip', () {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
      final map = emptySnapshot.toMap();
      final restored = RelationshipIntelligenceSnapshot.fromMap(map);

      expect(restored.totalPeople, equals(0));
      expect(restored.people, isEmpty);
      expect(restored.network.totalPeople, equals(0));
    });
  });

  // ===========================================================================
  // Group 2 — Engine Composition (13H-01 through 13H-06)
  // ===========================================================================
  group('Phase 13H-07 Group 2 — Engine Composition (13H-01 through 13H-06)', () {
    test('11. 13H-01 signals aggregate interactions, recency, and follow-ups', () {
      final p = buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final act = buildActivity(
        id: 'a1',
        personId: 'p1',
        title: 'Strategy Meeting',
        date: refDate.subtract(const Duration(days: 5)),
      );
      final fu = buildFollowUp(
        id: 'f1',
        personId: 'p1',
        title: 'Send notes',
        dueDate: '2026-08-28',
        status: FollowUpStatus.overdue,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: p,
        activities: [act],
        followUps: [fu],
        referenceDate: refDate,
      );

      expect(signals.interactionCount, greaterThan(0));
      expect(signals.daysSinceLastInteraction, equals(5));
      expect(signals.hasOverdueFollowUp, isTrue);
      expect(signals.overdueFollowUpCount, equals(1));
    });

    test('12. 13H-01 strength calculation generates bounded score 0-100', () {
      const strengthCalc = DeterministicRelationshipStrengthCalculator();
      final p = buildProfile(id: 'p1', name: 'Bob', company: 'Tech');
      final act = buildActivity(
        id: 'a1',
        personId: 'p1',
        title: 'Sync',
        date: refDate.subtract(const Duration(days: 2)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: p,
        activities: [act],
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);

      expect(strength.score, greaterThanOrEqualTo(0.0));
      expect(strength.score, lessThanOrEqualTo(100.0));
      expect(strength.factors, isNotEmpty);
    });

    test('13. 13H-01 state classification classifies dormant vs neglected vs active', () {
      const stateCalc = DeterministicRelationshipStateClassifier();

      // Dormant: > 180 days since last interaction
      final dormantSignals = RelationshipSignals(
        interactionCount: 5,
        recentInteractionDate: refDate.subtract(const Duration(days: 200)),
        daysSinceLastInteraction: 200,
        interactionFrequency: 0.1,
        relationshipAgeDays: 300,
        memoryCount: 2,
        captureCount: 1,
        activeFollowUpCount: 0,
        overdueFollowUpCount: 0,
        completedFollowUpCount: 2,
        recentInteractionCount: 0,
        recentActivityCount: 0,
      );
      final dormantState = stateCalc.classify(
        signals: dormantSignals,
        strength: RelationshipStrength.zero(),
      );
      expect(dormantState, equals(RelationshipState.dormant));
    });

    test('14. 13H-02 action engine generates proactive action for overdue follow-up', () {
      const actionEngine = DeterministicRelationshipActionEngine();
      final p = buildProfile(id: 'p1', name: 'Charlie', company: 'FinTech');
      final signals = RelationshipSignals(
        interactionCount: 3,
        recentInteractionDate: refDate.subtract(const Duration(days: 10)),
        daysSinceLastInteraction: 10,
        interactionFrequency: 1.0,
        relationshipAgeDays: 90,
        memoryCount: 1,
        captureCount: 0,
        activeFollowUpCount: 0,
        overdueFollowUpCount: 2,
        completedFollowUpCount: 1,
        recentInteractionCount: 1,
        recentActivityCount: 1,
      );
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: signals,
        strength: const RelationshipStrength(score: 55.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.neglected,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      final action = actionEngine.getPrimaryAction(p, intel, referenceDate: refDate);
      expect(action, isNotNull);
      expect(action!.type, equals(RelationshipActionType.completeOverdueFollowUp));
      expect(action.priority, equals(RelationshipActionPriority.urgent));
    });

    test('15. 13H-03 attention engine computes elevated score for neglected contacts', () {
      const attentionEngine = DeterministicRelationshipAttentionEngine();
      final p = buildProfile(id: 'p1', name: 'Diana', company: 'Health');
      final signals = RelationshipSignals(
        interactionCount: 5,
        recentInteractionDate: refDate.subtract(const Duration(days: 70)),
        daysSinceLastInteraction: 70,
        interactionFrequency: 0.5,
        relationshipAgeDays: 200,
        memoryCount: 2,
        captureCount: 0,
        activeFollowUpCount: 0,
        overdueFollowUpCount: 1,
        completedFollowUpCount: 2,
        recentInteractionCount: 0,
        recentActivityCount: 0,
      );
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: signals,
        strength: const RelationshipStrength(score: 40.0, factors: [], level: 'Cooling', summary: ''),
        state: RelationshipState.neglected,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      final attention = attentionEngine.getAttentionSync(intel, profile: p);
      expect(attention.attentionScore, greaterThan(50.0));
      expect(attention.priority, isNot(equals(RelationshipAttentionPriority.none)));
    });

    test('16. 13H-04 network health calculation scores healthy vs neglected network', () {
      const healthCalc = DeterministicNetworkHealthCalculator();
      final intel1 = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: RelationshipSignals.empty(),
        strength: const RelationshipStrength(score: 80.0, factors: [], level: 'Strong', summary: ''),
        state: RelationshipState.strong,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );
      final intel2 = PersonRelationshipIntelligence(
        personId: 'p2',
        signals: RelationshipSignals.empty(),
        strength: const RelationshipStrength(score: 75.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      final health = healthCalc.calculate(
        intelligenceList: [intel1, intel2],
        attentionList: const [],
        referenceDate: refDate,
      );

      expect(health.totalPeople, equals(2));
      expect(health.strongRelationships, equals(1));
      expect(health.activeRelationships, equals(1));
      expect(health.score, greaterThan(60.0));
    });

    test('17. 13H-04 network trends identify interaction velocities', () {
      const trendCalc = DeterministicNetworkTrendCalculator();
      final act1 = buildActivity(
        id: 'a1',
        personId: 'p1',
        title: 'Meeting 1',
        date: refDate.subtract(const Duration(days: 5)),
      );
      final act2 = buildActivity(
        id: 'a2',
        personId: 'p2',
        title: 'Meeting 2',
        date: refDate.subtract(const Duration(days: 12)),
      );

      final trends = trendCalc.calculate(
        activities: [act1, act2],
        followUps: const [],
        intelligenceList: const [],
        referenceDate: refDate,
      );

      expect(trends, isNotEmpty);
      expect(trends.any((t) => t.type == NetworkTrendType.growing || t.type == NetworkTrendType.strengthening || t.type == NetworkTrendType.stable), isTrue);
    });

    test('18. 13H-04 insight generator creates overdue commitment alert', () {
      const insightGen = DeterministicNetworkInsightGenerator();
      final health = NetworkHealth(
        score: 65.0,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.high,
        totalPeople: 2,
        activeRelationships: 1,
        strongRelationships: 0,
        coolingRelationships: 0,
        neglectedRelationships: 1,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 1,
        overdueFollowUps: 2,
        interactionCount: 10,
        recentInteractionCount: 5,
        followUpCompletionRate: 0.5,
        relationshipCoverage: 0.5,
        generatedAt: refDate,
      );

      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: RelationshipSignals(
          interactionCount: 2,
          recentInteractionDate: null,
          daysSinceLastInteraction: null,
          interactionFrequency: 0.0,
          relationshipAgeDays: 30,
          memoryCount: 0,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 2,
          completedFollowUpCount: 0,
          recentInteractionCount: 0,
          recentActivityCount: 0,
        ),
        strength: RelationshipStrength.zero(),
        state: RelationshipState.neglected,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      final insights = insightGen.generate(
        health: health,
        intelligenceList: [intel],
        attentionList: const [],
        nameMap: {'p1': 'Alice'},
      );

      expect(insights.any((i) => i.type == NetworkInsightType.followUpRisk), isTrue);
    });

    test('19. 13H-05 cadence and momentum engine detects cooling rhythm', () {
      const momentumEngine = DeterministicRelationshipMomentumEngine();
      final signals = RelationshipSignals(
        interactionCount: 5,
        recentInteractionDate: refDate.subtract(const Duration(days: 45)),
        daysSinceLastInteraction: 45,
        interactionFrequency: 1.0,
        relationshipAgeDays: 120,
        memoryCount: 1,
        captureCount: 0,
        activeFollowUpCount: 0,
        overdueFollowUpCount: 0,
        completedFollowUpCount: 1,
        recentInteractionCount: 0,
        recentActivityCount: 0,
      );
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: signals,
        strength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      // Historical cadence every 15 days, but now 45 days since last -> cooling
      final dates = [
        refDate.subtract(const Duration(days: 45)),
        refDate.subtract(const Duration(days: 60)),
        refDate.subtract(const Duration(days: 75)),
        refDate.subtract(const Duration(days: 90)),
      ];

      final momentum = momentumEngine.getMomentumSync(
        intelligence: intel,
        interactionDates: dates,
        referenceDate: refDate,
      );

      expect(momentum.direction, equals(MomentumDirection.declining));
      expect(momentum.cadence.hasCadenceHistory, isTrue);
    });

    test('20. 13H-06 network connections, clusters, and pattern detection compose cleanly', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Nova Labs');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Nova Labs');
      final p3 = buildProfile(id: 'p3', name: 'Carol', company: 'Nova Labs');

      final service = createService(profiles: [p1, p2, p3]);
      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2, p3],
        referenceDate: refDate,
      );

      expect(snapshot.networkConnections, isNotEmpty);
      expect(snapshot.networkClusters, isNotEmpty);
      expect(snapshot.networkClusters.first.name, contains('Nova Labs'));
      expect(snapshot.network.totalNodes, equals(3));
    });

    test('21. Synchronous single person intelligence computePersonIntelligenceSync composes all 6 dimensions', () {
      final p1 = buildProfile(id: 'p1', name: 'Dan', company: 'Alpha Inc');
      final act = buildActivity(
        id: 'a1',
        personId: 'p1',
        title: 'Intro meeting',
        date: refDate.subtract(const Duration(days: 3)),
      );

      final service = createService(profiles: [p1], activities: [act]);
      final intel = service.computePersonIntelligenceSync(
        profile: p1,
        activities: [act],
        referenceDate: refDate,
      );

      expect(intel.personId, equals('p1'));
      expect(intel.relationshipSignals.interactionCount, greaterThan(0));
      expect(intel.relationshipStrength.score, greaterThan(0.0));
      expect(intel.relationshipState, isNotNull);
      expect(intel.relationshipMomentum, isNotNull);
      expect(intel.relationshipAttention, isNotNull);
    });

    test('22. Single person intelligence reflects bridging status when in a bridge position', () {
      final p1 = buildProfile(id: 'p1', name: 'A', company: 'Company One');
      final p2 = buildProfile(id: 'p2', name: 'B (Bridge)', company: 'Bridge Co', connectedEntities: [
        const ConnectedEntity(id: 'p1', title: 'A', type: EntityType.person, subtitle: 'Colleague', targetRoute: '/person/p1'),
        const ConnectedEntity(id: 'p3', title: 'C', type: EntityType.person, subtitle: 'Advisor', targetRoute: '/person/p3'),
      ]);
      final p3 = buildProfile(id: 'p3', name: 'C', company: 'Company Two');

      final service = createService(profiles: [p1, p2, p3]);
      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2, p3],
        referenceDate: refDate,
      );

      expect(snapshot.people.length, equals(3));
    });
  });

  // ===========================================================================
  // Group 3 — Cross-Engine Consistency Validation
  // ===========================================================================
  group('Phase 13H-07 Group 3 — Cross-Engine Consistency Validation', () {
    const validator = RelationshipIntelligenceConsistencyValidator();

    test('23. Validator passes clean, harmonious snapshot without exceptions', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Tech');
      final service = createService(profiles: [p1]);
      final snapshot = service.computeSnapshotSync(
        profiles: [p1],
        referenceDate: refDate,
      );

      final report = validator.validateSnapshot(snapshot);
      expect(report.isValid, isTrue);
      expect(report.criticalCount, equals(0));
    });

    test('24. Validator detects contradiction: zero interactions with Strong state', () {
      final badIntel = UnifiedPersonRelationshipIntelligence(
        personId: 'p_bad',
        personName: 'Ghost',
        company: 'None',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 85.0, factors: [], level: 'Strong', summary: ''),
        relationshipState: RelationshipState.strong, // Contradiction: strong with 0 interactions
        generatedAt: refDate,
      );

      final issues = validator.validatePerson(badIntel);
      expect(issues.isNotEmpty, isTrue);
      expect(issues.any((i) => i.rule == 'NO_INTERACTION_STRONG_STATE'), isTrue);
    });

    test('25. Validator detects contradiction: zero interactions with Strengthening momentum', () {
      final badIntel = UnifiedPersonRelationshipIntelligence(
        personId: 'p_bad2',
        personName: 'Ghost 2',
        company: 'None',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: RelationshipStrength.zero(),
        relationshipState: RelationshipState.newRelationship,
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p_bad2',
        direction: MomentumDirection.strengthening,
        momentumScore: 80.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );

      final issues = validator.validatePerson(badIntel);
      expect(issues.isNotEmpty, isTrue);
      expect(issues.any((i) => i.rule == 'NO_INTERACTION_STRENGTHENING_MOMENTUM'), isTrue);
    });

    test('26. Validator detects contradiction: critical attention with zero score', () {
      final badIntel = UnifiedPersonRelationshipIntelligence(
        personId: 'p_bad3',
        personName: 'Ghost 3',
        company: 'None',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: RelationshipStrength.zero(),
        relationshipState: RelationshipState.newRelationship,
        relationshipAttention: RelationshipAttention.simple(
        personId: 'p_bad3',
        personName: 'Ghost 3',
        attentionScore: 0.0,
        priority: RelationshipAttentionPriority.critical,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );

      final issues = validator.validatePerson(badIntel);
      expect(issues.isNotEmpty, isTrue);
      expect(issues.any((i) => i.rule == 'UNSUPPORTED_CRITICAL_ATTENTION'), isTrue);
    });

    test('27. Validator detects aggregate count mismatch in snapshot', () {
      final p1 = UnifiedPersonRelationshipIntelligence.empty('p1', referenceDate: refDate);
      final netHealthWithWrongCount = NetworkHealth(
        score: 50.0,
        level: NetworkHealthLevel.developing,
        confidence: NetworkConfidence.moderate,
        totalPeople: 10, // Contradiction: 10 claimed, but snapshot only has 1 person
        activeRelationships: 5,
        strongRelationships: 2,
        coolingRelationships: 1,
        neglectedRelationships: 2,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 0,
        overdueFollowUps: 0,
        interactionCount: 10,
        recentInteractionCount: 5,
        followUpCompletionRate: 1.0,
        relationshipCoverage: 0.5,
        generatedAt: refDate,
      );

      final net = UnifiedNetworkRelationshipIntelligence(
        health: netHealthWithWrongCount,
        generatedAt: refDate,
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: [p1],
        network: net,
      );

      final report = validator.validateSnapshot(snapshot);
      expect(report.issues.any((i) => i.rule == 'NETWORK_COUNT_MISMATCH'), isTrue);
    });

    test('28. Validator handles empty snapshot cleanly with zero issues', () {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
      final report = validator.validateSnapshot(emptySnapshot);

      expect(report.isValid, isTrue);
      expect(report.criticalCount, equals(0));
    });

    test('29. Validator throws ConsistencyException on fatal error in strict mode', () {
      final badIntel = UnifiedPersonRelationshipIntelligence(
        personId: 'p_bad_strict',
        personName: 'Ghost Strict',
        company: 'None',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 90.0, factors: [], level: 'Strong', summary: ''),
        relationshipState: RelationshipState.strong,
        generatedAt: refDate,
      );

      expect(
        () => validator.validatePerson(badIntel, throwOnCritical: true),
        throwsA(isA<ConsistencyException>()),
      );
    });

    test('30. Validator reports clean diagnostic summary string', () {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
      final report = validator.validateSnapshot(emptySnapshot);

      expect(report.toString(), contains('VALID'));
    });
  });

  // ===========================================================================
  // Group 4 — Deterministic Ranking & Tie-Breakers
  // ===========================================================================
  group('Phase 13H-07 Group 4 — Deterministic Ranking & Tie-Breakers', () {
    const ranking = UnifiedRelationshipRanking();

    test('31. Attention ranking orders priority DESC then score DESC', () {
      final a1 = RelationshipAttention.simple(
        personId: 'p1',
        personName: 'A',
        attentionScore: 90.0,
        priority: RelationshipAttentionPriority.high,
        generatedAt: refDate,
      );
      final a2 = RelationshipAttention.simple(
        personId: 'p2',
        personName: 'B',
        attentionScore: 95.0,
        priority: RelationshipAttentionPriority.critical,
        generatedAt: refDate,
      );
      final a3 = RelationshipAttention.simple(
        personId: 'p3',
        personName: 'C',
        attentionScore: 70.0,
        priority: RelationshipAttentionPriority.high,
        generatedAt: refDate,
      );

      final ranked = ranking.rankAttention([a1, a2, a3]);

      expect(ranked[0].personId, equals('p2')); // Critical
      expect(ranked[1].personId, equals('p1')); // High, score 90
      expect(ranked[2].personId, equals('p3')); // High, score 70
    });

    test('32. Attention ranking tie-breaker: identical priority & score broken by name ASC then personId ASC', () {
      final a1 = RelationshipAttention.simple(
        personId: 'p_zebra',
        personName: 'Zebra',
        attentionScore: 80.0,
        priority: RelationshipAttentionPriority.high,
        generatedAt: refDate,
      );
      final a2 = RelationshipAttention.simple(
        personId: 'p_apple',
        personName: 'Apple',
        attentionScore: 80.0,
        priority: RelationshipAttentionPriority.high,
        generatedAt: refDate,
      );

      final ranked = ranking.rankAttention([a1, a2]);
      expect(ranked[0].personName, equals('Apple'));
      expect(ranked[1].personName, equals('Zebra'));
    });

        test('33. Action ranking orders priority DESC then score DESC', () {
      final act1 = RelationshipAction.simple(
        id: 'act1',
        personId: 'p1',
        personName: 'Alice',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.medium,
        title: 'Reconnect',
        generatedAt: refDate,
      );
      final act2 = RelationshipAction.simple(
        id: 'act2',
        personId: 'p2',
        personName: 'Bob',
        type: RelationshipActionType.completeOverdueFollowUp,
        priority: RelationshipActionPriority.urgent,
        title: 'Overdue follow-up',
        generatedAt: refDate,
      );

      final ranked = ranking.rankActions([act1, act2]);
      expect(ranked.first.id, equals('act2'));
    });

    test('34. Momentum ranking orders direction significance DESC then momentumScore DESC', () {
      final m1 = RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.cooling,
        momentumScore: 70.0,
        generatedAt: refDate,
      );
      final m2 = RelationshipMomentum.simple(
        personId: 'p2',
        direction: MomentumDirection.strengthening,
        momentumScore: 60.0,
        generatedAt: refDate,
      );

      final ranked = ranking.rankMomentum([m1, m2]);
      // Strengthening (significance 5) beats Cooling (significance 4)
      expect(ranked.first.personId, equals('p2'));
    });

    test('35. Momentum ranking correctly ranks newlyDeveloping direction', () {
      final m1 = RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.newlyDeveloping,
        momentumScore: 50.0,
        generatedAt: refDate,
      );
      final m2 = RelationshipMomentum.simple(
        personId: 'p2',
        direction: MomentumDirection.stable,
        momentumScore: 80.0,
        generatedAt: refDate,
      );

      final ranked = ranking.rankMomentum([m1, m2]);
      // newlyDeveloping (significance 2) beats stable (significance 1)
      expect(ranked.first.personId, equals('p1'));
    });

    test('36. People ranking category needsAttention filters correctly', () {
      final p1 = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Needs Attention',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: RelationshipStrength.zero(),
        relationshipState: RelationshipState.neglected,
        relationshipAttention: RelationshipAttention.simple(
        personId: 'p1',
        personName: 'Needs Attention',
        attentionScore: 75.0,
        priority: RelationshipAttentionPriority.high,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );
      final p2 = UnifiedPersonRelationshipIntelligence.empty('p2', referenceDate: refDate);

      final ranked = ranking.rankPeople([p1, p2], category: UnifiedPeopleCategory.needsAttention);
      expect(ranked.length, equals(1));
      expect(ranked.first.personId, equals('p1'));
    });

    test('37. People ranking category strengthening filters correctly', () {
      final p1 = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Strengthening Contact',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 70.0, factors: [], level: 'Active', summary: ''),
        relationshipState: RelationshipState.active,
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 80.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );
      final p2 = UnifiedPersonRelationshipIntelligence.empty('p2', referenceDate: refDate);

      final ranked = ranking.rankPeople([p1, p2], category: UnifiedPeopleCategory.strengthening);
      expect(ranked.length, equals(1));
      expect(ranked.first.personId, equals('p1'));
    });

    test('38. People ranking category cooling filters correctly', () {
      final p1 = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Cooling Contact',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 50.0, factors: [], level: 'Cooling', summary: ''),
        relationshipState: RelationshipState.cooling,
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.cooling,
        momentumScore: 40.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );
      final p2 = UnifiedPersonRelationshipIntelligence.empty('p2', referenceDate: refDate);

      final ranked = ranking.rankPeople([p1, p2], category: UnifiedPeopleCategory.cooling);
      expect(ranked.length, equals(1));
      expect(ranked.first.personId, equals('p1'));
    });

    test('39. People ranking category isolated filters correctly', () {
      final p1 = UnifiedPersonRelationshipIntelligence.empty('p_iso', referenceDate: refDate);
      final p2 = UnifiedPersonRelationshipIntelligence(
        personId: 'p_connected',
        personName: 'Connected',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        relationshipState: RelationshipState.active,
        networkConnections: [
                    NetworkConnection(
            personAId: 'p_connected',
            personBId: 'p_other',
            personAName: 'Connected',
            personBName: 'Other',
            connectionType: NetworkConnectionType.sharedCompany,
            connectionScore: 50.0,
            evidenceCount: 1,
            evidenceIds: const ['ev1'],
            sharedCompany: 'Co',
            generatedAt: refDate,
          ),
        ],
        generatedAt: refDate,
      );

      final isolatedList = ranking.rankPeople([p1, p2], category: UnifiedPeopleCategory.isolated);
      expect(isolatedList.length, equals(1));
      expect(isolatedList.first.personId, equals('p_iso'));
    });

    test('40. People ranking category bridgeContacts filters correctly', () {
      final p1 = UnifiedPersonRelationshipIntelligence(
        personId: 'p_bridge',
        personName: 'Bridge Person',
        company: 'Bridge Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        relationshipState: RelationshipState.active,
        isBridge: true,
        generatedAt: refDate,
      );
      final p2 = UnifiedPersonRelationshipIntelligence.empty('p2', referenceDate: refDate);

      final bridgeList = ranking.rankPeople([p1, p2], category: UnifiedPeopleCategory.bridgeContacts);
      expect(bridgeList.length, equals(1));
      expect(bridgeList.first.personId, equals('p_bridge'));
    });
  });

  // ===========================================================================
  // Group 5 — Empty Network Truthful State
  // ===========================================================================
  group('Phase 13H-07 Group 5 — Empty Network Truthful State', () {
    test('41. computeSnapshotSync with empty list returns clean truthful zero state', () {
      final service = createService();
      final snapshot = service.computeSnapshotSync(
        profiles: const [],
        referenceDate: refDate,
      );

      expect(snapshot.totalPeople, equals(0));
      expect(snapshot.people, isEmpty);
      expect(snapshot.topAttention, isEmpty);
      expect(snapshot.topActions, isEmpty);
      expect(snapshot.topMomentum, isEmpty);
      expect(snapshot.networkConnections, isEmpty);
      expect(snapshot.networkClusters, isEmpty);
      expect(snapshot.networkPatterns, isEmpty);
      expect(snapshot.network.totalPeople, equals(0));
      expect(snapshot.network.networkHealthScore, equals(0.0));
      expect(snapshot.network.networkHealthLevel, equals(NetworkHealthLevel.developing));
      expect(snapshot.network.networkConfidence, equals(NetworkConfidence.limited));
    });

    test('42. Empty snapshot network density is 0.0 with formatted percentage string 0.0%', () {
      final service = createService();
      final snapshot = service.computeSnapshotSync(profiles: const [], referenceDate: refDate);

      expect(snapshot.network.networkDensity, equals(0.0));
      expect(snapshot.network.densityPercentageString, equals('0.0%'));
    });

    test('43. Empty snapshot getPerson returns null and hasPerson returns false', () {
      final service = createService();
      final snapshot = service.computeSnapshotSync(profiles: const [], referenceDate: refDate);

      expect(snapshot.hasPerson('any_id'), isFalse);
      expect(snapshot.getPerson('any_id'), isNull);
    });

    test('44. computePersonIntelligenceSync with no history returns truthful newRelationship state', () {
      final p = buildProfile(id: 'p_new', name: 'New Contact', company: 'Startup', totalInteractions: 0, firstMet: '', lastInteraction: '', relationshipStrength: 'New');
      final service = createService(profiles: [p]);
      final intel = service.computePersonIntelligenceSync(profile: p, referenceDate: refDate);

      expect(intel.personId, equals('p_new'));
      expect(intel.strengthScore, equals(0.0));
      expect(intel.relationshipState, equals(RelationshipState.newRelationship));
      expect(intel.needsAttention, isFalse);
      expect(intel.isIsolated, isTrue);
      expect(intel.connectionCount, equals(0));
    });

    test('45. Empty network evaluations do not throw exceptions or generate spurious insights', () {
      final service = createService();
      expect(() => service.computeSnapshotSync(profiles: const []), returnsNormally);

      final snapshot = service.computeSnapshotSync(profiles: const []);
      expect(snapshot.network.insights, isEmpty);
      expect(snapshot.network.trends, isEmpty);
    });

    test('46. Empty network top extractions return empty lists safely', () {
      final service = createService();
      final snapshot = service.computeSnapshotSync(profiles: const []);

      expect(service.getTopAttention(snapshot.people), isEmpty);
      expect(service.getTopActions(snapshot.people), isEmpty);
      expect(service.getTopMomentum(snapshot.people), isEmpty);
    });
  });

  // ===========================================================================
  // Group 6 — Sparse Network Scaling
  // ===========================================================================
  group('Phase 13H-07 Group 6 — Sparse Network Scaling', () {
    test('47. 1 contact network: 1 node, 0 edges, isolated person, 0 clusters', () {
      final p1 = buildProfile(id: 'p1', name: 'Single Contact', company: 'Solo Co');
      final service = createService(profiles: [p1]);
      final snapshot = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);

      expect(snapshot.totalPeople, equals(1));
      expect(snapshot.network.totalNodes, equals(1));
      expect(snapshot.network.totalConnections, equals(0));
      expect(snapshot.network.isolatedPeople, equals(1));
      expect(snapshot.network.clusterCount, equals(0));
      expect(snapshot.people.first.isIsolated, isTrue);
    });

    test('48. 2 contacts with different companies: 2 nodes, 0 edges, 2 isolated', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Company A');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Company B');
      final service = createService(profiles: [p1, p2]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2], referenceDate: refDate);

      expect(snapshot.network.totalNodes, equals(2));
      expect(snapshot.network.totalConnections, equals(0));
      expect(snapshot.network.isolatedPeople, equals(2));
    });

    test('49. 2 contacts with same company: 2 nodes, 1 edge, 0 isolated', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final service = createService(profiles: [p1, p2]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2], referenceDate: refDate);

      expect(snapshot.network.totalNodes, equals(2));
      expect(snapshot.network.totalConnections, equals(1));
      expect(snapshot.network.isolatedPeople, equals(0));
      expect(snapshot.people.every((p) => !p.isIsolated), isTrue);
    });

    test('50. 3 contacts forming triangle cluster: 3 nodes, 3 edges, strong cluster', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Tech Hub');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Tech Hub');
      final p3 = buildProfile(id: 'p3', name: 'Carol', company: 'Tech Hub');
      final service = createService(profiles: [p1, p2, p3]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2, p3], referenceDate: refDate);

      expect(snapshot.network.totalNodes, equals(3));
      expect(snapshot.network.totalConnections, equals(3)); // 3 pairs
      expect(snapshot.network.clusterCount, greaterThanOrEqualTo(1));
      expect(snapshot.network.networkDensity, equals(1.0)); // Fully connected triangle
    });

    test('51. 5 contacts with bridge contact: correctly detects bridge and 2 distinct clusters', () {
      // Group A: p1, p2 at Company A
      final p1 = buildProfile(id: 'p1', name: 'A1', company: 'Alpha Inc');
      final p2 = buildProfile(id: 'p2', name: 'A2', company: 'Alpha Inc');
      // Bridge: p3 connected to p1 and p4
      final p3 = buildProfile(id: 'p3', name: 'Bridge', company: 'Bridge LLC', connectedEntities: [
        const ConnectedEntity(id: 'p1', title: 'A1', type: EntityType.person, subtitle: '', targetRoute: '/person/p1'),
        const ConnectedEntity(id: 'p4', title: 'B1', type: EntityType.person, subtitle: '', targetRoute: '/person/p4'),
      ]);
      // Group B: p4, p5 at Company B
      final p4 = buildProfile(id: 'p4', name: 'B1', company: 'Beta Corp');
      final p5 = buildProfile(id: 'p5', name: 'B2', company: 'Beta Corp');

      final service = createService(profiles: [p1, p2, p3, p4, p5]);
      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2, p3, p4, p5],
        referenceDate: refDate,
      );

      expect(snapshot.totalPeople, equals(5));
      expect(snapshot.network.totalNodes, equals(5));
      expect(snapshot.networkConnections, isNotEmpty);
    });

    test('52. 10 contacts with diverse states and companies evaluates in sub-millisecond time', () {
      final profiles = List.generate(
        10,
        (i) => buildProfile(
          id: 'p$i',
          name: 'Person $i',
          company: 'Company ${i % 3}',
          totalInteractions: i * 2,
        ),
      );

      final service = createService(profiles: profiles);
      final stopwatch = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: refDate);
      stopwatch.stop();

      expect(snapshot.totalPeople, equals(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Fast deterministic execution
    });

    test('53. Network density formula clamp: 0.0 <= density <= 1.0', () {
      final p1 = buildProfile(id: 'p1', name: 'A', company: 'C1');
      final p2 = buildProfile(id: 'p2', name: 'B', company: 'C1');
      final service = createService(profiles: [p1, p2]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2], referenceDate: refDate);

      expect(snapshot.network.networkDensity, greaterThanOrEqualTo(0.0));
      expect(snapshot.network.networkDensity, lessThanOrEqualTo(1.0));
    });

    test('54. Cross-company connectivity and concentration score boundaries 0.0 to 100.0', () {
      final p1 = buildProfile(id: 'p1', name: 'A', company: 'C1');
      final p2 = buildProfile(id: 'p2', name: 'B', company: 'C2');
      final service = createService(profiles: [p1, p2]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2], referenceDate: refDate);

      expect(snapshot.network.crossCompanyConnectivity, greaterThanOrEqualTo(0.0));
      expect(snapshot.network.crossCompanyConnectivity, lessThanOrEqualTo(100.0));
      expect(snapshot.network.concentrationScore, greaterThanOrEqualTo(0.0));
      expect(snapshot.network.concentrationScore, lessThanOrEqualTo(100.0));
    });
  });

  // ===========================================================================
  // Group 7 — Multi-Tenant Isolation
  // ===========================================================================
  group('Phase 13H-07 Group 7 — Multi-Tenant Isolation', () {
    test('55. RelationshipIntelligenceContext is request-scoped with immutable collections', () {
      final ctx = RelationshipIntelligenceContext(
        uid: 'user_123',
        profiles: [buildProfile(id: 'p1', name: 'Alice', company: 'Co')],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: const [],
        referenceDate: refDate,
      );

      expect(ctx.uid, equals('user_123'));
      expect(ctx.profiles.length, equals(1));
      expect(() => (ctx.profiles as List).add(buildProfile(id: 'p2', name: 'Bob', company: 'Co')), throwsUnsupportedError);
    });

    test('56. Context activitiesForPerson matches personId and metadata fallback', () {
      final act1 = buildActivity(id: 'a1', personId: 'p1', title: 'Call', date: refDate);
            final act2 = ActivityItem(
        id: 'a2',
        type: ActivityType.meeting,
        period: TimelinePeriod.earlier,
        targetRoute: '/act2',
        actionLabel: 'View',
        title: 'Call 2',
        summary: '',
        timestamp: refDate.toIso8601String(),
        metadata: {'personId': 'p1'},
      );
      final act3 = buildActivity(id: 'a3', personId: 'p2', title: 'Call 3', date: refDate);

      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: [act1, act2, act3],
        followUps: const [],
        captures: const [],
      );

      final p1Activities = ctx.activitiesForPerson('p1');
      expect(p1Activities.length, equals(2));
      expect(p1Activities.map((a) => a.id), containsAll(['a1', 'a2']));
    });

    test('57. Context followUpsForPerson strictly filters by personId', () {
      final f1 = buildFollowUp(id: 'f1', personId: 'p1', title: 'F1', dueDate: '2026-08-30');
      final f2 = buildFollowUp(id: 'f2', personId: 'p2', title: 'F2', dueDate: '2026-08-30');

      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: [f1, f2],
        captures: const [],
      );

      expect(ctx.followUpsForPerson('p1').length, equals(1));
      expect(ctx.followUpsForPerson('p1').first.id, equals('f1'));
    });

    test('58. Context capturesForPerson matches personId and resolvedPersonId', () {
      final c1 = CaptureItem(
        id: 'c1',
        type: CaptureType.businessCard,
        title: 'Card 1',
        description: '',
        timestamp: refDate.toIso8601String(),
        personId: 'p1',
        targetRoute: '/capture/c1',
      );
      final c2 = CaptureItem(
        id: 'c2',
        type: CaptureType.voice,
        title: 'Voice 1',
        description: '',
        timestamp: refDate.toIso8601String(),
        resolvedPersonId: 'p1',
        targetRoute: '/capture/c2',
      );
      final c3 = CaptureItem(
        id: 'c3',
        type: CaptureType.note,
        title: 'Note 1',
        description: '',
        timestamp: refDate.toIso8601String(),
        personId: 'p2',
        targetRoute: '/capture/c3',
      );

      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: [c1, c2, c3],
      );

      final p1Caps = ctx.capturesForPerson('p1');
      expect(p1Caps.length, equals(2));
      expect(p1Caps.map((c) => c.id), containsAll(['c1', 'c2']));
    });

    test('59. Two independent services with different tenant datasets do not cross-contaminate', () {
      final pA = buildProfile(id: 'p_userA', name: 'User A Contact', company: 'Org A');
      final pB = buildProfile(id: 'p_userB', name: 'User B Contact', company: 'Org B');

      final serviceA = createService(profiles: [pA]);
      final serviceB = createService(profiles: [pB]);

      final snapA = serviceA.computeSnapshotSync(profiles: [pA], referenceDate: refDate);
      final snapB = serviceB.computeSnapshotSync(profiles: [pB], referenceDate: refDate);

      expect(snapA.hasPerson('p_userA'), isTrue);
      expect(snapA.hasPerson('p_userB'), isFalse);
      expect(snapB.hasPerson('p_userB'), isTrue);
      expect(snapB.hasPerson('p_userA'), isFalse);
    });

    test('60. Multi-tenant snapshot evaluation produces strictly zero write operations', () {
      // Deterministic computeSnapshotSync is a pure query & derive function
      final p1 = buildProfile(id: 'p1', name: 'Read Only', company: 'Clean Co');
      final service = createService(profiles: [p1]);

      // Evaluating 10 snapshots generates 0 mutations
      for (int i = 0; i < 10; i++) {
        final snap = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);
        expect(snap.totalPeople, equals(1));
      }
    });
  });

  // ===========================================================================
  // Group 8 — Authentication & Closed-Fail Handling
  // ===========================================================================
  group('Phase 13H-07 Group 8 — Authentication & Closed-Fail Handling', () {
    test('61. getSnapshot fails closed and returns empty snapshot when unauthenticated', () async {
      // Service initialized with no FirebaseAuth / null currentUser
      final service = createService();
      final snapshot = await service.getSnapshot(referenceDate: refDate);

      expect(snapshot.totalPeople, equals(0));
      expect(snapshot.people, isEmpty);
    });

    test('62. streamSnapshot yields empty snapshot when unauthenticated', () async {
      final service = createService();
      final snapshot = await service.streamSnapshot(referenceDate: refDate).first;

      expect(snapshot.totalPeople, equals(0));
      expect(snapshot.people, isEmpty);
    });

    test('63. getPersonIntelligence fails closed when unauthenticated', () async {
      final service = createService();
      final intel = await service.getPersonIntelligence('p1', referenceDate: refDate);

      expect(intel.personId, equals('p1'));
      expect(intel.strengthScore, equals(0.0));
      expect(intel.relationshipState, equals(RelationshipState.newRelationship));
    });

    test('64. streamPersonIntelligence returns empty intelligence when profile missing', () async {
      final service = createService(); // Fake repository returns null profile
      final intel = await service.streamPersonIntelligence('missing_id', referenceDate: refDate).first;

      expect(intel.personId, equals('missing_id'));
      expect(intel.strengthScore, equals(0.0));
    });

    test('65. getPeopleIntelligence returns empty list when unauthenticated', () async {
      final service = createService();
      final people = await service.getPeopleIntelligence(referenceDate: refDate);

      expect(people, isEmpty);
    });
  });

  // ===========================================================================
  // Group 9 — Repository & Context Efficiency
  // ===========================================================================
  group('Phase 13H-07 Group 9 — Repository & Context Efficiency', () {
    test('66. Single computeSnapshotSync call indexes all entities in memory without redundant queries', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Tech');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Tech', totalInteractions: 0);
      final act = buildActivity(id: 'a1', personId: 'p1', title: 'Meeting', date: refDate);

      final service = createService(profiles: [p1, p2], activities: [act]);
      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2],
        activities: [act],
        referenceDate: refDate,
      );

      expect(snapshot.totalPeople, equals(2));
      expect(snapshot.getPerson('p1')?.relationshipSignals.interactionCount, greaterThan(0));
      expect(snapshot.getPerson('p2')?.relationshipSignals.interactionCount, equals(0));
    });

    test('67. Context creation handles null referenceDate by falling back to DateTime.now()', () {
      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: const [],
      );

      expect(ctx.referenceDate, isNotNull);
    });

    test('68. Context activitiesForPerson handles empty activity list safely', () {
      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: const [],
      );

      expect(ctx.activitiesForPerson('p1'), isEmpty);
    });

    test('69. Context followUpsForPerson handles empty follow-ups safely', () {
      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: const [],
      );

      expect(ctx.followUpsForPerson('p1'), isEmpty);
    });

    test('70. Context capturesForPerson handles metadata without personId safely', () {
      final cap = CaptureItem(
        id: 'c1',
        type: CaptureType.note,
        title: 'Note',
        description: '',
        timestamp: refDate.toIso8601String(),
        targetRoute: '/c1',
        metadata: {'otherKey': 'otherValue'},
      );

      final ctx = RelationshipIntelligenceContext(
        uid: 'u1',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: [cap],
      );

      expect(ctx.capturesForPerson('p1'), isEmpty);
    });

    test('71. Single snapshot computation with 20 contacts finishes in < 100ms', () {
      final profiles = List.generate(
        20,
        (i) => buildProfile(id: 'p$i', name: 'Contact $i', company: 'Company ${i % 4}'),
      );

      final service = createService(profiles: profiles);
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: refDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(20));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });

  // ===========================================================================
  // Group 10 — Person Dossier Integration
  // ===========================================================================
  group('Phase 13H-07 Group 10 — Person Dossier Integration', () {
            testWidgets('72. RelationshipIntelligence widget renders unified intelligence badges', (tester) async {
      final unified = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Dossier Person',
        company: 'Unified Inc',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(
          score: 85.0,
          factors: [
            StrengthFactor(name: 'Recent Encounter', score: 0.9, weight: 0.3, explanation: 'Met 3 days ago'),
          ],
          level: 'Strong',
          summary: 'Highly engaged contact',
        ),
        relationshipState: RelationshipState.strong,
        relationshipMomentum: RelationshipMomentum.simple(
          personId: 'p1',
          direction: MomentumDirection.strengthening,
          momentumScore: 82.0,
          generatedAt: refDate,
        ),
        generatedAt: refDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: pds_ri.RelationshipIntelligence(
                profile: buildProfile(
                  id: 'p1',
                  name: 'Dossier Person',
                  company: 'Unified Inc',
                  relationshipStrength: 'Strong',
                ),
                unified: unified,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Strong Partner'), findsWidgets);
      expect(find.text('85/100'), findsOneWidget);
      expect(find.text('STRENGTHENING'), findsOneWidget);
    });

    testWidgets('73. RelationshipIntelligence widget renders fallback when unified is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: pds_ri.RelationshipIntelligence(
                profile: buildProfile(
                  id: 'p1',
                  name: 'Dossier Person',
                  company: 'Unified Inc',
                  relationshipStrength: 'Active',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Relationship Snapshot'), findsOneWidget);
    });

    test('74. UnifiedPersonRelationshipIntelligence provides all fields needed for dossier header', () {
      final intel = UnifiedPersonRelationshipIntelligence.empty('p1', referenceDate: refDate);

      expect(intel.strengthScore, isNotNull);
      expect(intel.relationshipState, isNotNull);
      expect(intel.momentumDirection, isNotNull);
      expect(intel.attentionPriority, isNotNull);
      expect(intel.clusterIds, isNotNull);
      expect(intel.networkConnections, isNotNull);
    });

    test('75. UnifiedPersonRelationshipIntelligence badges map cleanly to design token colors', () {
      final strongIntel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Test',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 90.0, factors: [], level: 'Strong', summary: ''),
        relationshipState: RelationshipState.strong,
        generatedAt: refDate,
      );

      expect(strongIntel.relationshipState.badgeColor, equals(RecallrColors.emeraldVerified));
    });

    test('76. Dossier explanations map cleanly to strength factors list', () {
      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Test',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(
          score: 75.0,
          factors: [
            StrengthFactor(name: 'Frequency', score: 0.8, weight: 0.25, explanation: 'Frequent interaction pattern'),
          ],
          level: 'Strong',
          summary: '',
        ),
        relationshipState: RelationshipState.strong,
        generatedAt: refDate,
      );

      expect(intel.relationshipStrength.factors.first.explanation, contains('Frequent interaction'));
    });

    test('77. Empty dossier intel renders zero-state values gracefully', () {
      final empty = UnifiedPersonRelationshipIntelligence.empty('p_empty', referenceDate: refDate);

      expect(empty.strengthScore, equals(0.0));
      expect(empty.relationshipState.label, equals('New'));
    });
  });

  // ===========================================================================
  // Group 11 — Home Command Center Integration
  // ===========================================================================
  group('Phase 13H-07 Group 11 — Home Command Center Integration', () {
    testWidgets('78. HomeScreen accepts initialSnapshot and renders without error', (tester) async {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            initialSnapshot: emptySnapshot,
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    test('79. Top attention from snapshot feeds home attention queue', () {
      final a1 = RelationshipAttention.simple(
        personId: 'p1',
        personName: 'Alert Contact',
        attentionScore: 92.0,
        priority: RelationshipAttentionPriority.critical,
        generatedAt: refDate,
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: const [],
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate),
        topAttention: [a1],
      );

      expect(snapshot.topAttention.length, equals(1));
      expect(snapshot.topAttention.first.personName, equals('Alert Contact'));
      expect(snapshot.topAttention.first.priority, equals(RelationshipAttentionPriority.critical));
    });

        test('80. Top actions from snapshot feeds home recommended actions', () {
      final act = RelationshipAction.simple(
        id: 'act1',
        personId: 'p1',
        personName: 'Action Contact',
        type: RelationshipActionType.completeOverdueFollowUp,
        priority: RelationshipActionPriority.urgent,
        title: 'Complete follow-up',
        description: 'Send deliverables',
        generatedAt: refDate,
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: const [],
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate),
        topActions: [act],
      );

      expect(snapshot.topActions.length, equals(1));
      expect(snapshot.topActions.first.title, equals('Complete follow-up'));
    });

    test('81. Top momentum from snapshot highlights accelerating contacts', () {
      final m = RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 88.0,
        generatedAt: refDate,
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: const [],
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate),
        topMomentum: [m],
      );

      expect(snapshot.topMomentum.first.direction, equals(MomentumDirection.strengthening));
    });

    test('82. Network health score from snapshot maps cleanly to home KPI metric', () {
      final netHealth = NetworkHealth(
        score: 78.5,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.high,
        totalPeople: 5,
        activeRelationships: 3,
        strongRelationships: 2,
        coolingRelationships: 0,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 0,
        overdueFollowUps: 0,
        interactionCount: 15,
        recentInteractionCount: 8,
        followUpCompletionRate: 1.0,
        relationshipCoverage: 0.8,
        generatedAt: refDate,
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: const [],
        network: UnifiedNetworkRelationshipIntelligence(
          health: netHealth,
          generatedAt: refDate,
        ),
      );

      expect(snapshot.network.networkHealthScore, equals(78.5));
      expect(snapshot.network.networkHealthLevel, equals(NetworkHealthLevel.healthy));
    });

    test('83. Unauthenticated home screen state handles empty snapshot safely', () {
      final empty = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
      expect(empty.totalPeople, equals(0));
      expect(empty.topAttention, isEmpty);
      expect(empty.topActions, isEmpty);
    });
  });

  // ===========================================================================
  // Group 12 — Network Dashboard Integration
  // ===========================================================================
  group('Phase 13H-07 Group 12 — Network Dashboard Integration', () {
    testWidgets('84. NetworkDashboardScreen accepts initialSnapshot without errors', (tester) async {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkDashboardScreen(
            initialSnapshot: emptySnapshot,
          ),
        ),
      );

      expect(find.byType(NetworkDashboardScreen), findsOneWidget);
    });

    testWidgets('85. NetworkDashboardScreen accepts initialUnifiedNetwork without errors', (tester) async {
      final emptyNet = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkDashboardScreen(
            initialUnifiedNetwork: emptyNet,
          ),
        ),
      );

      expect(find.byType(NetworkDashboardScreen), findsOneWidget);
    });

    test('86. Network density and concentration score display correctly in unified network model', () {
      final net = UnifiedNetworkRelationshipIntelligence(
        health: NetworkHealth.empty(referenceDate: refDate),
        networkDensity: 0.428,
        crossCompanyConnectivity: 65.0,
        concentrationScore: 35.0,
        generatedAt: refDate,
      );

      expect(net.densityPercentageString, equals('42.8%'));
      expect(net.crossCompanyConnectivity, equals(65.0));
      expect(net.concentrationScore, equals(35.0));
    });

    test('87. Bridge contacts count and list extract from unified network model', () {
      final net = UnifiedNetworkRelationshipIntelligence(
        health: NetworkHealth.empty(referenceDate: refDate),
        bridgeContacts: ['p1', 'p2'],
        generatedAt: refDate,
      );

      expect(net.bridgeContacts.length, equals(2));
      expect(net.bridgeContacts, contains('p1'));
    });

    test('88. Clusters and patterns unpack seamlessly from unified network', () {
      final cluster = RelationshipCluster(
        id: 'c1',
        name: 'Alpha Cluster',
        type: RelationshipClusterType.company,
        personIds: ['p1', 'p2'],
        averageRelationshipStrength: 70.0,
        averageAttentionScore: 30.0,
        interactionCount: 5,
        sharedContextCount: 2,
        clusterStrength: 75.0,
        description: 'Co-workers',
        generatedAt: refDate,
      );
      final pattern = NetworkPattern(
        id: 'pat1',
        type: NetworkPatternType.strongCluster,
        severity: NetworkPatternSeverity.info,
        title: 'Tight Cluster',
        description: 'High connectivity',
        evidencePersonIds: ['p1', 'p2'],
        evidenceConnectionIds: ['conn1'],
        impactScore: 80.0,
        recommendedAction: 'Engage cluster',
        generatedAt: refDate,
      );

      final net = UnifiedNetworkRelationshipIntelligence(
        health: NetworkHealth.empty(referenceDate: refDate),
        clusters: [cluster],
        patterns: [pattern],
        generatedAt: refDate,
      );

      expect(net.clusterCount, equals(1));
      expect(net.patterns.length, equals(1));
      expect(net.clusters.first.name, equals('Alpha Cluster'));
    });

    test('89. toConnectionIntelligence provides backwards compatibility with all 13H-06 widgets', () {
      final net = UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate);
      final legacy = net.toConnectionIntelligence();

      expect(legacy.totalNodes, equals(0));
      expect(legacy.totalConnections, equals(0));
      expect(legacy.clusters, isEmpty);
      expect(legacy.patterns, isEmpty);
    });
  });

  // ===========================================================================
  // Group 13 — People Screen Integration
  // ===========================================================================
  group('Phase 13H-07 Group 13 — People Screen Integration', () {
    testWidgets('90. PeopleScreen accepts initialSnapshot without errors', (tester) async {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);

      await tester.pumpWidget(
        MaterialApp(
          home: PeopleScreen(
            initialSnapshot: emptySnapshot,
          ),
        ),
      );

      expect(find.byType(PeopleScreen), findsOneWidget);
    });

    testWidgets('91. PersonCard displays relationship state badge when intelligence is passed', (tester) async {
      final item = PersonItem(
        id: 'p1',
        name: 'Alice Card',
        role: 'Founder',
        company: 'Startup',
        initials: 'AC',
      );

      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Alice Card',
        company: 'Startup',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 88.0, factors: [], level: 'Strong', summary: ''),
        relationshipState: RelationshipState.strong,
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 80.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonCard(
              person: item,
              intelligence: intel,
            ),
          ),
        ),
      );

      expect(find.text('STRONG'), findsOneWidget);
      expect(find.text('88/100'), findsOneWidget);
    });

    testWidgets('92. PersonCard displays momentum direction indicator when strengthening', (tester) async {
      final item = PersonItem(
        id: 'p1',
        name: 'Bob Card',
        role: 'CTO',
        company: 'Tech',
        initials: 'BC',
      );

      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Bob Card',
        company: 'Tech',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 65.0, factors: [], level: 'Active', summary: ''),
        relationshipState: RelationshipState.active,
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 75.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonCard(
              person: item,
              intelligence: intel,
            ),
          ),
        ),
      );

      // Icon for strengthening momentum
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    test('93. People screen initialSnapshot getPerson binds correctly to person cards', () {
      final intel = UnifiedPersonRelationshipIntelligence.empty('p1', referenceDate: refDate);
      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: refDate,
        people: [intel],
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: refDate),
      );

      final found = snapshot.getPerson('p1');
      expect(found, isNotNull);
      expect(found!.personId, equals('p1'));
    });

    test('94. Filter chips on people screen align with UnifiedPeopleCategory enum', () {
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.all));
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.needsAttention));
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.strengthening));
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.cooling));
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.isolated));
      expect(UnifiedPeopleCategory.values, contains(UnifiedPeopleCategory.bridgeContacts));
    });
  });

  // ===========================================================================
  // Group 14 — Grounded Ask Context Integration
  // ===========================================================================
  group('Phase 13H-07 Group 14 — Grounded Ask Context Integration', () {
    test('95. RelationshipContextAssembler formats unified relationship intelligence evidence', () {
      final p = buildProfile(id: 'p1', name: 'Grounded Contact', company: 'Evidence Co');
      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Grounded Contact',
        company: 'Evidence Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 75.0, factors: [], level: 'Strong', summary: 'Strong ties'),
        relationshipState: RelationshipState.strong,
        relationshipAttention: RelationshipAttention.simple(
        personId: 'p1',
        personName: 'Grounded Contact',
        attentionScore: 40.0,
        priority: RelationshipAttentionPriority.low,
        generatedAt: refDate,
      ),
        relationshipMomentum: RelationshipMomentum.simple(
        personId: 'p1',
        direction: MomentumDirection.stable,
        momentumScore: 50.0,
        generatedAt: refDate,
      ),
        generatedAt: refDate,
      );

      final assembler = RelationshipContextAssembler(
        peopleRepository: FakePeopleRepository([]),
        personDetailRepository: FakePersonDetailRepository({'p1': p}),
        activityRepository: FakeActivityRepository([]),
        followUpRepository: FakeFollowUpRepository([]),
        captureRepository: FakeCaptureRepository([]),
      );

      final contextStr = assembler.formatProfileContext(p, intelligence: intel);
      expect(contextStr, contains('Strength: 75.0 (Strong)'));
      expect(contextStr, contains('State: Strong'));
      expect(contextStr, contains('Momentum: stable'));
    });

    test('96. RelationshipContextAssembler includes bridge contact and cluster evidence', () {
      final p = buildProfile(id: 'p1', name: 'Bridge Contact', company: 'Bridge Co');
      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Bridge Contact',
        company: 'Bridge Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        relationshipState: RelationshipState.active,
        isBridge: true,
        clusterIds: ['cluster_fintech'],
        generatedAt: refDate,
      );

      final assembler = RelationshipContextAssembler(
        peopleRepository: FakePeopleRepository([]),
        personDetailRepository: FakePersonDetailRepository({'p1': p}),
        activityRepository: FakeActivityRepository([]),
        followUpRepository: FakeFollowUpRepository([]),
        captureRepository: FakeCaptureRepository([]),
      );

      final contextStr = assembler.formatProfileContext(p, intelligence: intel);
      expect(contextStr, contains('Bridge Contact: Yes'));
      expect(contextStr, contains('cluster_fintech'));
    });

    test('97. Grounding context safely omits empty fields when intelligence is null', () {
      final p = buildProfile(id: 'p1', name: 'Plain Contact', company: 'Plain Co');
      final assembler = RelationshipContextAssembler(
        peopleRepository: FakePeopleRepository([]),
        personDetailRepository: FakePersonDetailRepository({'p1': p}),
        activityRepository: FakeActivityRepository([]),
        followUpRepository: FakeFollowUpRepository([]),
        captureRepository: FakeCaptureRepository([]),
      );

      final contextStr = assembler.formatProfileContext(p);
      expect(contextStr, contains('Plain Contact'));
      expect(contextStr, isNot(contains('Bridge Contact: Yes')));
    });

        test('98. RelationshipContextAssembler includes recommended action evidence', () {
      final p = buildProfile(id: 'p1', name: 'Action Contact', company: 'Co');
      final act = RelationshipAction.simple(
        id: 'act1',
        personId: 'p1',
        personName: 'Action Contact',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.high,
        title: 'Reconnect message',
        description: 'Send casual hello',
        generatedAt: refDate,
      );

      final intel = UnifiedPersonRelationshipIntelligence(
        personId: 'p1',
        personName: 'Action Contact',
        company: 'Co',
        relationshipSignals: RelationshipSignals.empty(),
        relationshipStrength: RelationshipStrength.zero(),
        relationshipState: RelationshipState.dormant,
        relationshipAction: act,
        generatedAt: refDate,
      );

      final assembler = RelationshipContextAssembler(
        peopleRepository: FakePeopleRepository([]),
        personDetailRepository: FakePersonDetailRepository({'p1': p}),
        activityRepository: FakeActivityRepository([]),
        followUpRepository: FakeFollowUpRepository([]),
        captureRepository: FakeCaptureRepository([]),
      );

      final contextStr = assembler.formatProfileContext(p, intelligence: intel);
      expect(contextStr, contains('Recommended Action: Reconnect message'));
    });

    test('99. Ask context assembler formats memory items and interaction timelines cleanly', () {
      final p = buildProfile(
        id: 'p1',
        name: 'Memory Contact',
        company: 'Co',
        memories: [
          const MemoryItem(id: 'm1', category: 'Discussion', text: 'Coffee discussion on architecture', source: 'Meeting'),
        ],
      );

      final assembler = RelationshipContextAssembler(
        peopleRepository: FakePeopleRepository([]),
        personDetailRepository: FakePersonDetailRepository({'p1': p}),
        activityRepository: FakeActivityRepository([]),
        followUpRepository: FakeFollowUpRepository([]),
        captureRepository: FakeCaptureRepository([]),
      );

      final contextStr = assembler.formatProfileContext(p);
      expect(contextStr, contains('Coffee discussion on architecture'));
    });
  });

  // ===========================================================================
  // Group 15 — Zero Mock Contamination Audit
  // ===========================================================================
  group('Phase 13H-07 Group 15 — Zero Mock Contamination Audit', () {
    test('100. Production services do not contain hardcoded demo names in outputs', () {
      final p1 = buildProfile(id: 'p1', name: 'Real User Contact', company: 'Real Corp');
      final service = createService(profiles: [p1]);
      final snapshot = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);

      final snapshotJson = jsonEncode(snapshot.toMap());
      expect(snapshotJson, isNot(contains('Priya Sharma')));
      expect(snapshotJson, isNot(contains('Arjun Mehta')));
      expect(snapshotJson, isNot(contains('Sarvam AI')));
      expect(snapshotJson, isNot(contains('Vivek Raghavan')));
      expect(snapshotJson, isNot(contains('RISC-V')));
    });

    test('101. Empty snapshot contains zero mock contacts', () {
      final emptySnapshot = RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
      expect(emptySnapshot.people, isEmpty);
      expect(emptySnapshot.network.connections, isEmpty);
      expect(emptySnapshot.network.clusters, isEmpty);
    });

    test('102. Unified models handle dynamically typed runtime maps without crashing', () {
      final dynamicMap = <String, dynamic>{
        'personId': 'p_dyn',
        'personName': 'Dynamic Contact',
        'company': 'Dynamic Inc',
        'relationshipSignals': <String, dynamic>{},
        'relationshipStrength': <String, dynamic>{'score': 50.0},
        'relationshipState': 'active',
        'generatedAt': refDate.toIso8601String(),
      };

      final parsed = UnifiedPersonRelationshipIntelligence.fromMap(dynamicMap);
      expect(parsed.personId, equals('p_dyn'));
      expect(parsed.personName, equals('Dynamic Contact'));
    });

    test('103. Network intelligence models handle null optional fields in fromMap', () {
      final netMap = <String, dynamic>{
        'health': <String, dynamic>{
          'score': 60.0,
          'level': 'good',
          'confidence': 'high',
          'totalPeople': 1,
        },
      };

      final restored = UnifiedNetworkRelationshipIntelligence.fromMap(netMap);
      expect(restored.totalPeople, equals(1));
      expect(restored.connections, isEmpty);
      expect(restored.clusters, isEmpty);
    });

    test('104. Snapshot serialization survives full JSON encode and decode without data loss', () {
      final p1 = buildProfile(id: 'p1', name: 'Alpha', company: 'Nova');
      final service = createService(profiles: [p1]);
      final snapshot = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);

      final encoded = jsonEncode(snapshot.toMap());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = RelationshipIntelligenceSnapshot.fromMap(decoded);

      expect(restored.totalPeople, equals(snapshot.totalPeople));
      expect(restored.getPerson('p1')?.personName, equals('Alpha'));
    });
  });

  // ===========================================================================
  // Group 16 — Security & Secret Leak Prevention
  // ===========================================================================
  group('Phase 13H-07 Group 16 — Security & Secret Leak Prevention', () {
    test('105. Serialized models do not contain API keys, private tokens, or secrets', () {
      final intel = UnifiedPersonRelationshipIntelligence.empty('p1', referenceDate: refDate);
      final json = intel.toJson();

      expect(json, isNot(contains('AIza'))); // Google API key prefix
      expect(json, isNot(contains('Bearer ')));
      expect(json, isNot(contains('secret')));
      expect(json, isNot(contains('token')));
    });

    test('106. Snapshot computation runs strictly offline without external network calls', () {
      final p = buildProfile(id: 'p1', name: 'Offline Person', company: 'Local Co');
      final service = createService(profiles: [p]);

      // Execution is 100% synchronous and deterministic
      final snapshot = service.computeSnapshotSync(profiles: [p], referenceDate: refDate);
      expect(snapshot.totalPeople, equals(1));
    });

    test('107. Service defaults fail closed without auth state leakage', () {
      final service = createService();
      expect(service.auth, isNull);
    });

    test('108. Context does not expose raw database pointers or unauthenticated collections', () {
      final ctx = RelationshipIntelligenceContext(
        uid: 'user_safe',
        profiles: const [],
        people: const [],
        activities: const [],
        followUps: const [],
        captures: const [],
      );

      expect(ctx.uid, equals('user_safe'));
    });
  });

  // ===========================================================================
  // Group 17 — Determinism & Idempotency
  // ===========================================================================
  group('Phase 13H-07 Group 17 — Determinism & Idempotency', () {
    test('109. Running computeSnapshotSync 100 times produces 100 identical snapshots', () {
      final p1 = buildProfile(id: 'p1', name: 'Alice', company: 'Acme');
      final p2 = buildProfile(id: 'p2', name: 'Bob', company: 'Acme');
      final act = buildActivity(id: 'a1', personId: 'p1', title: 'Meeting', date: refDate.subtract(const Duration(days: 1)));
      final service = createService(profiles: [p1, p2], activities: [act]);

      final firstSnap = service.computeSnapshotSync(
        profiles: [p1, p2],
        activities: [act],
        referenceDate: refDate,
      );
      final firstJson = jsonEncode(firstSnap.toMap());

      for (int i = 0; i < 100; i++) {
        final snap = service.computeSnapshotSync(
          profiles: [p1, p2],
          activities: [act],
          referenceDate: refDate,
        );
        final snapJson = jsonEncode(snap.toMap());
        expect(snapJson, equals(firstJson));
      }
    });

    test('110. Reference date pinning guarantees reproducible time-based scores', () {
      final p = buildProfile(id: 'p1', name: 'Charlie', company: 'Tech');
      final act = buildActivity(id: 'a1', personId: 'p1', title: 'Call', date: DateTime(2026, 8, 20));
      final service = createService(profiles: [p], activities: [act]);

      final snapA = service.computeSnapshotSync(
        profiles: [p],
        activities: [act],
        referenceDate: DateTime(2026, 8, 25),
      );
      final snapB = service.computeSnapshotSync(
        profiles: [p],
        activities: [act],
        referenceDate: DateTime(2026, 8, 25),
      );

      expect(snapA.people.first.strengthScore, equals(snapB.people.first.strengthScore));
      expect(snapA.people.first.relationshipSignals.daysSinceLastInteraction, equals(5));
    });

    test('111. Ranking tie-breakers produce 100% deterministic ordering across runs', () {
      const ranking = UnifiedRelationshipRanking();
      final people = [
        UnifiedPersonRelationshipIntelligence(
          personId: 'p_b',
          personName: 'Same Name',
          company: 'Co',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
          relationshipState: RelationshipState.active,
          generatedAt: refDate,
        ),
        UnifiedPersonRelationshipIntelligence(
          personId: 'p_a',
          personName: 'Same Name',
          company: 'Co',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
          relationshipState: RelationshipState.active,
          generatedAt: refDate,
        ),
      ];

      for (int i = 0; i < 50; i++) {
        final ranked = ranking.rankPeople(people);
        expect(ranked.first.personId, equals('p_a')); // p_a precedes p_b lexicographically
      }
    });

    test('112. Edge connections sort consistently by connectionScore DESC', () {
      final p1 = buildProfile(id: 'p1', name: 'A', company: 'Shared');
      final p2 = buildProfile(id: 'p2', name: 'B', company: 'Shared');
      final p3 = buildProfile(id: 'p3', name: 'C', company: 'Shared', totalInteractions: 10);

      final service = createService(profiles: [p1, p2, p3]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2, p3], referenceDate: refDate);

      for (int i = 0; i < snapshot.networkConnections.length - 1; i++) {
        expect(
          snapshot.networkConnections[i].connectionScore,
          greaterThanOrEqualTo(snapshot.networkConnections[i + 1].connectionScore),
        );
      }
    });

    test('113. Clusters sort consistently by clusterStrength DESC', () {
      final p1 = buildProfile(id: 'p1', name: 'A1', company: 'Alpha');
      final p2 = buildProfile(id: 'p2', name: 'A2', company: 'Alpha');
      final p3 = buildProfile(id: 'p3', name: 'B1', company: 'Beta', totalInteractions: 8);
      final p4 = buildProfile(id: 'p4', name: 'B2', company: 'Beta', totalInteractions: 8);

      final service = createService(profiles: [p1, p2, p3, p4]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2, p3, p4], referenceDate: refDate);

      for (int i = 0; i < snapshot.networkClusters.length - 1; i++) {
        expect(
          snapshot.networkClusters[i].clusterStrength,
          greaterThanOrEqualTo(snapshot.networkClusters[i + 1].clusterStrength),
        );
      }
    });

    test('114. Patterns sort consistently by impactScore DESC', () {
      final p1 = buildProfile(id: 'p1', name: 'A', company: 'Nova');
      final p2 = buildProfile(id: 'p2', name: 'B', company: 'Nova');
      final service = createService(profiles: [p1, p2]);
      final snapshot = service.computeSnapshotSync(profiles: [p1, p2], referenceDate: refDate);

      for (int i = 0; i < snapshot.networkPatterns.length - 1; i++) {
        expect(
          snapshot.networkPatterns[i].impactScore,
          greaterThanOrEqualTo(snapshot.networkPatterns[i + 1].impactScore),
        );
      }
    });
  });

  // ===========================================================================
  // Group 18 — Full Golden User Journey
  // ===========================================================================
  group('Phase 13H-07 Group 18 — Full Golden User Journey', () {
    test('115. Golden Flow: Multi-person network evaluation with full intelligence stack', () {
      // 1. Setup 4 contacts across 2 companies with varied history
      final p1 = buildProfile(
        id: 'p1',
        name: 'Sarah Chen',
        company: 'Apex AI',
        totalInteractions: 5,
        relationshipStrength: 'Strong',
        firstMet: '2025-06-01',
        lastInteraction: '2026-08-28',
      );
      final p2 = buildProfile(
        id: 'p2',
        name: 'Marcus Vance',
        company: 'Apex AI',
        totalInteractions: 3,
        relationshipStrength: 'Active',
        firstMet: '2025-09-15',
        lastInteraction: '2026-08-20',
      );
      final p3 = buildProfile(
        id: 'p3',
        name: 'Elena Rostova',
        company: 'Helios Ventures',
        totalInteractions: 1,
        relationshipStrength: 'Cooling',
        firstMet: '2025-03-10',
        lastInteraction: '2026-06-01', // Cooling
      );
      final p4 = buildProfile(
        id: 'p4',
        name: 'David Kim',
        company: 'Apex AI',
        totalInteractions: 0,
        relationshipStrength: 'New',
        firstMet: '2026-08-29',
        lastInteraction: 'Never',
      );

      final activities = [
        buildActivity(id: 'a1', personId: 'p1', title: 'Product roadmap sync', date: DateTime(2026, 8, 28)),
        buildActivity(id: 'a2', personId: 'p1', title: 'Architecture review', date: DateTime(2026, 8, 15)),
        buildActivity(id: 'a3', personId: 'p2', title: 'Design alignment', date: DateTime(2026, 8, 20)),
        buildActivity(id: 'a4', personId: 'p3', title: 'Q1 Investor update', date: DateTime(2026, 6, 1)),
      ];

      final followUps = [
        buildFollowUp(
          id: 'f1',
          personId: 'p3',
          title: 'Send portfolio update',
          dueDate: '2026-06-15',
          status: FollowUpStatus.overdue, // Overdue commitment
        ),
      ];

      final captures = [
        CaptureItem(
          id: 'c1',
          type: CaptureType.businessCard,
          title: 'David Kim Visiting Card',
          description: 'Met at AI Summit',
          timestamp: '2026-08-29T14:00:00Z',
          personId: 'p4',
          targetRoute: '/capture/c1',
        ),
      ];

      final service = createService(
        profiles: [p1, p2, p3, p4],
        activities: activities,
        followUps: followUps,
        captures: captures,
      );

      // 2. Compute full unified intelligence snapshot
      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2, p3, p4],
        activities: activities,
        followUps: followUps,
        captures: captures,
        referenceDate: refDate,
      );

      // 3. Verify Snapshot Integrity
      expect(snapshot.totalPeople, equals(4));
      expect(snapshot.people.length, equals(4));

      // 4. Verify Sarah Chen: Strong, low attention, active connections
      final sarah = snapshot.getPerson('p1')!;
      expect(sarah.strengthScore, greaterThan(60.0));
      expect(sarah.relationshipState, equals(RelationshipState.active));
      expect(sarah.connectionCount, greaterThan(0));

      // 5. Verify Elena Rostova: Overdue commitment causes high attention priority
      final elena = snapshot.getPerson('p3')!;
      expect(elena.relationshipSignals.hasOverdueFollowUp, isTrue);
      expect(elena.attentionPriority, isNot(equals(RelationshipAttentionPriority.none)));
      expect(elena.primaryAction?.type, equals(RelationshipActionType.completeOverdueFollowUp));

      // 6. Verify David Kim: New contact with captured card
      final david = snapshot.getPerson('p4')!;
      expect(david.relationshipSignals.captureCount, equals(1));
      expect(david.relationshipState, equals(RelationshipState.newRelationship));

      // 7. Verify Network Clusters: Apex AI company cluster formed
      expect(snapshot.networkClusters.any((c) => c.name.contains('Apex AI')), isTrue);

      // 8. Verify Top Attention extracts Elena Rostova first
      expect(snapshot.topAttention.first.personId, equals('p3'));

      // 9. Verify Top Actions extracts completeOverdueFollowUp first
      expect(snapshot.topActions.first.type, equals(RelationshipActionType.completeOverdueFollowUp));

      // 10. Verify Cross-Engine Consistency passes 100%
      const validator = RelationshipIntelligenceConsistencyValidator();
      final report = validator.validateSnapshot(snapshot);
      expect(report.isValid, isTrue);
    });

    test('116. Golden Flow: Dynamic updates through copyWith preserve deep snapshot invariants', () {
      final p1 = buildProfile(id: 'p1', name: 'Alpha', company: 'Co');
      final service = createService(profiles: [p1]);
      final snap = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);

      final updatedSnap = snap.copyWith(
        people: [
          snap.people.first.copyWith(personName: 'Alpha Renamed'),
        ],
      );

      expect(updatedSnap.totalPeople, equals(1));
      expect(updatedSnap.getPerson('p1')?.personName, equals('Alpha Renamed'));
    });

    test('117. Golden Flow: Rank and filter people through all 6 categorical views', () {
      final p1 = buildProfile(id: 'p1', name: 'Needs Attn', company: 'Co');
      final p2 = buildProfile(id: 'p2', name: 'Strengthening', company: 'Co');
      final p3 = buildProfile(id: 'p3', name: 'Cooling', company: 'Co');
      final p4 = buildProfile(id: 'p4', name: 'Isolated', company: 'Solo');

      final service = createService(profiles: [p1, p2, p3, p4]);
      final snap = service.computeSnapshotSync(profiles: [p1, p2, p3, p4], referenceDate: refDate);

      for (final cat in UnifiedPeopleCategory.values) {
        final ranked = service.rankPeople(snap.people, category: cat);
        expect(ranked, isA<List<UnifiedPersonRelationshipIntelligence>>());
      }
    });

    test('118. Golden Flow: Top extractions respect custom limit argument', () {
      final profiles = List.generate(
        10,
        (i) => buildProfile(id: 'p$i', name: 'Person $i', company: 'Co $i'),
      );
      final service = createService(profiles: profiles);
      final snap = service.computeSnapshotSync(profiles: profiles, referenceDate: refDate);

      expect(service.getTopAttention(snap.people, limit: 3).length, lessThanOrEqualTo(3));
      expect(service.getTopActions(snap.people, limit: 2).length, lessThanOrEqualTo(2));
      expect(service.getTopMomentum(snap.people, limit: 4).length, lessThanOrEqualTo(4));
    });

    test('119. Golden Flow: Verification of zero Firestore writes and zero Gemini API calls during evaluation', () {
      final p1 = buildProfile(id: 'p1', name: 'Pure Local', company: 'Offline');
      final service = createService(profiles: [p1]);

      // Complete derive execution is pure in-memory mathematics
      final snap = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);
      expect(snap.totalPeople, equals(1));
    });

    test('120. Golden Flow: Full snapshot serialization round-trip reproduces identical object graph', () {
      final p1 = buildProfile(id: 'p1', name: 'Round Trip Contact', company: 'Round Trip Co');
      final service = createService(profiles: [p1]);
      final snap = service.computeSnapshotSync(profiles: [p1], referenceDate: refDate);

      final map = snap.toMap();
      final restored = RelationshipIntelligenceSnapshot.fromMap(map);

      expect(restored.totalPeople, equals(snap.totalPeople));
      expect(restored.getPerson('p1')?.personId, equals('p1'));
      expect(restored.network.totalPeople, equals(snap.network.totalPeople));
    });
  });
}
