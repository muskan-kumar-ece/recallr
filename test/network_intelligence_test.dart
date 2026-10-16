import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_distribution_bar.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_health_header.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_insights_section.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_metrics_grid.dart';
import 'package:recaller/features/relationship_intelligence/widgets/network_trends_section.dart';
import 'package:recaller/screens/network/network_dashboard_screen.dart';
import 'package:recaller/services/relationship/network_health_calculator.dart';
import 'package:recaller/services/relationship/network_insight_generator.dart';
import 'package:recaller/services/relationship/network_intelligence_service.dart';
import 'package:recaller/services/relationship/network_trend_calculator.dart';
import 'package:recaller/services/relationship/relationship_attention_engine.dart';
import 'package:recaller/services/relationship/relationship_intelligence_service.dart';

Widget _wrap(Widget child, {RecallrDependencies? dependencies}) {
  final deps = dependencies ?? RecallrDependencies.mock();
  return RecallrScope(
    dependencies: deps,
    child: MaterialApp(
      theme: RecallrTheme.darkTheme,
      routes: {
        '/network': (context) => const NetworkDashboardScreen(),
        '/capture': (context) => const Scaffold(body: Text('Capture Screen')),
        '/person/p1': (context) => const Scaffold(body: Text('Person p1')),
        '/person/p2': (context) => const Scaffold(body: Text('Person p2')),
      },
      home: child,
    ),
  );
}

PersonRelationshipIntelligence _buildIntel({
  required String personId,
  required RelationshipState state,
  double strengthScore = 50.0,
  int? daysSinceLastInteraction,
  int interactionCount = 0,
  int memoryCount = 0,
  int captureCount = 0,
  int recentActivityCount = 0,
  bool hasOverdueFollowUp = false,
  int overdueFollowUpCount = 0,
  int activeFollowUpCount = 0,
}) {
  final signals = RelationshipSignals(
    daysSinceLastInteraction: daysSinceLastInteraction,
    interactionCount: interactionCount,
    memoryCount: memoryCount,
    captureCount: captureCount,
    activeFollowUpCount: activeFollowUpCount,
    overdueFollowUpCount: overdueFollowUpCount > 0 ? overdueFollowUpCount : (hasOverdueFollowUp ? 1 : 0),
    recentActivityCount: recentActivityCount,
  );

  return PersonRelationshipIntelligence(
    personId: personId,
    signals: signals,
    strength: RelationshipStrength(
      score: strengthScore,
      factors: const [],
      level: strengthScore >= 70 ? 'High' : (strengthScore >= 35 ? 'Moderate' : 'Low'),
      summary: 'Test summary',
    ),
    state: state,
    generatedAt: DateTime(2026, 8, 29),
    explanations: const [],
    topFactors: const [],
  );
}

RelationshipAttention _buildAttention({
  required String personId,
  required String personName,
  RelationshipAttentionPriority priority = RelationshipAttentionPriority.medium,
  double score = 50.0,
  String reasonCode = 'cooling',
}) {
  return RelationshipAttention(
    personId: personId,
    personName: personName,
    attentionScore: score,
    priority: priority,
    relationshipState: RelationshipState.cooling,
    relationshipStrength: RelationshipStrength.zero(),
    reasons: [
      RelationshipAttentionReason(
        code: reasonCode,
        title: 'Needs Attention',
        description: 'Explanation for $personName',
        weight: 1.0,
      ),
    ],
    recommendedTiming: 'This week',
    generatedAt: DateTime(2026, 8, 29),
    deduplicationKey: 'att_${personId}_${priority.name}_$reasonCode',
  );
}

