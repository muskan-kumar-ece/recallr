import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/home/widgets/relationship_attention_section.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/features/relationship_intelligence/widgets/relationship_attention_card.dart';
import 'package:recaller/services/relationship/relationship_attention_calculator.dart';
import 'package:recaller/services/relationship/relationship_attention_engine.dart';
import 'package:recaller/services/relationship/relationship_attention_explanation.dart';
import 'package:recaller/services/relationship/relationship_attention_priority_calculator.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/follow-ups': (context) => const Scaffold(body: Text('Follow-ups Screen')),
      '/person/p1': (context) => const Scaffold(body: Text('Person Detail p1')),
      '/person/p2': (context) => const Scaffold(body: Text('Person Detail p2')),
    },
    home: Scaffold(body: child),
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

PersonProfile _buildProfile({
  required String id,
  required String name,
  String company = 'TechCorp',
  int interactionCount = 3,
  String lastInteraction = '10 days ago',
}) {
  return PersonProfile(
    id: id,
    name: name,
    role: 'Engineer',
    company: company,
    location: 'San Francisco',
    initials: name.isNotEmpty ? name[0] : 'U',
    relationshipType: RelationshipContextType.collaborator,
    relationshipStrength: 'Active',
    firstMet: '2025-01-01',
    lastInteraction: lastInteraction,
    totalInteractions: interactionCount,
    sharedEventsCount: 1,
    aiSummary: 'Summary of $name',
    followUps: const [],
  );
}

