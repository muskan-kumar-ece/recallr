import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/people/models/person_item.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/person_detail/models/relationship_memory_models.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'network_connection_intelligence_service.dart';
import 'network_health_calculator.dart';
import 'network_insight_generator.dart';
import 'network_intelligence_service.dart';
import 'network_trend_calculator.dart';
import 'relationship_action_engine.dart';
import 'relationship_attention_engine.dart';
import 'relationship_intelligence_consistency_validator.dart';
import 'relationship_momentum_engine.dart';
import 'relationship_state_classifier.dart';
import 'relationship_strength_calculator.dart';
import 'unified_relationship_ranking.dart';

/// Request-scoped, in-memory context holding loaded domain entities.
///
/// Prevents redundant, duplicate Firestore read queries across 13H-01 -> 13H-06 engines.
@immutable
class RelationshipIntelligenceContext {
  final String uid;
  final List<PersonProfile> profiles;
  final List<PersonItem> people;
  final List<ActivityItem> activities;
  final List<FollowUpItem> followUps;
  final List<CaptureItem> captures;
  final DateTime referenceDate;

  RelationshipIntelligenceContext({
    required this.uid,
    required List<PersonProfile> profiles,
    required List<PersonItem> people,
    required List<ActivityItem> activities,
    required List<FollowUpItem> followUps,
    required List<CaptureItem> captures,
    DateTime? referenceDate,
  })  : profiles = List.unmodifiable(profiles),
        people = List.unmodifiable(people),
        activities = List.unmodifiable(activities),
        followUps = List.unmodifiable(followUps),
        captures = List.unmodifiable(captures),
        referenceDate = referenceDate ?? DateTime.now();

  List<ActivityItem> activitiesForPerson(String personId) {
    return activities
        .where((a) =>
            a.personId == personId ||
            (a.metadata != null &&
                a.metadata!['personId']?.toString() == personId))
        .toList();
  }

  List<FollowUpItem> followUpsForPerson(String personId) {
    return followUps.where((f) => f.personId == personId).toList();
  }

  List<CaptureItem> capturesForPerson(String personId) {
    return captures
        .where((c) =>
            c.personId == personId ||
            c.resolvedPersonId == personId ||
            (c.metadata != null &&
                c.metadata!['personId']?.toString() == personId))
        .toList();
  }
}

/// Abstract contract for the Unified Relationship Intelligence Orchestrator.
abstract class UnifiedRelationshipIntelligenceService {
  /// Fetches a unified intelligence snapshot across the entire network.
  Future<RelationshipIntelligenceSnapshot> getSnapshot({DateTime? referenceDate});

  /// Streams real-time updates of the unified intelligence snapshot.
  Stream<RelationshipIntelligenceSnapshot> streamSnapshot({DateTime? referenceDate});

  /// Fetches unified intelligence for a specific contact.
  Future<UnifiedPersonRelationshipIntelligence> getPersonIntelligence(
    String personId, {
    DateTime? referenceDate,
  });

  /// Streams real-time updates for a single contact.
  Stream<UnifiedPersonRelationshipIntelligence> streamPersonIntelligence(
    String personId, {
    DateTime? referenceDate,
  });

  /// Fetches unified intelligence across all contacts.
  Future<List<UnifiedPersonRelationshipIntelligence>> getPeopleIntelligence({
    DateTime? referenceDate,
  });

  /// Ranks people categorically with deterministic tie-breaking.
  List<UnifiedPersonRelationshipIntelligence> rankPeople(
    List<UnifiedPersonRelationshipIntelligence> people, {
    UnifiedPeopleCategory category = UnifiedPeopleCategory.all,
  });

