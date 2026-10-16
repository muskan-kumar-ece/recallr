import 'dart:async';
import '../../features/activity/models/activity_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/people/models/person_item.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'network_health_calculator.dart';
import 'network_insight_generator.dart';
import 'network_trend_calculator.dart';
import 'relationship_attention_engine.dart';
import 'relationship_intelligence_service.dart';

/// Contract for deriving complete, multi-tenant network intelligence.
abstract class NetworkIntelligenceService {
  Future<NetworkIntelligence> getNetworkIntelligence({DateTime? referenceDate});
  Stream<NetworkIntelligence> streamNetworkIntelligence({DateTime? referenceDate});
  Future<NetworkHealth> getNetworkHealth({DateTime? referenceDate});
}

/// Production implementation composing authentic Firestore repositories and 13H-01/02/03 engines.
class DeterministicNetworkIntelligenceService implements NetworkIntelligenceService {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository activityRepository;
  final FollowUpRepository followUpRepository;
  final CaptureRepository captureRepository;
  final RelationshipIntelligenceService relationshipIntelligenceService;
  final RelationshipAttentionEngine relationshipAttentionEngine;
  final NetworkHealthCalculator healthCalculator;
  final NetworkTrendCalculator trendCalculator;
  final NetworkInsightGenerator insightGenerator;

  DeterministicNetworkIntelligenceService({
    required this.peopleRepository,
    required this.personDetailRepository,
    required this.activityRepository,
    required this.followUpRepository,
    required this.captureRepository,
    required this.relationshipIntelligenceService,
    required this.relationshipAttentionEngine,
    NetworkHealthCalculator? healthCalculator,
    NetworkTrendCalculator? trendCalculator,
    NetworkInsightGenerator? insightGenerator,
  })  : healthCalculator = healthCalculator ?? const DeterministicNetworkHealthCalculator(),
        trendCalculator = trendCalculator ?? const DeterministicNetworkTrendCalculator(),
        insightGenerator = insightGenerator ?? const DeterministicNetworkInsightGenerator();

  @override
  Future<NetworkIntelligence> getNetworkIntelligence({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();

    // 1. Fetch raw domain datasets concurrently from first stream emission
    final results = await Future.wait([
      peopleRepository.streamPeople().first,
      activityRepository.streamActivities().first,
      followUpRepository.streamFollowUps().first,
    ]);

    final people = results[0] as List<PersonItem>;
    final activities = results[1] as List<ActivityItem>;
    final followUps = results[2] as List<FollowUpItem>;

    if (people.isEmpty) {
      return NetworkIntelligence.empty(referenceDate: now);
    }

    // 2. Fetch individual relationship intelligence across people
    final personIds = people.map((p) => p.id).toList();
    final intelList = await relationshipIntelligenceService.getBulkIntelligence(
      personIds,
      referenceDate: now,
    );

    // 3. Derive prioritized attention list using 13H-03 engine
    final nameMap = {for (final p in people) p.id: p.name};
    final companyMap = {for (final p in people) if (p.company.isNotEmpty) p.id: p.company};

    final rankedAttention = relationshipAttentionEngine.rankAttentionSync(
      intelList,
      nameMap: nameMap,
      companyMap: companyMap,
    );

    // 4. Calculate Aggregate Follow-up Counts
    int completedCount = 0;
    int overdueCount = 0;
    for (final f in followUps) {
      if (f.isCompleted || f.status == FollowUpStatus.completed) completedCount++;
      if (f.status == FollowUpStatus.overdue || f.commitmentType == CommitmentType.overdue) overdueCount++;
    }

    // 5. Calculate Network Health
    final health = healthCalculator.calculate(
      intelligenceList: intelList,
      attentionList: rankedAttention,
      totalFollowUps: followUps.length,
      completedFollowUps: completedCount,
      overdueFollowUps: overdueCount,
      referenceDate: now,
    );

    // 6. Calculate Network Trends
    final trends = trendCalculator.calculate(
      activities: activities,
      followUps: followUps,
      intelligenceList: intelList,
      referenceDate: now,
    );

    // 7. Generate Grounded Network Insights
    final insights = insightGenerator.generate(
      health: health,
      intelligenceList: intelList,
      attentionList: rankedAttention,
      nameMap: nameMap,
    );

    // 8. Classify Recently Strengthened vs Cooling
    final strengthened = intelList
        .where((i) => i.signals.hasRecentInteraction && i.strength.score >= 60.0)
        .toList();

    final cooling = intelList
        .where((i) => i.state == RelationshipState.cooling || i.state == RelationshipState.neglected)
        .toList();

    return NetworkIntelligence(
      health: health,
      trends: trends,
      insights: insights,
      topAttention: rankedAttention.take(5).toList(),
      recentlyStrengthened: strengthened,
      coolingRelationships: cooling,
      generatedAt: now,
    );
  }

  @override
  Stream<NetworkIntelligence> streamNetworkIntelligence({DateTime? referenceDate}) {
    return peopleRepository.streamPeople().asyncMap((_) => getNetworkIntelligence(referenceDate: referenceDate));
  }

  @override
  Future<NetworkHealth> getNetworkHealth({DateTime? referenceDate}) async {
    final intel = await getNetworkIntelligence(referenceDate: referenceDate);
    return intel.health;
  }
}