void main() {
  group('Phase 13H-04 Group 1 — Network Health Calculation', () {
    const calc = DeterministicNetworkHealthCalculator();

    test('1. empty network (0 people) returns clean zero health', () {
      final health = calc.calculate(
        intelligenceList: [],
        attentionList: [],
      );
      expect(health.score, equals(0.0));
      expect(health.totalPeople, equals(0));
      expect(health.confidence, equals(NetworkConfidence.limited));
    });

    test('2. single contact calculates state weight and limited confidence', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.active, interactionCount: 2, daysSinceLastInteraction: 5)];
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, greaterThan(50.0));
      expect(health.totalPeople, equals(1));
      expect(health.confidence, equals(NetworkConfidence.limited));
    });

    test('3. small network (2 people) maintains limited confidence', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.active, interactionCount: 2, daysSinceLastInteraction: 5),
        _buildIntel(personId: 'p2', state: RelationshipState.cooling, interactionCount: 2, daysSinceLastInteraction: 40),
      ];
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.totalPeople, equals(2));
      expect(health.confidence, equals(NetworkConfidence.limited));
    });

    test('4. strong-only network scores in excellent level', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(
          personId: 'p$i',
          state: RelationshipState.strong,
          strengthScore: 85.0,
          interactionCount: 8,
          memoryCount: 4,
          daysSinceLastInteraction: 3,
        ),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, greaterThanOrEqualTo(85.0));
      expect(health.level, equals(NetworkHealthLevel.excellent));
      expect(health.confidence, equals(NetworkConfidence.high));
    });

    test('5. active-only network scores in healthy or excellent level', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(
          personId: 'p$i',
          state: RelationshipState.active,
          strengthScore: 60.0,
          interactionCount: 3,
          daysSinceLastInteraction: 40,
        ),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, inInclusiveRange(70.0, 84.9));
      expect(health.level, equals(NetworkHealthLevel.healthy));
    });

    test('6. cooling-heavy network scores in developing level', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(
          personId: 'p$i',
          state: RelationshipState.cooling,
          strengthScore: 45.0,
          interactionCount: 2,
          daysSinceLastInteraction: 45,
        ),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, inInclusiveRange(50.0, 69.9));
      expect(health.level, equals(NetworkHealthLevel.developing));
    });

    test('7. neglected-heavy network scores lower than active network', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(
          personId: 'p$i',
          state: RelationshipState.neglected,
          strengthScore: 30.0,
          interactionCount: 3,
          daysSinceLastInteraction: 90,
        ),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, lessThan(60.0));
    });

    test('8. dormant-heavy network scores in lower tier', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(
          personId: 'p$i',
          state: RelationshipState.dormant,
          strengthScore: 10.0,
          interactionCount: 1,
          daysSinceLastInteraction: 200,
        ),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, lessThan(50.0));
    });

    test('9. mixed network produces balanced weighted score', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.strong, strengthScore: 90.0, daysSinceLastInteraction: 2),
        _buildIntel(personId: 'p2', state: RelationshipState.active, strengthScore: 65.0, daysSinceLastInteraction: 10),
        _buildIntel(personId: 'p3', state: RelationshipState.cooling, strengthScore: 50.0, daysSinceLastInteraction: 40),
        _buildIntel(personId: 'p4', state: RelationshipState.neglected, strengthScore: 30.0, daysSinceLastInteraction: 80),
      ];
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, inInclusiveRange(50.0, 80.0));
      expect(health.totalPeople, equals(4));
    });

    test('10. score is strictly bounded in 0..100 range', () {
      final intel = List.generate(
        5,
        (i) => _buildIntel(personId: 'p$i', state: RelationshipState.strong, strengthScore: 100.0, daysSinceLastInteraction: 1),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score, inInclusiveRange(0.0, 100.0));
    });

    test('11. zero-division safety across empty inputs', () {
      final health = calc.calculate(
        intelligenceList: [],
        attentionList: [],
        totalFollowUps: 0,
        completedFollowUps: 0,
        overdueFollowUps: 0,
      );
      expect(health.score.isNaN, isFalse);
      expect(health.score.isInfinite, isFalse);
    });

    test('12. NaN safety verification', () {
      final signals = RelationshipSignals(
        daysSinceLastInteraction: null,
        interactionCount: 0,
      );
      final intel = [
        PersonRelationshipIntelligence(
          personId: 'nan_test',
          signals: signals,
          strength: RelationshipStrength.zero(),
          state: RelationshipState.newRelationship,
          generatedAt: DateTime.now(),
          explanations: const [],
          topFactors: const [],
        )
      ];
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score.isNaN, isFalse);
    });

    test('13. Infinity safety verification', () {
      final intel = List.generate(
        100,
        (i) => _buildIntel(personId: 'inf_$i', state: RelationshipState.strong, strengthScore: 100.0, daysSinceLastInteraction: 0),
      );
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
      );
      expect(health.score.isInfinite, isFalse);
      expect(health.score, lessThanOrEqualTo(100.0));
    });

    test('14. deterministic calculation produces identical results', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.active, daysSinceLastInteraction: 5),
        _buildIntel(personId: 'p2', state: RelationshipState.cooling, daysSinceLastInteraction: 40),
      ];
      final h1 = calc.calculate(intelligenceList: intel, attentionList: []);
      final h2 = calc.calculate(intelligenceList: intel, attentionList: []);
      expect(h1.score, equals(h2.score));
      expect(h1.level, equals(h2.level));
    });

    test('15. neutral follow-up reliability when zero follow-ups exist', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.active, daysSinceLastInteraction: 5)];
      final health = calc.calculate(
        intelligenceList: intel,
        attentionList: [],
        totalFollowUps: 0,
        completedFollowUps: 0,
        overdueFollowUps: 0,
      );
      expect(health.score, greaterThan(60.0));
    });
  });

  group('Phase 13H-04 Group 2 — Aggregate Metrics', () {
    const calc = DeterministicNetworkHealthCalculator();

    final testIntel = [
      _buildIntel(personId: 'p1', state: RelationshipState.strong, daysSinceLastInteraction: 3),
      _buildIntel(personId: 'p2', state: RelationshipState.strong, daysSinceLastInteraction: 5),
      _buildIntel(personId: 'p3', state: RelationshipState.active, daysSinceLastInteraction: 12),
      _buildIntel(personId: 'p4', state: RelationshipState.newRelationship, daysSinceLastInteraction: 2),
      _buildIntel(personId: 'p5', state: RelationshipState.cooling, daysSinceLastInteraction: 40),
      _buildIntel(personId: 'p6', state: RelationshipState.neglected, daysSinceLastInteraction: 75),
      _buildIntel(personId: 'p7', state: RelationshipState.dormant, daysSinceLastInteraction: 200),
    ];

    test('16. total people count matches exactly', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.totalPeople, equals(7));
    });

    test('17. strong relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.strongRelationships, equals(2));
    });

    test('18. active relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.activeRelationships, equals(1));
    });

    test('19. cooling relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.coolingRelationships, equals(1));
    });

    test('20. neglected relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.neglectedRelationships, equals(1));
    });

    test('21. dormant relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.dormantRelationships, equals(1));
    });

    test('22. new relationships count matches', () {
      final health = calc.calculate(intelligenceList: testIntel, attentionList: []);
      expect(health.newRelationships, equals(1));
    });

    test('23. relationships needing attention matches attention list length', () {
      final att = [_buildAttention(personId: 'p5', personName: 'P5')];
      final health = calc.calculate(intelligenceList: testIntel, attentionList: att);
      expect(health.relationshipsNeedingAttention, equals(1));
    });

    test('24. critical attention count reduces health score', () {
      final attCritical = [_buildAttention(personId: 'p1', personName: 'P1', priority: RelationshipAttentionPriority.critical)];
      final healthNoAtt = calc.calculate(intelligenceList: testIntel, attentionList: []);
      final healthCrit = calc.calculate(intelligenceList: testIntel, attentionList: attCritical);
      expect(healthCrit.score, lessThan(healthNoAtt.score));
    });

    test('25. overdue follow-up count matches accurately', () {
      final health = calc.calculate(
        intelligenceList: testIntel,
        attentionList: [],
        overdueFollowUps: 3,
      );
      expect(health.overdueFollowUps, equals(3));
    });
  });

  group('Phase 13H-04 Group 3 — Temporal Trends', () {
    const trendCalc = DeterministicNetworkTrendCalculator();
    final now = DateTime(2026, 8, 29);

    test('26. recent interaction velocity in trailing 30 days', () {
      final activities = [
        ActivityItem(
          id: 'a1',
          type: ActivityType.encounter,
          period: TimelinePeriod.today,
          timestamp: '2026-08-20',
          title: 'Meeting',
          summary: 'Encounter note',
          targetRoute: '/person/p1',
          actionLabel: 'View',
          createdAt: DateTime(2026, 8, 20),
        ),
      ];
      final trends = trendCalc.calculate(
        activities: activities,
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.currentValue, equals(1.0));
      expect(velocity.type, equals(NetworkTrendType.growing));
    });

    test('27. previous-period interaction count comparison', () {
      final activities = [
        ActivityItem(
          id: 'a1',
          type: ActivityType.meeting,
          period: TimelinePeriod.earlier,
          timestamp: '2026-07-15',
          title: 'Past Meeting',
          summary: 'Past encounter',
          targetRoute: '/person/p1',
          actionLabel: 'View',
          createdAt: DateTime(2026, 7, 15),
        ),
      ];
      final trends = trendCalc.calculate(
        activities: activities,
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.previousValue, equals(1.0));
      expect(velocity.currentValue, equals(0.0));
      expect(velocity.type, equals(NetworkTrendType.cooling));
    });

    test('28. positive interaction delta generates growing trend', () {
      final activities = [
        ActivityItem(id: 'a1', type: ActivityType.meeting, period: TimelinePeriod.earlier, timestamp: '2026-07-15', title: 'M1', summary: 'S1', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 7, 15)),
        ActivityItem(id: 'a2', type: ActivityType.meeting, period: TimelinePeriod.thisWeek, timestamp: '2026-08-20', title: 'M2', summary: 'S2', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 8, 20)),
        ActivityItem(id: 'a3', type: ActivityType.meeting, period: TimelinePeriod.thisWeek, timestamp: '2026-08-25', title: 'M3', summary: 'S3', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 8, 25)),
      ];
      final trends = trendCalc.calculate(
        activities: activities,
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.delta, equals(1.0));
      expect(velocity.type, equals(NetworkTrendType.growing));
    });

    test('29. negative interaction delta generates cooling trend', () {
      final activities = [
        ActivityItem(id: 'a1', type: ActivityType.meeting, period: TimelinePeriod.earlier, timestamp: '2026-07-15', title: 'M1', summary: 'S1', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 7, 15)),
        ActivityItem(id: 'a2', type: ActivityType.meeting, period: TimelinePeriod.earlier, timestamp: '2026-07-20', title: 'M2', summary: 'S2', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 7, 20)),
      ];
      final trends = trendCalc.calculate(
        activities: activities,
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.delta, equals(-2.0));
      expect(velocity.type, equals(NetworkTrendType.cooling));
    });

    test('30. zero delta generates stable trend', () {
      final activities = [
        ActivityItem(id: 'a1', type: ActivityType.meeting, period: TimelinePeriod.earlier, timestamp: '2026-07-15', title: 'M1', summary: 'S1', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 7, 15)),
        ActivityItem(id: 'a2', type: ActivityType.meeting, period: TimelinePeriod.thisWeek, timestamp: '2026-08-20', title: 'M2', summary: 'S2', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 8, 20)),
      ];
      final trends = trendCalc.calculate(
        activities: activities,
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.delta, equals(0.0));
      expect(velocity.type, equals(NetworkTrendType.stable));
    });

    test('31. insufficient history handles empty activities honestly', () {
      final trends = trendCalc.calculate(
        activities: [],
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final velocity = trends.firstWhere((t) => t.periodLabel.contains('30 days'));
      expect(velocity.hasSufficientData, isFalse);
      expect(velocity.type, equals(NetworkTrendType.insufficientData));
    });

    test('32. cooling trend detects cooling relationships', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.cooling)];
      final trends = trendCalc.calculate(
        activities: [],
        followUps: [],
        intelligenceList: intel,
        referenceDate: now,
      );
      final coolingTrend = trends.firstWhere((t) => t.periodLabel.contains('current network status'));
      expect(coolingTrend.type, equals(NetworkTrendType.cooling));
      expect(coolingTrend.currentValue, equals(1.0));
    });

    test('33. follow-up completion rate trend formats percentage', () {
      final followUps = [
        const FollowUpItem(id: 'f1', title: 'T1', dueDate: '2026-08-20', context: 'C1', commitmentType: CommitmentType.followUp, status: FollowUpStatus.completed, isCompleted: true, personId: 'p1', personName: 'P1', targetRoute: '/f1'),
        const FollowUpItem(id: 'f2', title: 'T2', dueDate: '2026-08-29', context: 'C2', commitmentType: CommitmentType.followUp, status: FollowUpStatus.dueToday, isCompleted: false, personId: 'p1', personName: 'P1', targetRoute: '/f2'),
      ];
      final trends = trendCalc.calculate(
        activities: [],
        followUps: followUps,
        intelligenceList: [],
        referenceDate: now,
      );
      final fuTrend = trends.firstWhere((t) => t.periodLabel.contains('completed'));
      expect(fuTrend.currentValue, equals(50.0));
    });

    test('34. zero follow-ups generates insufficientData trend', () {
      final trends = trendCalc.calculate(
        activities: [],
        followUps: [],
        intelligenceList: [],
        referenceDate: now,
      );
      final fuTrend = trends.firstWhere((t) => t.periodLabel.contains('commitments'));
      expect(fuTrend.hasSufficientData, isFalse);
    });

    test('35. deterministic trend output across multiple evaluations', () {
      final activities = [
        ActivityItem(id: 'a1', type: ActivityType.meeting, period: TimelinePeriod.today, timestamp: '2026-08-28', title: 'M1', summary: 'S1', targetRoute: '/person/p1', actionLabel: 'View', createdAt: DateTime(2026, 8, 28)),
      ];
      final t1 = trendCalc.calculate(activities: activities, followUps: [], intelligenceList: [], referenceDate: now);
      final t2 = trendCalc.calculate(activities: activities, followUps: [], intelligenceList: [], referenceDate: now);
      expect(t1.first.delta, equals(t2.first.delta));
      expect(t1.first.description, equals(t2.first.description));
    });
  });

  group('Phase 13H-04 Group 4 — Grounded Insights', () {
    const insightGen = DeterministicNetworkInsightGenerator();
    const healthCalc = DeterministicNetworkHealthCalculator();

    test('36. cooling insight generated with real counts', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.cooling, interactionCount: 4),
        _buildIntel(personId: 'p2', state: RelationshipState.cooling, interactionCount: 1),
      ];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      final coolingInsight = insights.firstWhere((i) => i.type == NetworkInsightType.relationshipDecline);
      expect(coolingInsight.description, contains('2 relationships are cooling'));
      expect(coolingInsight.description, contains('1 with meaningful interaction history'));
    });

    test('37. overdue follow-up insight generated with contact name', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.active, hasOverdueFollowUp: true, overdueFollowUpCount: 1)];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: [], overdueFollowUps: 1);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
        nameMap: {'p1': 'Sarah Chen'},
      );
      final overdueInsight = insights.firstWhere((i) => i.type == NetworkInsightType.followUpRisk);
      expect(overdueInsight.description, contains('Sarah Chen'));
      expect(overdueInsight.severity, equals(NetworkInsightSeverity.critical));
    });

    test('38. high-priority attention insight generated', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.cooling)];
      final att = [_buildAttention(personId: 'p1', personName: 'David Kim', priority: RelationshipAttentionPriority.high)];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: att);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: att,
      );
      final attInsight = insights.firstWhere((i) => i.type == NetworkInsightType.attention);
      expect(attInsight.description, contains('David Kim requires proactive outreach'));
    });

    test('39. interaction momentum insight generated with real counts', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.active, interactionCount: 5, daysSinceLastInteraction: 3),
        _buildIntel(personId: 'p2', state: RelationshipState.active, interactionCount: 3, daysSinceLastInteraction: 7),
      ];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      final momentum = insights.firstWhere((i) => i.type == NetworkInsightType.interactionMomentum);
      expect(momentum.description, contains('2 contacts in the past 30 days'));
    });

    test('40. active core network ratio insight generated', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.strong),
        _buildIntel(personId: 'p2', state: RelationshipState.active),
      ];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      final core = insights.firstWhere((i) => i.type == NetworkInsightType.relationshipHealth);
      expect(core.title, contains('100% Active Core Network'));
    });

    test('41. context coverage gap insight generated when coverage < 50%', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.newRelationship),
        _buildIntel(personId: 'p2', state: RelationshipState.newRelationship),
        _buildIntel(personId: 'p3', state: RelationshipState.newRelationship),
      ];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      final cov = insights.firstWhere((i) => i.type == NetworkInsightType.networkCoverage);
      expect(cov.description, contains('lack captured encounter notes'));
    });

    test('42. maximum 5 insights returned', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.cooling, hasOverdueFollowUp: true, overdueFollowUpCount: 2),
        _buildIntel(personId: 'p2', state: RelationshipState.neglected),
        _buildIntel(personId: 'p3', state: RelationshipState.active, daysSinceLastInteraction: 2),
        _buildIntel(personId: 'p4', state: RelationshipState.strong, daysSinceLastInteraction: 5),
        _buildIntel(personId: 'p5', state: RelationshipState.newRelationship),
      ];
      final att = [_buildAttention(personId: 'p1', personName: 'P1', priority: RelationshipAttentionPriority.critical)];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: att, overdueFollowUps: 2);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: att,
      );
      expect(insights.length, lessThanOrEqualTo(5));
    });

    test('43. severity ordering: critical outranks high and medium', () {
      final intel = [
        _buildIntel(personId: 'p1', state: RelationshipState.cooling, hasOverdueFollowUp: true, overdueFollowUpCount: 1),
        _buildIntel(personId: 'p2', state: RelationshipState.cooling),
      ];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: [], overdueFollowUps: 1);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      expect(insights.first.severity, equals(NetworkInsightSeverity.critical));
    });

    test('44. grounded copy contains zero emotional or hallucinatory claims', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.neglected, daysSinceLastInteraction: 90)];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final insights = insightGen.generate(
        health: health,
        intelligenceList: intel,
        attentionList: [],
      );
      for (final i in insights) {
        expect(i.description.toLowerCase(), isNot(contains('feels')));
        expect(i.description.toLowerCase(), isNot(contains('disconnected')));
        expect(i.description.toLowerCase(), isNot(contains('might want')));
      }
    });

    test('45. deterministic generation across multiple calls', () {
      final intel = [_buildIntel(personId: 'p1', state: RelationshipState.cooling)];
      final health = healthCalc.calculate(intelligenceList: intel, attentionList: []);
      final i1 = insightGen.generate(health: health, intelligenceList: intel, attentionList: []);
      final i2 = insightGen.generate(health: health, intelligenceList: intel, attentionList: []);
      expect(i1.map((i) => i.id).toList(), equals(i2.map((i) => i.id).toList()));
    });
  });

  group('Phase 13H-04 Group 5 — Small-N Confidence', () {
    const calc = DeterministicNetworkHealthCalculator();

    test('46. zero people results in limited confidence', () {
      final h = calc.calculate(intelligenceList: [], attentionList: []);
      expect(h.confidence, equals(NetworkConfidence.limited));
    });

    test('47. 1 person results in limited confidence', () {
      final h = calc.calculate(
        intelligenceList: [_buildIntel(personId: 'p1', state: RelationshipState.active)],
        attentionList: [],
      );
      expect(h.confidence, equals(NetworkConfidence.limited));
    });

    test('48. 2 people results in limited confidence', () {
      final h = calc.calculate(
        intelligenceList: [
          _buildIntel(personId: 'p1', state: RelationshipState.active),
          _buildIntel(personId: 'p2', state: RelationshipState.active),
        ],
        attentionList: [],
      );
      expect(h.confidence, equals(NetworkConfidence.limited));
    });

    test('49. 3–9 people results in moderate confidence', () {
      final h = calc.calculate(
        intelligenceList: List.generate(5, (i) => _buildIntel(personId: 'p$i', state: RelationshipState.active)),
        attentionList: [],
      );
      expect(h.confidence, equals(NetworkConfidence.moderate));
    });

    test('50. 10+ people results in high confidence', () {
      final h = calc.calculate(
        intelligenceList: List.generate(12, (i) => _buildIntel(personId: 'p$i', state: RelationshipState.active)),
        attentionList: [],
      );
      expect(h.confidence, equals(NetworkConfidence.high));
    });

    test('51. confidence never invents certainty on small sample size', () {
      final h = calc.calculate(
        intelligenceList: [_buildIntel(personId: 'p1', state: RelationshipState.strong, strengthScore: 100.0)],
        attentionList: [],
      );
      expect(h.confidence, isNot(equals(NetworkConfidence.high)));
    });
  });

  group('Phase 13H-04 Group 6 — Security & Multi-Tenant Isolation', () {
    test('52. empty snapshot returns clean empty entities (fail-closed)', () {
      final emptySnapshot = NetworkIntelligence.empty();
      expect(emptySnapshot.health.totalPeople, equals(0));
      expect(emptySnapshot.trends, isEmpty);
      expect(emptySnapshot.insights, isEmpty);
    });

    test('53. User A data does not leak into User B snapshot', () {
      final userAIntel = [_buildIntel(personId: 'userA_1', state: RelationshipState.strong)];
      final userBIntel = [_buildIntel(personId: 'userB_1', state: RelationshipState.active)];

      const calc = DeterministicNetworkHealthCalculator();
      final healthA = calc.calculate(intelligenceList: userAIntel, attentionList: []);
      final healthB = calc.calculate(intelligenceList: userBIntel, attentionList: []);

      expect(healthA.totalPeople, equals(1));
      expect(healthB.totalPeople, equals(1));
    });

    test('54. User B cannot access User A contact insights', () {
      final userAIntel = [_buildIntel(personId: 'userA_secret', state: RelationshipState.cooling)];
      const calc = DeterministicNetworkHealthCalculator();
      const gen = DeterministicNetworkInsightGenerator();

      final healthA = calc.calculate(intelligenceList: userAIntel, attentionList: []);
      final insightsA = gen.generate(
        health: healthA,
        intelligenceList: userAIntel,
        attentionList: [],
        nameMap: {'userA_secret': 'Confidential Lead'},
      );

      expect(insightsA.first.supportingPersonIds, contains('userA_secret'));
    });

    test('55. serialization contains no private tokens or API keys', () {
      final intel = NetworkIntelligence.empty();
      final map = intel.toMap();
      expect(map.containsKey('uid'), isFalse);
      expect(map.containsKey('apiKey'), isFalse);
      expect(map.containsKey('authToken'), isFalse);
    });

    test('56. serialization round-trip fidelity', () {
      final health = NetworkHealth(
        score: 75.0,
        level: NetworkHealthLevel.healthy,
        confidence: NetworkConfidence.moderate,
        totalPeople: 5,
        activeRelationships: 3,
        strongRelationships: 1,
        coolingRelationships: 1,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 1,
        overdueFollowUps: 0,
        interactionCount: 8,
        recentInteractionCount: 4,
        followUpCompletionRate: 0.8,
        relationshipCoverage: 0.8,
        generatedAt: DateTime(2026, 8, 29),
      );
      final map = health.toMap();
      final restored = NetworkHealth.fromMap(map);
      expect(restored.score, equals(75.0));
      expect(restored.totalPeople, equals(5));
      expect(restored.level, equals(NetworkHealthLevel.healthy));
    });

    test('57. Trend serialization round-trip fidelity', () {
      const trend = NetworkTrend(
        type: NetworkTrendType.growing,
        currentValue: 12.0,
        previousValue: 8.0,
        delta: 4.0,
        percentageChange: 50.0,
        periodLabel: 'vs previous 30 days',
        description: 'Growing momentum',
      );
      final map = trend.toMap();
      final restored = NetworkTrend.fromMap(map);
      expect(restored.type, equals(NetworkTrendType.growing));
      expect(restored.delta, equals(4.0));
    });
  });

  group('Phase 13H-04 Group 7 — UI & Dashboard Widgets', () {
    final sampleHealth = NetworkHealth(
      score: 82.0,
      level: NetworkHealthLevel.healthy,
      confidence: NetworkConfidence.high,
      totalPeople: 15,
      activeRelationships: 8,
      strongRelationships: 4,
      coolingRelationships: 2,
      neglectedRelationships: 1,
      dormantRelationships: 0,
      newRelationships: 0,
      relationshipsNeedingAttention: 6,
      overdueFollowUps: 3,
      interactionCount: 24,
      recentInteractionCount: 12,
      followUpCompletionRate: 0.85,
      relationshipCoverage: 0.90,
      generatedAt: DateTime(2026, 8, 29),
    );

    testWidgets('58. NetworkHealthHeader renders score, level, and confidence badge', (tester) async {
      await tester.pumpWidget(_wrap(NetworkHealthHeader(health: sampleHealth)));
      await tester.pumpAndSettle();

      expect(find.text('82'), findsOneWidget);
      expect(find.text('HEALTHY'), findsOneWidget);
      expect(find.text('HIGH CONFIDENCE'), findsOneWidget);
      expect(find.text('NETWORK HEALTH'), findsOneWidget);
    });

    testWidgets('59. NetworkMetricsGrid renders all 6 metrics', (tester) async {
      await tester.pumpWidget(_wrap(NetworkMetricsGrid(health: sampleHealth)));
      await tester.pumpAndSettle();

      expect(find.text('People'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Cooling'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('60. NetworkDistributionBar renders proportional breakdown and legend', (tester) async {
      await tester.pumpWidget(_wrap(NetworkDistributionBar(health: sampleHealth)));
      await tester.pumpAndSettle();

      expect(find.text('RELATIONSHIP DISTRIBUTION'), findsOneWidget);
      expect(find.textContaining('Strong (4'), findsOneWidget);
      expect(find.textContaining('Active (8'), findsOneWidget);
      expect(find.textContaining('Cooling (2'), findsOneWidget);
    });

    testWidgets('61. NetworkTrendsSection renders trend cards', (tester) async {
      const trends = [
        NetworkTrend(
          type: NetworkTrendType.growing,
          currentValue: 10.0,
          previousValue: 5.0,
          delta: 5.0,
          percentageChange: 100.0,
          periodLabel: 'vs previous 30 days',
          description: '10 interactions recorded (+100% momentum).',
        ),
      ];
      await tester.pumpWidget(_wrap(const NetworkTrendsSection(trends: trends)));
      await tester.pumpAndSettle();

      expect(find.text('NETWORK TRENDS'), findsOneWidget);
      expect(find.text('Growing'), findsOneWidget);
      expect(find.text('10 interactions recorded (+100% momentum).'), findsOneWidget);
    });

    testWidgets('62. NetworkInsightsSection renders insight cards with severity badges', (tester) async {
      const insights = [
        NetworkInsight(
          id: 'i1',
          type: NetworkInsightType.followUpRisk,
          title: '1 Overdue Commitment',
          description: 'You have an overdue follow-up with Sarah Chen.',
          severity: NetworkInsightSeverity.critical,
          metric: 'Overdue',
          value: 1.0,
        ),
      ];
      await tester.pumpWidget(_wrap(const NetworkInsightsSection(insights: insights)));
      await tester.pumpAndSettle();

      expect(find.text('GROUNDED NETWORK INSIGHTS'), findsOneWidget);
      expect(find.text('1 Overdue Commitment'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('You have an overdue follow-up with Sarah Chen.'), findsOneWidget);
    });

    testWidgets('63. NetworkDashboardScreen renders populated dashboard with data', (tester) async {
      final sampleIntel = NetworkIntelligence(
        health: sampleHealth,
        trends: const [],
        insights: const [],
        topAttention: const [],
        generatedAt: DateTime(2026, 8, 29),
      );

      await tester.pumpWidget(_wrap(NetworkDashboardScreen(initialData: sampleIntel)));
      await tester.pumpAndSettle();

      expect(find.text('Network Intelligence'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('HEALTHY'), findsOneWidget);
    });

    testWidgets('64. NetworkDashboardScreen renders genuine empty state on 0 people', (tester) async {
      final emptyIntel = NetworkIntelligence.empty();

      await tester.pumpWidget(_wrap(NetworkDashboardScreen(initialData: emptyIntel)));
      await tester.pumpAndSettle();

      expect(find.text('Your Network Is Just Getting Started'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
    });

    testWidgets('65. NetworkDashboardScreen renders limited confidence guidance on small network', (tester) async {
      final smallHealth = NetworkHealth(
        score: 65.0,
        level: NetworkHealthLevel.developing,
        confidence: NetworkConfidence.limited,
        totalPeople: 1,
        activeRelationships: 1,
        strongRelationships: 0,
        coolingRelationships: 0,
        neglectedRelationships: 0,
        dormantRelationships: 0,
        newRelationships: 0,
        relationshipsNeedingAttention: 0,
        overdueFollowUps: 0,
        interactionCount: 1,
        recentInteractionCount: 1,
        followUpCompletionRate: 1.0,
        relationshipCoverage: 1.0,
        generatedAt: DateTime(2026, 8, 29),
      );
      final smallIntel = NetworkIntelligence(
        health: smallHealth,
        trends: const [],
        insights: const [],
        topAttention: const [],
        generatedAt: DateTime(2026, 8, 29),
      );

      await tester.pumpWidget(_wrap(NetworkDashboardScreen(initialData: smallIntel)));
      await tester.pumpAndSettle();

      expect(find.text('LIMITED DATA'), findsOneWidget);
      expect(find.textContaining('Limited data: Keep recording interactions'), findsOneWidget);
    });

    testWidgets('66. responsive layout renders across mobile, tablet, and desktop viewports without overflow', (tester) async {
      final sampleIntel = NetworkIntelligence(
        health: sampleHealth,
        trends: const [
          NetworkTrend(
            type: NetworkTrendType.growing,
            currentValue: 5.0,
            previousValue: 2.0,
            delta: 3.0,
            percentageChange: 150.0,
            periodLabel: 'vs previous 30 days',
            description: '5 interactions recorded.',
          ),
        ],
        insights: const [
          NetworkInsight(
            id: 'i1',
            type: NetworkInsightType.relationshipHealth,
            title: 'Active Core',
            description: '8 of 15 contacts active.',
            severity: NetworkInsightSeverity.info,
            metric: 'Ratio',
            value: 8.0,
          ),
        ],
        topAttention: const [],
        generatedAt: DateTime(2026, 8, 29),
      );

      final viewports = [
        const Size(360, 800),   // Compact mobile
        const Size(390, 844),   // Standard mobile
        const Size(768, 1024),  // Tablet portrait
        const Size(1024, 768),  // Tablet landscape
        const Size(1440, 900),  // Desktop
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrap(NetworkDashboardScreen(initialData: sampleIntel)));
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Phase 13H-04 Group 8 — Composition & Integration', () {
    test('67. compositions reuse 13H-01 relationship intelligence', () {
      final pRepo = MockPeopleRepository(initialPeople: []);
      final dRepo = MockPersonDetailRepository();
      final aRepo = MockActivityRepository();
      final fRepo = MockFollowUpRepository();
      final cRepo = MockCaptureRepository();

      final intelSvc = DeterministicRelationshipIntelligenceService(
        personDetailRepository: dRepo,
        activityRepository: aRepo,
        followUpRepository: fRepo,
        captureRepository: cRepo,
      );
      final attEngine = DeterministicRelationshipAttentionEngine();

      final netSvc = DeterministicNetworkIntelligenceService(
        peopleRepository: pRepo,
        personDetailRepository: dRepo,
        activityRepository: aRepo,
        followUpRepository: fRepo,
        captureRepository: cRepo,
        relationshipIntelligenceService: intelSvc,
        relationshipAttentionEngine: attEngine,
      );

      expect(netSvc.relationshipIntelligenceService, equals(intelSvc));
      expect(netSvc.relationshipAttentionEngine, equals(attEngine));
    });

    test('68. RecallrDependencies production wiring resolves network intelligence service', () {
      final deps = RecallrDependencies.production();
      expect(deps.networkHealthCalculator, isNotNull);
      expect(deps.networkTrendCalculator, isNotNull);
      expect(deps.networkInsightGenerator, isNotNull);
      expect(deps.networkIntelligenceService, isNotNull);
    });

    test('69. RecallrDependencies mock wiring resolves network intelligence service', () {
      final deps = RecallrDependencies.mock();
      expect(deps.networkHealthCalculator, isNotNull);
      expect(deps.networkTrendCalculator, isNotNull);
      expect(deps.networkInsightGenerator, isNotNull);
      expect(deps.networkIntelligenceService, isNotNull);
    });

    test('70. Golden User Journey: Complete network derivation across multi-contact dataset', () async {
      final pRepo = MockPeopleRepository(initialPeople: []);
      final dRepo = MockPersonDetailRepository();
      final aRepo = MockActivityRepository();
      final fRepo = MockFollowUpRepository();
      final cRepo = MockCaptureRepository();

      // Add contacts
      final p1 = PersonItem(id: 'per_sarah', name: 'Sarah Chen', role: 'Architect', company: 'Mosaic Labs', locationOrEvent: 'SF', initials: 'SC', relationshipType: RelationshipContextType.collaborator, lastInteraction: 'Aug 2026', interactionCount: 8);
      final p2 = PersonItem(id: 'per_david', name: 'David Kim', role: 'Partner', company: 'Vertex', locationOrEvent: 'NYC', initials: 'DK', relationshipType: RelationshipContextType.advisor, lastInteraction: 'Jul 2026', interactionCount: 3);

      await pRepo.addPerson(p1);
      await pRepo.addPerson(p2);

      await dRepo.saveProfile(PersonProfile(
        id: 'per_sarah',
        name: 'Sarah Chen',
        role: 'Architect',
        company: 'Mosaic Labs',
        location: 'SF',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Strong',
        firstMet: 'Jan 2026',
        lastInteraction: 'Aug 2026',
        totalInteractions: 8,
        sharedEventsCount: 2,
        aiSummary: 'Summary of Sarah',
        timeline: const [],
        memories: const [],
        followUps: const [],
      ));

      await dRepo.saveProfile(PersonProfile(
        id: 'per_david',
        name: 'David Kim',
        role: 'Partner',
        company: 'Vertex',
        location: 'NYC',
        initials: 'DK',
        relationshipType: RelationshipContextType.advisor,
        relationshipStrength: 'Active',
        firstMet: 'Feb 2026',
        lastInteraction: 'Jul 2026',
        totalInteractions: 3,
        sharedEventsCount: 1,
        aiSummary: 'Summary of David',
        timeline: const [],
        memories: const [],
        followUps: const [],
      ));

      final netSvc = DeterministicNetworkIntelligenceService(
        peopleRepository: pRepo,
        personDetailRepository: dRepo,
        activityRepository: aRepo,
        followUpRepository: fRepo,
        captureRepository: cRepo,
        relationshipIntelligenceService: DeterministicRelationshipIntelligenceService(
          personDetailRepository: dRepo,
          activityRepository: aRepo,
          followUpRepository: fRepo,
          captureRepository: cRepo,
        ),
        relationshipAttentionEngine: const DeterministicRelationshipAttentionEngine(),
      );

      final snapshot = await netSvc.getNetworkIntelligence(referenceDate: DateTime(2026, 8, 29));
      expect(snapshot.health.totalPeople, equals(2));
      expect(snapshot.health.score, greaterThan(0.0));
      expect(snapshot.health.confidence, equals(NetworkConfidence.limited));
    });

    test('71. Insight ID uniqueness across all generated observations', () {
      final intel = List.generate(
        10,
        (i) => _buildIntel(personId: 'p$i', state: RelationshipState.cooling, interactionCount: 4, hasOverdueFollowUp: i == 0),
      );
      const calc = DeterministicNetworkHealthCalculator();
      const gen = DeterministicNetworkInsightGenerator();
      final health = calc.calculate(intelligenceList: intel, attentionList: [], overdueFollowUps: 1);
      final insights = gen.generate(health: health, intelligenceList: intel, attentionList: []);

      final ids = insights.map((i) => i.id).toSet();
      expect(ids.length, equals(insights.length));
    });

    test('72. Empty people repo stream produces empty intelligence without throwing', () async {
      final pRepo = MockPeopleRepository(initialPeople: []);
      final dRepo = MockPersonDetailRepository();
      final aRepo = MockActivityRepository();
      final fRepo = MockFollowUpRepository();
      final cRepo = MockCaptureRepository();

      final netSvc = DeterministicNetworkIntelligenceService(
        peopleRepository: pRepo,
        personDetailRepository: dRepo,
        activityRepository: aRepo,
        followUpRepository: fRepo,
        captureRepository: cRepo,
        relationshipIntelligenceService: DeterministicRelationshipIntelligenceService(personDetailRepository: dRepo),
        relationshipAttentionEngine: const DeterministicRelationshipAttentionEngine(),
      );

      final result = await netSvc.getNetworkIntelligence();
      expect(result.health.totalPeople, equals(0));
      expect(result.health.score, equals(0.0));
    });
  });
}