  /// Extracts top prioritized attention items.
  List<RelationshipAttention> getTopAttention(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  });

  /// Extracts top recommended actions.
  List<RelationshipAction> getTopActions(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  });

  /// Extracts top momentum insights.
  List<RelationshipMomentum> getTopMomentum(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  });

  /// Synchronous computation engine for testability and deterministic offline evaluations.
  RelationshipIntelligenceSnapshot computeSnapshotSync({
    required List<PersonProfile> profiles,
    List<PersonItem>? people,
    List<ActivityItem>? activities,
    List<FollowUpItem>? followUps,
    List<CaptureItem>? captures,
    DateTime? referenceDate,
  });

  /// Synchronous computation for a single person.
  UnifiedPersonRelationshipIntelligence computePersonIntelligenceSync({
    required PersonProfile profile,
    List<ActivityItem>? activities,
    List<FollowUpItem>? followUps,
    List<CaptureItem>? captures,
    List<PersonProfile>? allProfiles,
    DateTime? referenceDate,
  });
}

/// Production-grade deterministic implementation of UnifiedRelationshipIntelligenceService.
class DeterministicUnifiedRelationshipIntelligenceService
    implements UnifiedRelationshipIntelligenceService {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository activityRepository;
  final FollowUpRepository followUpRepository;
  final CaptureRepository captureRepository;

  final RelationshipStrengthCalculator strengthCalculator;
  final RelationshipStateClassifier stateClassifier;
  final RelationshipActionEngine actionEngine;
  final RelationshipAttentionEngine attentionEngine;
  final RelationshipMomentumEngine momentumEngine;
  final NetworkConnectionIntelligenceService networkConnectionService;
  final NetworkHealthCalculator healthCalculator;
  final NetworkTrendCalculator trendCalculator;
  final NetworkInsightGenerator insightGenerator;
  final UnifiedRelationshipRanking ranking;
  final RelationshipIntelligenceConsistencyValidator validator;
  final FirebaseAuth? auth;

  /// Computation threshold for dispatching graph computation to a background isolate.
  /// Datasets <= 50 run on the main isolate without spawning overhead.
  /// Datasets > 50 are offloaded to background computation via [compute].
  static const int kIsolateThreshold = 50;

  DeterministicUnifiedRelationshipIntelligenceService({
    required this.peopleRepository,
    required this.personDetailRepository,
    required this.activityRepository,
    required this.followUpRepository,
    required this.captureRepository,
    this.strengthCalculator = const DeterministicRelationshipStrengthCalculator(),
    this.stateClassifier = const DeterministicRelationshipStateClassifier(),
    this.actionEngine = const DeterministicRelationshipActionEngine(),
    this.attentionEngine = const DeterministicRelationshipAttentionEngine(),
    this.momentumEngine = const DeterministicRelationshipMomentumEngine(),
    NetworkConnectionIntelligenceService? networkConnectionService,
    NetworkIntelligenceService? networkIntelligenceService,
    NetworkHealthCalculator? healthCalculator,
    NetworkTrendCalculator? trendCalculator,
    NetworkInsightGenerator? insightGenerator,
    this.ranking = const UnifiedRelationshipRanking(),
    this.validator = const RelationshipIntelligenceConsistencyValidator(),
    this.auth,
  })  : networkConnectionService = networkConnectionService ??
            DeterministicNetworkConnectionIntelligenceService(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              captureRepository: captureRepository,
            ),
        healthCalculator = healthCalculator ?? const DeterministicNetworkHealthCalculator(),
        trendCalculator = trendCalculator ?? const DeterministicNetworkTrendCalculator(),
        insightGenerator = insightGenerator ?? const DeterministicNetworkInsightGenerator();

  /// Calculation-only constructor for background isolate execution.
  DeterministicUnifiedRelationshipIntelligenceService.pure({
    this.strengthCalculator = const DeterministicRelationshipStrengthCalculator(),
    this.stateClassifier = const DeterministicRelationshipStateClassifier(),
    this.actionEngine = const DeterministicRelationshipActionEngine(),
    this.attentionEngine = const DeterministicRelationshipAttentionEngine(),
    this.momentumEngine = const DeterministicRelationshipMomentumEngine(),
    NetworkConnectionIntelligenceService? networkConnectionService,
    NetworkHealthCalculator? healthCalculator,
    NetworkTrendCalculator? trendCalculator,
    NetworkInsightGenerator? insightGenerator,
    this.ranking = const UnifiedRelationshipRanking(),
    this.validator = const RelationshipIntelligenceConsistencyValidator(),
  })  : peopleRepository = const _NoOpPeopleRepository(),
        personDetailRepository = const _NoOpPersonDetailRepository(),
        activityRepository = const _NoOpActivityRepository(),
        followUpRepository = const _NoOpFollowUpRepository(),
        captureRepository = const _NoOpCaptureRepository(),
        auth = null,
        networkConnectionService = networkConnectionService ??
            const DeterministicNetworkConnectionIntelligenceService(
              peopleRepository: _NoOpPeopleRepository(),
              personDetailRepository: _NoOpPersonDetailRepository(),
              activityRepository: _NoOpActivityRepository(),
              captureRepository: _NoOpCaptureRepository(),
            ),
        healthCalculator = healthCalculator ?? const DeterministicNetworkHealthCalculator(),
        trendCalculator = trendCalculator ?? const DeterministicNetworkTrendCalculator(),
        insightGenerator = insightGenerator ?? const DeterministicNetworkInsightGenerator();

  String? _resolveCurrentUid() {
    final current = auth?.currentUser;
    if (current != null) return current.uid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<List<PersonProfile>> _loadAllProfiles(List<PersonItem> people) async {
    try {
      final allProfiles = await personDetailRepository.getAllProfiles();
      if (allProfiles.isNotEmpty) return allProfiles;
    } catch (_) {}
    final profilesList = await Future.wait(
      people.map((p) => personDetailRepository.getProfile(p.id)),
    );
    return profilesList.whereType<PersonProfile>().toList();
  }

  Future<RelationshipIntelligenceSnapshot> _dispatchSnapshotCompute({
    required List<PersonProfile> profiles,
    List<PersonItem>? people,
    List<ActivityItem>? activities,
    List<FollowUpItem>? followUps,
    List<CaptureItem>? captures,
    DateTime? referenceDate,
  }) async {
    if (profiles.length > kIsolateThreshold) {
      final params = _SnapshotComputeParams(
        profiles: profiles,
        people: people,
        activities: activities,
        followUps: followUps,
        captures: captures,
        referenceDate: referenceDate,
      );
      return compute(_computeSnapshotInIsolate, params);
    }
    return computeSnapshotSync(
      profiles: profiles,
      people: people,
      activities: activities,
      followUps: followUps,
      captures: captures,
      referenceDate: referenceDate,
    );
  }

  @override
  Future<RelationshipIntelligenceSnapshot> getSnapshot({DateTime? referenceDate}) async {
    final uid = _resolveCurrentUid();
    if (uid == null) {
      return RelationshipIntelligenceSnapshot.empty(referenceDate: referenceDate);
    }

    final people = await peopleRepository.streamPeople().first;
    if (people.isEmpty) {
      return RelationshipIntelligenceSnapshot.empty(referenceDate: referenceDate);
    }

    final profiles = await _loadAllProfiles(people);
    if (profiles.isEmpty) {
      return RelationshipIntelligenceSnapshot.empty(referenceDate: referenceDate);
    }

    final activities = await activityRepository.streamActivities().first;
    final followUps = await followUpRepository.streamFollowUps().first;
    final captures = await captureRepository.streamRecentCaptures(limit: 100).first;

    return _dispatchSnapshotCompute(
      profiles: profiles,
      people: people,
      activities: activities,
      followUps: followUps,
      captures: captures,
      referenceDate: referenceDate,
    );
  }

  @override
  Stream<RelationshipIntelligenceSnapshot> streamSnapshot({DateTime? referenceDate}) {
    return peopleRepository.streamPeople().asyncMap((people) async {
      final uid = _resolveCurrentUid();
      if (uid == null || people.isEmpty) {
        return RelationshipIntelligenceSnapshot.empty(referenceDate: referenceDate);
      }

      final profiles = await _loadAllProfiles(people);
      if (profiles.isEmpty) {
        return RelationshipIntelligenceSnapshot.empty(referenceDate: referenceDate);
      }

      final activities = await activityRepository.streamActivities().first;
      final followUps = await followUpRepository.streamFollowUps().first;
      final captures = await captureRepository.streamRecentCaptures(limit: 100).first;

      return _dispatchSnapshotCompute(
        profiles: profiles,
        people: people,
        activities: activities,
        followUps: followUps,
        captures: captures,
        referenceDate: referenceDate,
      );
    }).asBroadcastStream();
  }

  @override
  Future<UnifiedPersonRelationshipIntelligence> getPersonIntelligence(
    String personId, {
    DateTime? referenceDate,
  }) async {
    final uid = _resolveCurrentUid();
    if (uid == null) {
      return UnifiedPersonRelationshipIntelligence.empty(personId, referenceDate: referenceDate);
    }

    final profile = await personDetailRepository.getProfile(personId);
    if (profile == null) {
      return UnifiedPersonRelationshipIntelligence.empty(personId, referenceDate: referenceDate);
    }

    // PERF-P0-2: Bounded queries scoped to target person ONLY.
    // Never load all people or issue N profile queries to open one dossier.
    final activities = (await activityRepository.streamActivities().first)
        .where((a) => a.personId == personId || (a.metadata != null && a.metadata!['personId']?.toString() == personId))
        .toList();
    final followUps = (await followUpRepository.streamFollowUps().first)
        .where((f) => f.personId == personId)
        .toList();
    final captures = (await captureRepository.streamRecentCaptures(limit: 20).first)
        .where((c) => c.personId == personId || c.resolvedPersonId == personId)
        .toList();

    return computePersonIntelligenceSync(
      profile: profile,
      activities: activities,
      followUps: followUps,
      captures: captures,
      allProfiles: null,
      referenceDate: referenceDate,
    );
  }

  @override
  Stream<UnifiedPersonRelationshipIntelligence> streamPersonIntelligence(
    String personId, {
    DateTime? referenceDate,
  }) {
    return personDetailRepository.streamProfile(personId).asyncMap((profile) async {
      if (profile == null) {
        return UnifiedPersonRelationshipIntelligence.empty(personId, referenceDate: referenceDate);
      }
      return getPersonIntelligence(personId, referenceDate: referenceDate);
    }).asBroadcastStream();
  }

  @override
  Future<List<UnifiedPersonRelationshipIntelligence>> getPeopleIntelligence({
    DateTime? referenceDate,
  }) async {
    final snapshot = await getSnapshot(referenceDate: referenceDate);
    return snapshot.people;
  }

  @override
  List<UnifiedPersonRelationshipIntelligence> rankPeople(
    List<UnifiedPersonRelationshipIntelligence> people, {
    UnifiedPeopleCategory category = UnifiedPeopleCategory.all,
  }) {
    return ranking.rankPeople(people, category: category);
  }

  @override
  List<RelationshipAttention> getTopAttention(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  }) {
    final attentionList = people
        .map((p) => p.relationshipAttention)
        .whereType<RelationshipAttention>()
        .toList();
    final ranked = ranking.rankAttention(attentionList);
    return ranked.take(limit).toList();
  }

  @override
  List<RelationshipAction> getTopActions(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  }) {
    final actionList = people
        .map((p) => p.relationshipAction)
        .whereType<RelationshipAction>()
        .toList();
    final ranked = ranking.rankActions(actionList);
    return ranked.take(limit).toList();
  }

  @override
  List<RelationshipMomentum> getTopMomentum(
    List<UnifiedPersonRelationshipIntelligence> people, {
    int limit = 5,
  }) {
    final momentumList = people
        .map((p) => p.relationshipMomentum)
        .whereType<RelationshipMomentum>()
        .toList();
    final ranked = ranking.rankMomentum(momentumList);
    return ranked.take(limit).toList();
  }

  @override
  RelationshipIntelligenceSnapshot computeSnapshotSync({
    required List<PersonProfile> profiles,
    List<PersonItem>? people,
    List<ActivityItem>? activities,
    List<FollowUpItem>? followUps,
    List<CaptureItem>? captures,
    DateTime? referenceDate,
  }) {
    final refDate = referenceDate ?? DateTime.now();

    if (profiles.isEmpty) {
      return RelationshipIntelligenceSnapshot.empty(referenceDate: refDate);
    }

    final actList = activities ?? const [];
    final folList = followUps ?? const [];
    final capList = captures ?? const [];

    // Pre-index domain inputs by personId for O(1) lookups
    final Map<String, List<ActivityItem>> activitiesByPerson = {};
    for (final a in actList) {
      if (a.personId != null && a.personId!.isNotEmpty) {
        activitiesByPerson.putIfAbsent(a.personId!, () => []).add(a);
      }
      final metaPid = a.metadata?['personId']?.toString();
      if (metaPid != null && metaPid.isNotEmpty && metaPid != a.personId) {
        activitiesByPerson.putIfAbsent(metaPid, () => []).add(a);
      }
    }

    final Map<String, List<FollowUpItem>> followUpsByPerson = {};
    for (final f in folList) {
      if (f.personId != null && f.personId!.isNotEmpty) {
        followUpsByPerson.putIfAbsent(f.personId!, () => []).add(f);
      }
    }

    final Map<String, List<CaptureItem>> capturesByPerson = {};
    for (final c in capList) {
      if (c.personId != null && c.personId!.isNotEmpty) {
        capturesByPerson.putIfAbsent(c.personId!, () => []).add(c);
      }
      if (c.resolvedPersonId != null && c.resolvedPersonId!.isNotEmpty && c.resolvedPersonId != c.personId) {
        capturesByPerson.putIfAbsent(c.resolvedPersonId!, () => []).add(c);
      }
      final metaPid = c.metadata?['personId']?.toString();
      if (metaPid != null && metaPid.isNotEmpty && metaPid != c.personId && metaPid != c.resolvedPersonId) {
        capturesByPerson.putIfAbsent(metaPid, () => []).add(c);
      }
    }

    // 1. Evaluate Network Connections, Clusters, and Patterns using 13H-06 engine
    final netConnIntel = networkConnectionService.computeIntelligenceSync(
      profiles: profiles,
      activities: actList,
      captures: capList,
      referenceDate: refDate,
    );

    // Pre-index network graph entities by personId for O(1) lookup
    final Map<String, List<NetworkConnection>> connectionsByPerson = {};
    for (final c in netConnIntel.connections) {
      connectionsByPerson.putIfAbsent(c.personAId, () => []).add(c);
      connectionsByPerson.putIfAbsent(c.personBId, () => []).add(c);
    }

    final Map<String, List<String>> clustersByPerson = {};
    for (final cl in netConnIntel.clusters) {
      for (final pid in cl.personIds) {
        clustersByPerson.putIfAbsent(pid, () => []).add(cl.id);
      }
    }

    final Map<String, List<NetworkPattern>> patternsByPerson = {};
    for (final pat in netConnIntel.patterns) {
      for (final pid in pat.evidencePersonIds) {
        patternsByPerson.putIfAbsent(pid, () => []).add(pat);
      }
    }

    // 2. For each person profile, compute all intelligence dimensions
    final unifiedPeople = <UnifiedPersonRelationshipIntelligence>[];
    final baseIntelList = <PersonRelationshipIntelligence>[];
    final allAttention = <RelationshipAttention>[];
    final allActions = <RelationshipAction>[];
    final allMomentum = <RelationshipMomentum>[];

    for (final profile in profiles) {
      final pActivities = activitiesByPerson[profile.id] ?? const [];
      final pFollowUps = followUpsByPerson[profile.id] ?? const [];
      final pCaptures = capturesByPerson[profile.id] ?? const [];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: pActivities,
        followUps: pFollowUps,
        captures: pCaptures,
        referenceDate: refDate,
      );

      final strength = strengthCalculator.calculate(signals);

      final state = stateClassifier.classify(
        signals: signals,
        strength: strength,
      );

      final baseIntel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: signals,
        strength: strength,
        state: state,
        generatedAt: refDate,
        explanations: strength.factors.map((f) => f.explanation).toList(),
        topFactors: strength.factors.take(3).toList(),
      );
      baseIntelList.add(baseIntel);

      final action = actionEngine.getPrimaryAction(
        profile,
        baseIntel,
        referenceDate: refDate,
      );
      if (action != null) {
        allActions.add(action);
      }

      final attention = attentionEngine.getAttentionSync(
        baseIntel,
        profile: profile,
        company: profile.company,
        personName: profile.name,
        primaryAction: action,
      ).copyWith(generatedAt: refDate);
      allAttention.add(attention);

      final interactionDates = <DateTime>[
        ...pActivities.map((a) => a.createdAt ?? DateTime.tryParse(a.timestamp)).whereType<DateTime>(),
        ...profile.timeline.map((t) => DateTime.tryParse(t.date)).whereType<DateTime>(),
      ].toSet().toList()..sort((a, b) => b.compareTo(a));
      final overdueCount = signals.overdueFollowUpCount;

      final momentum = momentumEngine.getMomentumSync(
        intelligence: baseIntel,
        interactionDates: interactionDates,
        profile: profile,
        overdueFollowUps: overdueCount,
        referenceDate: refDate,
      );
      allMomentum.add(momentum);

      // 13H-06: Connective edges and clusters for this person (O(1) pre-indexed lookups)
      final personConnections = connectionsByPerson[profile.id] ?? const [];
      final isBridge = netConnIntel.bridgeContacts.contains(profile.id);
      final personClusters = clustersByPerson[profile.id] ?? const [];
      final personPatterns = patternsByPerson[profile.id] ?? const [];

      final personIntel = UnifiedPersonRelationshipIntelligence(
        personId: profile.id,
        personName: profile.name,
        company: profile.company,
        relationshipSignals: signals,
        relationshipStrength: strength,
        relationshipState: state,
        relationshipAction: action,
        relationshipAttention: attention,
        relationshipMomentum: momentum,
        networkConnections: personConnections,
        networkPatterns: personPatterns,
        isBridge: isBridge,
        clusterIds: personClusters,
        generatedAt: refDate,
      );

      unifiedPeople.add(personIntel);
    }

    // 3. Evaluate Network Health, Trends, and Insights using 13H-04 engines
    final totalOverdueFollowUps = folList.where((f) {
      if (f.isCompleted || f.status == FollowUpStatus.completed) return false;
      if (f.status == FollowUpStatus.overdue || f.commitmentType == CommitmentType.overdue) return true;
      final parsed = DateTime.tryParse(f.dueDate);
      return parsed != null && parsed.isBefore(refDate);
    }).length;

    final networkHealth = healthCalculator.calculate(
      intelligenceList: baseIntelList,
      attentionList: allAttention,
      totalFollowUps: folList.length,
      completedFollowUps: folList.where((f) => f.status == FollowUpStatus.completed || f.isCompleted).length,
      overdueFollowUps: totalOverdueFollowUps,
      referenceDate: refDate,
    );

    final networkTrends = trendCalculator.calculate(
      activities: actList,
      followUps: folList,
      intelligenceList: baseIntelList,
      referenceDate: refDate,
    );

    final networkInsights = insightGenerator.generate(
      health: networkHealth,
      intelligenceList: baseIntelList,
      attentionList: allAttention,
      nameMap: {for (final p in profiles) p.id: p.name},
    );

    // 4. Rank attention, actions, momentum
    final rankedAttention = ranking.rankAttention(allAttention);
    final rankedActions = ranking.rankActions(allActions);
    final rankedMomentum = ranking.rankMomentum(allMomentum);

    // 5. Construct UnifiedNetworkRelationshipIntelligence
    final unifiedNetwork = UnifiedNetworkRelationshipIntelligence(
      health: networkHealth,
      trends: networkTrends,
      insights: networkInsights,
      connections: netConnIntel.connections,
      clusters: netConnIntel.clusters,
      patterns: netConnIntel.patterns,
      topAttention: rankedAttention,
      topMomentum: rankedMomentum,
      graph: netConnIntel.graph,
      bridgeContacts: netConnIntel.bridgeContacts,
      networkDensity: netConnIntel.networkDensity,
      crossCompanyConnectivity: netConnIntel.crossCompanyConnectivity,
      concentrationScore: netConnIntel.concentrationScore,
      generatedAt: refDate,
    );

    // 6. Assemble complete Snapshot
    final snapshot = RelationshipIntelligenceSnapshot(
      generatedAt: refDate,
      people: unifiedPeople,
      network: unifiedNetwork,
      topAttention: rankedAttention,
      topActions: rankedActions,
      topMomentum: rankedMomentum,
      networkPatterns: netConnIntel.patterns,
      networkConnections: netConnIntel.connections,
      networkClusters: netConnIntel.clusters,
    );

    // 7. Verify cross-engine consistency
    validator.validateSnapshot(snapshot);

    return snapshot;
  }

  @override
  UnifiedPersonRelationshipIntelligence computePersonIntelligenceSync({
    required PersonProfile profile,
    List<ActivityItem>? activities,
    List<FollowUpItem>? followUps,
    List<CaptureItem>? captures,
    List<PersonProfile>? allProfiles,
    DateTime? referenceDate,
  }) {
    final refDate = referenceDate ?? DateTime.now();
    final actList = (activities ?? const [])
        .where((a) =>
            a.personId == profile.id ||
            (a.metadata != null && a.metadata!['personId']?.toString() == profile.id))
        .toList();
    final folList = (followUps ?? const []).where((f) => f.personId == profile.id).toList();
    final capList = (captures ?? const [])
        .where((c) =>
            c.personId == profile.id ||
            c.resolvedPersonId == profile.id ||
            (c.metadata != null && c.metadata!['personId']?.toString() == profile.id))
        .toList();

    final signals = RelationshipSignals.fromDomainData(
      profile: profile,
      activities: actList,
      followUps: folList,
      captures: capList,
      referenceDate: refDate,
    );

    final strength = strengthCalculator.calculate(signals);

    final state = stateClassifier.classify(
      signals: signals,
      strength: strength,
    );

    final baseIntel = PersonRelationshipIntelligence(
      personId: profile.id,
      signals: signals,
      strength: strength,
      state: state,
      generatedAt: refDate,
      explanations: strength.factors.map((f) => f.explanation).toList(),
      topFactors: strength.factors.take(3).toList(),
    );

    final action = actionEngine.getPrimaryAction(
      profile,
      baseIntel,
      referenceDate: refDate,
    );

    final attention = attentionEngine.getAttentionSync(
      baseIntel,
      profile: profile,
      company: profile.company,
      personName: profile.name,
      primaryAction: action,
    ).copyWith(generatedAt: refDate);

    final interactionDates = actList
        .map((a) => a.createdAt ?? DateTime.tryParse(a.timestamp))
        .whereType<DateTime>()
        .toList();
    final overdueCount = signals.overdueFollowUpCount;

    final momentum = momentumEngine.getMomentumSync(
      intelligence: baseIntel,
      interactionDates: interactionDates,
      profile: profile,
      overdueFollowUps: overdueCount,
      referenceDate: refDate,
    );

    // If allProfiles provided, evaluate connections
    List<NetworkConnection> connections = const [];
    List<NetworkPattern> patterns = const [];
    List<String> clusterIds = const [];
    bool isBridge = false;

    if (allProfiles != null && allProfiles.isNotEmpty) {
      final netConnIntel = networkConnectionService.computeIntelligenceSync(
        profiles: allProfiles,
        activities: activities ?? const [],
        captures: captures ?? const [],
        referenceDate: refDate,
      );
      connections = netConnIntel.connections.where((c) => c.involves(profile.id)).toList();
      patterns = netConnIntel.patterns
          .where((pat) => pat.evidencePersonIds.contains(profile.id))
          .toList();
      clusterIds = netConnIntel.clusters
          .where((c) => c.containsPerson(profile.id))
          .map((c) => c.id)
          .toList();
      isBridge = netConnIntel.bridgeContacts.contains(profile.id);
    }

    final personIntel = UnifiedPersonRelationshipIntelligence(
      personId: profile.id,
      personName: profile.name,
      company: profile.company,
      relationshipSignals: signals,
      relationshipStrength: strength,
      relationshipState: state,
      relationshipAction: action,
      relationshipAttention: attention,
      relationshipMomentum: momentum,
      networkConnections: connections,
      networkPatterns: patterns,
      isBridge: isBridge,
      clusterIds: clusterIds,
      generatedAt: refDate,
    );

    // Validate person consistency
    validator.validatePerson(personIntel);

    return personIntel;
  }
}