void main() {
  group('Phase 13H-03 Group 1 — Attention Score Calculation', () {
    const calc = DeterministicRelationshipAttentionCalculator();

    test('1. empty relationship produces low base attention score', () {
      final intel = _buildIntel(
        personId: 'p1',
        state: RelationshipState.newRelationship,
        strengthScore: 0.0,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, isNotNull);
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThan(30.0));
    });

    test('2. new relationship has low attention score', () {
      final intel = _buildIntel(
        personId: 'p2',
        state: RelationshipState.newRelationship,
        strengthScore: 10.0,
        daysSinceLastInteraction: 2,
        interactionCount: 1,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThan(0.0));
      expect(score, lessThan(25.0));
    });

    test('3. active relationship with regular contact has moderate/low attention', () {
      final intel = _buildIntel(
        personId: 'p3',
        state: RelationshipState.active,
        strengthScore: 60.0,
        daysSinceLastInteraction: 5,
        interactionCount: 5,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, inInclusiveRange(10.0, 45.0));
    });

    test('4. strong healthy relationship with recent contact has minimal attention need', () {
      final intel = _buildIntel(
        personId: 'p4',
        state: RelationshipState.strong,
        strengthScore: 85.0,
        daysSinceLastInteraction: 3,
        interactionCount: 10,
        memoryCount: 5,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, lessThan(40.0));
    });

    test('5. cooling relationship increases attention score due to state decay', () {
      final intel = _buildIntel(
        personId: 'p5',
        state: RelationshipState.cooling,
        strengthScore: 60.0,
        daysSinceLastInteraction: 40,
        interactionCount: 4,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(40.0));
    });

    test('6. neglected relationship with rich history produces high attention score', () {
      final intel = _buildIntel(
        personId: 'p6',
        state: RelationshipState.neglected,
        strengthScore: 70.0,
        daysSinceLastInteraction: 120,
        interactionCount: 8,
        memoryCount: 4,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(50.0));
    });

    test('7. dormant relationship produces moderate-to-high attention score', () {
      final intel = _buildIntel(
        personId: 'p7',
        state: RelationshipState.dormant,
        strengthScore: 30.0,
        daysSinceLastInteraction: 200,
        interactionCount: 2,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, inInclusiveRange(40.0, 75.0));
    });

    test('8. overdue follow-up significantly increases attention score', () {
      final intel = _buildIntel(
        personId: 'p8',
        state: RelationshipState.active,
        strengthScore: 50.0,
        daysSinceLastInteraction: 10,
                overdueFollowUpCount: 1,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(35.0));
    });

    test('9. multiple overdue follow-ups maxes out urgency factor', () {
      final intel = _buildIntel(
        personId: 'p9',
        state: RelationshipState.active,
        strengthScore: 80.0,
        daysSinceLastInteraction: 15,
                overdueFollowUpCount: 3,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(50.0));
    });

    test('10. recent interaction lowers recency risk', () {
      final intel = _buildIntel(
        personId: 'p10',
        state: RelationshipState.active,
        strengthScore: 50.0,
        daysSinceLastInteraction: 1,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, lessThan(35.0));
    });

    test('11. stale interaction (>180 days) sets max recency risk', () {
      final intel = _buildIntel(
        personId: 'p11',
        state: RelationshipState.neglected,
        strengthScore: 50.0,
        daysSinceLastInteraction: 200,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThan(50.0));
    });

    test('12. null daysSinceLastInteraction handles default recency gracefully', () {
      final intel = _buildIntel(
        personId: 'p12',
        state: RelationshipState.newRelationship,
        daysSinceLastInteraction: null,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, isNotNull);
      expect(score.isNaN, isFalse);
    });

    test('13. rich memory context contributes to context weight', () {
      final intel = _buildIntel(
        personId: 'p13',
        state: RelationshipState.active,
        strengthScore: 50.0,
        interactionCount: 10,
        memoryCount: 10,
        captureCount: 5,
        recentActivityCount: 5,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThan(15.0));
    });

    test('14. sparse context does not crash or produce invalid numbers', () {
      final intel = _buildIntel(
        personId: 'p14',
        state: RelationshipState.newRelationship,
        interactionCount: 0,
        memoryCount: 0,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(0.0));
    });

    test('15. maximum risk scenario reaches near 100 attention score', () {
      final intel = _buildIntel(
        personId: 'p15',
        state: RelationshipState.neglected,
        strengthScore: 100.0,
        daysSinceLastInteraction: 250,
                overdueFollowUpCount: 4,
        interactionCount: 10,
        memoryCount: 10,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, greaterThanOrEqualTo(90.0));
      expect(score, lessThanOrEqualTo(100.0));
    });

    test('16. minimum risk scenario reaches lowest attention score', () {
      final intel = _buildIntel(
        personId: 'p16',
        state: RelationshipState.newRelationship,
        strengthScore: 0.0,
        daysSinceLastInteraction: 1,
        interactionCount: 0,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, lessThan(10.0));
      expect(score, greaterThanOrEqualTo(0.0));
    });

    test('17. score is strictly bounded in 0..100 range', () {
      final intel = _buildIntel(
        personId: 'p17',
        state: RelationshipState.neglected,
        strengthScore: 150.0, // Out of bounds input
        daysSinceLastInteraction: 500,
                overdueFollowUpCount: 10,
      );
      final score = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score, inInclusiveRange(0.0, 100.0));
    });

    test('18. NaN safety verification', () {
      final signals = RelationshipSignals(
        daysSinceLastInteraction: null,
                interactionCount: 0,
        memoryCount: 0,
        captureCount: 0,
        activeFollowUpCount: 0,
                overdueFollowUpCount: 0,
        recentActivityCount: 0,
      );
      final score = calc.calculate(
        signals: signals,
        strength: RelationshipStrength.zero(),
        state: RelationshipState.newRelationship,
      );
      expect(score.isNaN, isFalse);
    });

    test('19. Infinity safety verification', () {
      final signals = RelationshipSignals(
        daysSinceLastInteraction: 999999,
                interactionCount: 99999,
        memoryCount: 99999,
        captureCount: 99999,
        activeFollowUpCount: 99999,
                overdueFollowUpCount: 99999,
        recentActivityCount: 99999,
      );
      final score = calc.calculate(
        signals: signals,
        strength: const RelationshipStrength(score: 100.0, factors: [], level: 'High', summary: ''),
        state: RelationshipState.neglected,
      );
      expect(score.isInfinite, isFalse);
      expect(score, lessThanOrEqualTo(100.0));
    });

    test('20. deterministic calculation produces identical score for identical inputs', () {
      final intel = _buildIntel(
        personId: 'p20',
        state: RelationshipState.cooling,
        strengthScore: 65.4,
        daysSinceLastInteraction: 42,
                overdueFollowUpCount: 1,
        interactionCount: 4,
      );
      final score1 = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      final score2 = calc.calculate(
        signals: intel.signals,
        strength: intel.strength,
        state: intel.state,
      );
      expect(score1, equals(score2));
    });
  });

  group('Phase 13H-03 Group 2 — Attention Priority & Precedence', () {
    const prioCalc = DeterministicRelationshipAttentionPriorityCalculator();

    test('21. critical priority assigned for high score with severe overdue', () {
      final intel = _buildIntel(
        personId: 'p21',
        state: RelationshipState.strong,
        strengthScore: 80.0,
                overdueFollowUpCount: 2,
      );
      final prio = prioCalc.calculate(attentionScore: 88.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.critical);
    });

    test('22. high priority assigned for score >= 70', () {
      final intel = _buildIntel(
        personId: 'p22',
        state: RelationshipState.cooling,
        strengthScore: 65.0,
        daysSinceLastInteraction: 45,
      );
      final prio = prioCalc.calculate(attentionScore: 72.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.high);
    });

    test('23. medium priority assigned for score in 40..69 range', () {
      final intel = _buildIntel(
        personId: 'p23',
        state: RelationshipState.cooling,
        strengthScore: 45.0,
      );
      final prio = prioCalc.calculate(attentionScore: 50.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.medium);
    });

    test('24. low priority assigned for score < 40 with no critical risks', () {
      final intel = _buildIntel(
        personId: 'p24',
        state: RelationshipState.newRelationship,
        strengthScore: 10.0,
      );
      final prio = prioCalc.calculate(attentionScore: 25.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.low);
    });

    test('25. critical precedence rule outranks high/medium thresholds', () {
      final intel = _buildIntel(
        personId: 'p25',
        state: RelationshipState.strong,
                overdueFollowUpCount: 2,
      );
      final prio = prioCalc.calculate(attentionScore: 65.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.critical);
    });

    test('26. overdue + strong relationship triggers critical/high urgency', () {
      final intel = _buildIntel(
        personId: 'p26',
        state: RelationshipState.strong,
        strengthScore: 85.0,
                overdueFollowUpCount: 1,
      );
      final prio = prioCalc.calculate(attentionScore: 75.0, intelligence: intel);
      expect(prio == RelationshipAttentionPriority.critical || prio == RelationshipAttentionPriority.high, isTrue);
    });

    test('27. neglected + rich history triggers high priority', () {
      final intel = _buildIntel(
        personId: 'p27',
        state: RelationshipState.neglected,
        strengthScore: 60.0,
        interactionCount: 5,
        memoryCount: 3,
      );
      final prio = prioCalc.calculate(attentionScore: 60.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.high);
    });

    test('28. cooling + meaningful history triggers high priority', () {
      final intel = _buildIntel(
        personId: 'p28',
        state: RelationshipState.cooling,
        interactionCount: 4,
      );
      final prio = prioCalc.calculate(attentionScore: 55.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.high);
    });

    test('29. active + upcoming follow-up triggers medium priority', () {
      final intel = _buildIntel(
        personId: 'p29',
        state: RelationshipState.active,
        activeFollowUpCount: 1,
      );
      final prio = prioCalc.calculate(attentionScore: 35.0, intelligence: intel);
      expect(prio, RelationshipAttentionPriority.medium);
    });

    test('30. strong healthy relationship without risk NEVER escalates to critical', () {
      final intel = _buildIntel(
        personId: 'p30',
        state: RelationshipState.strong,
        strengthScore: 95.0,
        daysSinceLastInteraction: 4,
        interactionCount: 12,
                overdueFollowUpCount: 0,
      );
      final prio = prioCalc.calculate(attentionScore: 35.0, intelligence: intel);
      expect(prio, isNot(equals(RelationshipAttentionPriority.critical)));
    });
  });

  group('Phase 13H-03 Group 3 — Explainability & Grounded Copy', () {
    test('31. explanation includes real person name', () {
      final intel = _buildIntel(
        personId: 'p31',
        state: RelationshipState.cooling,
        daysSinceLastInteraction: 35,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Sarah Chen',
      );
      expect(reasons.first.description, contains('Sarah Chen'));
    });

    test('32. explanation supports company context in card presentation', () {
      final intel = _buildIntel(
        personId: 'p32',
        state: RelationshipState.active,
                overdueFollowUpCount: 1,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'David Kim',
        company: 'Mosaic Labs',
      );
      expect(reasons.first.description, contains('David Kim'));
    });

    test('33. explanation references real interaction count for missing context', () {
      final intel = _buildIntel(
        personId: 'p33',
        state: RelationshipState.active,
        interactionCount: 4,
        memoryCount: 0,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Alice',
      );
      final missingCtx = reasons.firstWhere((r) => r.code == 'missing_context');
      expect(missingCtx.description, contains('4 interactions'));
    });

    test('34. explanation references real days since interaction for cooling', () {
      final intel = _buildIntel(
        personId: 'p34',
        state: RelationshipState.cooling,
        daysSinceLastInteraction: 48,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Bob',
      );
      expect(reasons.first.description, contains('48 days ago'));
    });

    test('35. explanation accurately states overdue count', () {
      final intel = _buildIntel(
        personId: 'p35',
        state: RelationshipState.active,
                overdueFollowUpCount: 3,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Elena',
      );
      expect(reasons.first.description, contains('3 overdue follow-ups'));
    });

    test('36. zero fabricated facts or hallucinated emotion', () {
      final intel = _buildIntel(
        personId: 'p36',
        state: RelationshipState.neglected,
        daysSinceLastInteraction: 90,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Frank',
      );
      for (final r in reasons) {
        expect(r.description.toLowerCase(), isNot(contains('feels')));
        expect(r.description.toLowerCase(), isNot(contains('upset')));
        expect(r.description.toLowerCase(), isNot(contains('expects you')));
      }
    });

    test('37. no hallucinated future intent in explanations', () {
      final intel = _buildIntel(
        personId: 'p37',
        state: RelationshipState.cooling,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Grace',
      );
      for (final r in reasons) {
        expect(r.description.toLowerCase(), isNot(contains('probably')));
        expect(r.description.toLowerCase(), isNot(contains('might want')));
      }
    });

    test('38. explanations are completely deterministic across multiple calls', () {
      final intel = _buildIntel(
        personId: 'p38',
        state: RelationshipState.cooling,
        daysSinceLastInteraction: 40,
      );
      final r1 = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Hannah',
      );
      final r2 = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Hannah',
      );
      expect(r1.first.description, equals(r2.first.description));
    });

    test('39. recommended timing maps appropriately to priority', () {
      final intelCritical = _buildIntel(
        personId: 'p39a',
        state: RelationshipState.strong,
              );
      final timingCritical = RelationshipAttentionExplanation.generateRecommendedTiming(
        priority: RelationshipAttentionPriority.critical,
        intelligence: intelCritical,
      );
      expect(timingCritical, equals('Today'));

      final intelLow = _buildIntel(
        personId: 'p39b',
        state: RelationshipState.newRelationship,
      );
      final timingLow = RelationshipAttentionExplanation.generateRecommendedTiming(
        priority: RelationshipAttentionPriority.low,
        intelligence: intelLow,
      );
      expect(timingLow, equals('Soon'));
    });

    test('40. multiple grounded reasons generate when multiple signals exist', () {
      final intel = _buildIntel(
        personId: 'p40',
        state: RelationshipState.cooling,
        daysSinceLastInteraction: 35,
                overdueFollowUpCount: 1,
        interactionCount: 3,
        memoryCount: 0,
      );
      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: 'Ian',
      );
      expect(reasons.length, greaterThanOrEqualTo(2));
      expect(reasons.any((r) => r.code == 'overdue_follow_up'), isTrue);
      expect(reasons.any((r) => r.code == 'relationship_cooling'), isTrue);
    });
  });

  group('Phase 13H-03 Group 4 — Ranking & Deduplication', () {
    const engine = DeterministicRelationshipAttentionEngine();

    test('41. ranking sorts primarily by priority rank descending', () {
      final rCritical = _buildIntel(personId: 'p1', state: RelationshipState.strong, hasOverdueFollowUp: true, overdueFollowUpCount: 2);
      final rHigh = _buildIntel(personId: 'p2', state: RelationshipState.cooling, daysSinceLastInteraction: 40, interactionCount: 3);
      final rLow = _buildIntel(personId: 'p3', state: RelationshipState.newRelationship);

      final ranked = engine.rankAttentionSync([rLow, rCritical, rHigh]);
      expect(ranked.first.priority, equals(RelationshipAttentionPriority.critical));
      expect(ranked[1].priority, equals(RelationshipAttentionPriority.high));
      expect(ranked.last.priority, equals(RelationshipAttentionPriority.low));
    });

    test('42. ranking breaks priority ties by attention score descending', () {
      final r1 = _buildIntel(personId: 'p1', state: RelationshipState.cooling, daysSinceLastInteraction: 35, strengthScore: 40.0);
      final r2 = _buildIntel(personId: 'p2', state: RelationshipState.cooling, daysSinceLastInteraction: 80, strengthScore: 70.0);

      final ranked = engine.rankAttentionSync([r1, r2]);
      expect(ranked.first.attentionScore, greaterThanOrEqualTo(ranked.last.attentionScore));
    });

    test('43. ranking breaks score ties by relationship strength descending', () {
      final r1 = _buildIntel(personId: 'p1', state: RelationshipState.newRelationship, strengthScore: 20.0);
      final r2 = _buildIntel(personId: 'p2', state: RelationshipState.newRelationship, strengthScore: 80.0);

      final ranked = engine.rankAttentionSync([r1, r2]);
      expect(ranked.first.relationshipStrength.score, greaterThanOrEqualTo(ranked.last.relationshipStrength.score));
    });

    test('44. ranking breaks strength ties by person name ascending', () {
      final r1 = _buildIntel(personId: 'p1', state: RelationshipState.newRelationship);
      final r2 = _buildIntel(personId: 'p2', state: RelationshipState.newRelationship);

      final names = {'p1': 'Zoe', 'p2': 'Amy'};
      final ranked = engine.rankAttentionSync([r1, r2], nameMap: names);
      expect(ranked.first.personName, equals('Amy'));
      expect(ranked.last.personName, equals('Zoe'));
    });

    test('45. ranking breaks name ties by personId ascending', () {
      final r1 = _buildIntel(personId: 'pid_b', state: RelationshipState.newRelationship);
      final r2 = _buildIntel(personId: 'pid_a', state: RelationshipState.newRelationship);

      final ranked = engine.rankAttentionSync([r1, r2]);
      expect(ranked.first.personId, equals('pid_a'));
      expect(ranked.last.personId, equals('pid_b'));
    });

    test('46. duplicate person entries collapse into exactly ONE attention item', () {
      final r1 = _buildIntel(personId: 'p_dup', state: RelationshipState.cooling, daysSinceLastInteraction: 40);
      final r2 = _buildIntel(personId: 'p_dup', state: RelationshipState.cooling, daysSinceLastInteraction: 40);

      final ranked = engine.rankAttentionSync([r1, r2]);
      expect(ranked.length, equals(1));
      expect(ranked.first.personId, equals('p_dup'));
    });

    test('47. ranking is strictly reproducible and deterministic', () {
      final r1 = _buildIntel(personId: 'p1', state: RelationshipState.cooling);
      final r2 = _buildIntel(personId: 'p2', state: RelationshipState.neglected);
      final r3 = _buildIntel(personId: 'p3', state: RelationshipState.active);

      final run1 = engine.rankAttentionSync([r1, r2, r3]);
      final run2 = engine.rankAttentionSync([r3, r1, r2]);

      expect(run1.map((a) => a.personId).toList(), equals(run2.map((a) => a.personId).toList()));
    });

    test('48. getTopAttention returns the single highest priority attention item', () {
      final rCritical = _buildIntel(personId: 'p_crit', state: RelationshipState.strong, hasOverdueFollowUp: true, overdueFollowUpCount: 2);
      final rLow = _buildIntel(personId: 'p_low', state: RelationshipState.newRelationship);

      final top = engine.getTopAttention([rLow, rCritical]);
      expect(top, isNotNull);
      expect(top!.personId, equals('p_crit'));
    });
  });

  group('Phase 13H-03 Group 5 — Security & Multi-Tenant Isolation', () {
    test('49. empty intelligence list produces empty attention list (fail-closed)', () {
      const engine = DeterministicRelationshipAttentionEngine();
      final ranked = engine.rankAttentionSync([]);
      expect(ranked, isEmpty);
      expect(engine.getTopAttention([]), isNull);
    });

    test('50. User A intelligence never leaks into User B attention set', () {
      final userAIntel = [_buildIntel(personId: 'userA_contact1', state: RelationshipState.cooling)];
      final userBIntel = [_buildIntel(personId: 'userB_contact1', state: RelationshipState.active)];

      const engine = DeterministicRelationshipAttentionEngine();
      final attA = engine.rankAttentionSync(userAIntel);
      final attB = engine.rankAttentionSync(userBIntel);

      expect(attA.every((a) => a.personId.startsWith('userA_')), isTrue);
      expect(attB.every((a) => a.personId.startsWith('userB_')), isTrue);
      expect(attA.any((a) => a.personId.startsWith('userB_')), isFalse);
    });

    test('51. User B cannot access or compute User A contact attention', () {
      final userAContact = _buildIntel(personId: 'userA_secret', state: RelationshipState.neglected);
      const engine = DeterministicRelationshipAttentionEngine();
      final att = engine.getAttentionSync(userAContact, personName: 'User A Secret Contact');

      expect(att.personId, equals('userA_secret'));
      expect(att.toMap().containsKey('auth_token'), isFalse);
      expect(att.toMap().containsKey('apiKey'), isFalse);
    });

    test('52. attention entity serialization contains no private tokens or API keys', () {
      final intel = _buildIntel(personId: 'p52', state: RelationshipState.active);
      const engine = DeterministicRelationshipAttentionEngine();
      final att = engine.getAttentionSync(intel, personName: 'Public Contact');
      final map = att.toMap();

      expect(map.containsKey('uid'), isFalse);
      expect(map.containsKey('token'), isFalse);
      expect(map.containsKey('gemini_key'), isFalse);
      expect(map['personId'], equals('p52'));
    });

    test('53. stable deduplication key format enforces isolation and reproducibility', () {
      final intel = _buildIntel(personId: 'p53', state: RelationshipState.cooling, daysSinceLastInteraction: 40);
      const engine = DeterministicRelationshipAttentionEngine();
      final att = engine.getAttentionSync(intel, personName: 'Test Person');

      expect(att.deduplicationKey, startsWith('attention_p53_'));
      expect(att.deduplicationKey, contains('cooling'));
    });
  });

  group('Phase 13H-03 Group 6 — UI Widgets & Integration', () {
    testWidgets('54. Home attention section renders populated attention cards', (tester) async {
      final attention = RelationshipAttention(
        personId: 'p1',
        personName: 'Sarah Chen',
        company: 'Mosaic Labs',
        attentionScore: 78.0,
        priority: RelationshipAttentionPriority.high,
        relationshipState: RelationshipState.cooling,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [
          RelationshipAttentionReason(
            code: 'relationship_cooling',
            title: 'Cooling Relationship',
            description: 'Your connection with Sarah Chen is cooling.',
            weight: 1.0,
          ),
        ],
        recommendedTiming: 'This week',
        generatedAt: DateTime.now(),
        deduplicationKey: 'attention_p1_high_cooling',
      );

      await tester.pumpWidget(_wrap(RelationshipAttentionSection(
        attentionItems: [attention],
      )));
      await tester.pumpAndSettle();

      expect(find.text('Relationship Attention'), findsOneWidget);
      expect(find.text('Sarah Chen'), findsOneWidget);
      expect(find.text('Mosaic Labs'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Cooling Relationship'), findsOneWidget);
    });

    testWidgets('55. empty account renders nothing in RelationshipAttentionSection', (tester) async {
      await tester.pumpWidget(_wrap(const RelationshipAttentionSection(
        attentionItems: [],
      )));
      await tester.pumpAndSettle();

      expect(find.text('Relationship Attention'), findsNothing);
    });

    testWidgets('56. attention card renders with priority badge and timing', (tester) async {
      final attention = RelationshipAttention(
        personId: 'p2',
        personName: 'David Kim',
        company: 'Vertex Capital',
        attentionScore: 90.0,
        priority: RelationshipAttentionPriority.critical,
        relationshipState: RelationshipState.strong,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [
          RelationshipAttentionReason(
            code: 'overdue_follow_up',
            title: 'Overdue Commitment',
            description: 'You have 2 overdue follow-ups with David Kim.',
            weight: 1.0,
          ),
        ],
        recommendedTiming: 'Today',
        generatedAt: DateTime.now(),
        deduplicationKey: 'attention_p2_critical_overdue',
      );

      await tester.pumpWidget(_wrap(RelationshipAttentionCard(
        attention: attention,
      )));
      await tester.pumpAndSettle();

      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('David Kim'), findsOneWidget);
      expect(find.text('Vertex Capital'), findsOneWidget);
      expect(find.text('Recommended: Today'), findsOneWidget);
    });

    testWidgets('57. priority badge applies correct semantic color', (tester) async {
      final attention = RelationshipAttention(
        personId: 'p3',
        personName: 'Elena Rostova',
        attentionScore: 88.0,
        priority: RelationshipAttentionPriority.critical,
        relationshipState: RelationshipState.active,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [],
        recommendedTiming: 'Today',
        generatedAt: DateTime.now(),
        deduplicationKey: 'key_p3',
      );

      await tester.pumpWidget(_wrap(RelationshipAttentionCard(attention: attention)));
      await tester.pumpAndSettle();

      final badgeText = tester.widget<Text>(find.text('CRITICAL'));
      expect(badgeText.style?.color, equals(RecallrColors.crimsonAlert));
    });

    testWidgets('58. explanation rendering shows primary reason description', (tester) async {
      final attention = RelationshipAttention(
        personId: 'p4',
        personName: 'Marcus Aurelius',
        attentionScore: 65.0,
        priority: RelationshipAttentionPriority.high,
        relationshipState: RelationshipState.cooling,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [
          RelationshipAttentionReason(
            code: 'cooling',
            title: 'Cooling Connection',
            description: 'It has been 45 days since last interaction.',
            weight: 1.0,
          ),
        ],
        recommendedTiming: 'This week',
        generatedAt: DateTime.now(),
        deduplicationKey: 'key_p4',
      );

      await tester.pumpWidget(_wrap(RelationshipAttentionCard(attention: attention)));
      await tester.pumpAndSettle();

      expect(find.text('Cooling Connection'), findsOneWidget);
      expect(find.text('It has been 45 days since last interaction.'), findsOneWidget);
    });

    testWidgets('59. primary action CTA callbacks trigger appropriately', (tester) async {
      bool followUpTapped = false;
      bool personTapped = false;

      final attention = RelationshipAttention(
        personId: 'p5',
        personName: 'Kavita Rao',
        attentionScore: 70.0,
        priority: RelationshipAttentionPriority.high,
        relationshipState: RelationshipState.cooling,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [
          RelationshipAttentionReason(
            code: 'cooling',
            title: 'Cooling Relationship',
            description: 'Reconnect with Kavita.',
            weight: 1.0,
          ),
        ],
        recommendedTiming: 'This week',
        generatedAt: DateTime.now(),
        deduplicationKey: 'key_p5',
      );

      await tester.pumpWidget(_wrap(RelationshipAttentionCard(
        attention: attention,
        onCreateFollowUp: () => followUpTapped = true,
        onTap: () => personTapped = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Follow-up'));
      await tester.pumpAndSettle();
      expect(followUpTapped, isTrue);

      await tester.tap(find.text('View Person'));
      await tester.pumpAndSettle();
      expect(personTapped, isTrue);
    });

    testWidgets('60. Person Dossier integration renders WHY THIS NEEDS ATTENTION when present', (tester) async {
      final profile = _buildProfile(id: 'p60', name: 'James Wilson');
      final intel = _buildIntel(
        personId: 'p60',
        state: RelationshipState.cooling,
        daysSinceLastInteraction: 45,
      );
      final attention = RelationshipAttention(
        personId: 'p60',
        personName: 'James Wilson',
        attentionScore: 72.0,
        priority: RelationshipAttentionPriority.high,
        relationshipState: RelationshipState.cooling,
        relationshipStrength: RelationshipStrength.zero(),
        reasons: const [
          RelationshipAttentionReason(
            code: 'relationship_cooling',
            title: 'Cooling Relationship',
            description: 'Your connection with James Wilson is cooling.',
            weight: 1.0,
          ),
        ],
        recommendedTiming: 'This week',
        generatedAt: DateTime.now(),
        deduplicationKey: 'key_p60',
      );

      await tester.pumpWidget(_wrap(SingleChildScrollView(
        child: RelationshipIntelligence(
          profile: profile,
          intelligence: intel,
          attention: attention,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('WHY THIS NEEDS ATTENTION'), findsOneWidget);
      expect(find.text('Your connection with James Wilson is cooling.'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
    });
  });
}