/// Parameter bundle passed across isolate boundary for background computation.
class _SnapshotComputeParams {
  final List<PersonProfile> profiles;
  final List<PersonItem>? people;
  final List<ActivityItem>? activities;
  final List<FollowUpItem>? followUps;
  final List<CaptureItem>? captures;
  final DateTime? referenceDate;

  const _SnapshotComputeParams({
    required this.profiles,
    this.people,
    this.activities,
    this.followUps,
    this.captures,
    this.referenceDate,
  });
}

/// Top-level pure computation function executed in a background isolate.
RelationshipIntelligenceSnapshot _computeSnapshotInIsolate(_SnapshotComputeParams params) {
  final service = DeterministicUnifiedRelationshipIntelligenceService.pure();
  return service.computeSnapshotSync(
    profiles: params.profiles,
    people: params.people,
    activities: params.activities,
    followUps: params.followUps,
    captures: params.captures,
    referenceDate: params.referenceDate,
  );
}

// ---------------------------------------------------------------------------
// Private No-Op Repositories for Isolate Pure Execution
// ---------------------------------------------------------------------------

class _NoOpPeopleRepository implements PeopleRepository {
  const _NoOpPeopleRepository();

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) => const Stream.empty();

  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) => const Stream.empty();

  @override
  Future<PersonItem?> getPerson(String id) async => null;

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
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async => const [];

  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(String normalizedName, String normalizedCompany) async => const [];

  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async => person;

  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async => throw UnimplementedError();
}

class _NoOpPersonDetailRepository implements PersonDetailRepository {
  const _NoOpPersonDetailRepository();

  @override
  Future<PersonProfile?> getProfile(String personId) async => null;

  @override
  Stream<PersonProfile?> streamProfile(String personId) => const Stream.empty();

  @override
  Future<List<PersonProfile>> getAllProfiles() async => const [];

  @override
  Future<void> saveProfile(PersonProfile profile) async {}

  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {}

  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {}

  @override
  Future<PersonProfile> enrichRelationshipMemory({required String personId, required RelationshipMemoryUpdate update}) async => throw UnimplementedError();

  @override
  Future<void> updateRelationshipStats(String personId, {int? totalInteractions, String? lastInteraction, String? relationshipStrength, int? sharedEventsCount}) async {}
}

class _NoOpActivityRepository implements ActivityRepository {
  const _NoOpActivityRepository();

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) => const Stream.empty();

  @override
  Future<ActivityItem?> getActivity(String id) async => null;

  @override
  Future<void> addActivity(ActivityItem activity) async {}

  @override
  Future<void> deleteActivity(String id) async {}
}

class _NoOpFollowUpRepository implements FollowUpRepository {
  const _NoOpFollowUpRepository();

  @override
  Stream<List<FollowUpItem>> streamFollowUps({String? query, FollowUpFilter? filter, int limit = 100}) => const Stream.empty();

  @override
  Future<FollowUpItem?> getFollowUp(String id) async => null;

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {}

  @override
  Future<void> addFollowUp(FollowUpItem followUp) async {}

  @override
  Future<void> updateFollowUp(FollowUpItem followUp) async {}

  @override
  Future<void> deleteFollowUp(String id) async {}

  @override
  Stream<FollowUpSummaryStats> streamSummaryStats() => const Stream.empty();
}

class _NoOpCaptureRepository implements CaptureRepository {
  const _NoOpCaptureRepository();

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) => const Stream.empty();

  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async => item;

  @override
  Future<CaptureItem?> getCapture(String id) async => null;

  @override
  Future<void> deleteCapture(String id) async {}
}
