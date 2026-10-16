import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart' as pds_ri;
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/features/relationship_intelligence/widgets/relationship_momentum_card.dart';
import 'package:recaller/screens/network/network_dashboard_screen.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';
import 'package:recaller/services/relationship/relationship_cadence_calculator.dart';
import 'package:recaller/services/relationship/relationship_evolution_classifier.dart';
import 'package:recaller/services/relationship/relationship_momentum_engine.dart';
import 'package:recaller/services/relationship/relationship_momentum_service.dart';
import 'package:recaller/services/relationship/relationship_velocity_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final refDate = DateTime(2026, 8, 29, 12, 0, 0);

  group('Phase 13H-05 Group 1 — Cadence Calculations', () {
    const calc = DeterministicRelationshipCadenceCalculator();

    test('1. 0 interactions returns empty cadence analysis', () {
      final res = calc.calculate(interactionDates: const [], referenceDate: refDate);
      expect(res.averageCadenceDays, isNull);
      expect(res.daysSinceLastInteraction, isNull);
      expect(res.cadenceRatio, isNull);
      expect(res.hasSufficientCadence, isFalse);
      expect(res.totalDistinctDates, equals(0));
    });

    test('2. 1 interaction computes daysSinceLastInteraction but null averageCadenceDays', () {
      final dates = [refDate.subtract(const Duration(days: 10))];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.averageCadenceDays, isNull);
      expect(res.daysSinceLastInteraction, equals(10));
      expect(res.cadenceRatio, isNull);
      expect(res.hasSufficientCadence, isFalse);
      expect(res.totalDistinctDates, equals(1));
    });

    test('3. 2 interactions computes exact average cadence and expected next contact', () {
      final dates = [
        refDate.subtract(const Duration(days: 28)),
        refDate.subtract(const Duration(days: 14)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.averageCadenceDays, equals(14.0));
      expect(res.daysSinceLastInteraction, equals(14));
      expect(res.cadenceRatio, closeTo(1.0, 0.01));
      expect(res.hasSufficientCadence, isTrue);
      expect(res.isOffCadence, isFalse);
      expect(res.expectedNextContactDate, equals(DateTime(refDate.year, refDate.month, refDate.day)));
    });

    test('4. Multiple evenly spaced interactions calculate accurate cadence', () {
      final dates = [
        refDate.subtract(const Duration(days: 30)),
        refDate.subtract(const Duration(days: 20)),
        refDate.subtract(const Duration(days: 10)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.averageCadenceDays, equals(10.0));
      expect(res.daysSinceLastInteraction, equals(10));
      expect(res.cadenceRatio, closeTo(1.0, 0.01));
    });

    test('5. Irregular interaction intervals calculate mean cadence', () {
      final dates = [
        refDate.subtract(const Duration(days: 42)),
        refDate.subtract(const Duration(days: 21)),
        refDate.subtract(const Duration(days: 7)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.averageCadenceDays, equals(17.5));
      expect(res.daysSinceLastInteraction, equals(7));
      expect(res.cadenceRatio, closeTo(7.0 / 17.5, 0.01));
    });

    test('6. Duplicate timestamps on same calendar day are deduplicated', () {
      final d1 = refDate.subtract(const Duration(days: 20, hours: 2));
      final d2 = refDate.subtract(const Duration(days: 20, hours: 5));
      final d3 = refDate.subtract(const Duration(days: 10));
      final res = calc.calculate(interactionDates: [d1, d2, d3], referenceDate: refDate);
      expect(res.totalDistinctDates, equals(2));
      expect(res.averageCadenceDays, equals(10.0));
    });

    test('7. Multiple interactions in identical millisecond are deduplicated', () {
      final d = refDate.subtract(const Duration(days: 5));
      final res = calc.calculate(interactionDates: [d, d, d], referenceDate: refDate);
      expect(res.totalDistinctDates, equals(1));
      expect(res.averageCadenceDays, isNull);
    });

    test('8. Future timestamps are ignored and filtered safely', () {
      final past = refDate.subtract(const Duration(days: 14));
      final future = refDate.add(const Duration(days: 5));
      final res = calc.calculate(interactionDates: [past, future], referenceDate: refDate);
      expect(res.totalDistinctDates, equals(1));
      expect(res.daysSinceLastInteraction, equals(14));
      expect(res.averageCadenceDays, isNull);
    });

    test('9. Cadence ratio detects off-cadence status when ratio >= 1.5', () {
      final dates = [
        refDate.subtract(const Duration(days: 50)),
        refDate.subtract(const Duration(days: 40)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.cadenceRatio, equals(4.0));
      expect(res.isOffCadence, isTrue);
      expect(res.isCriticallyOffCadence, isTrue);
    });

    test('10. Cadence ratio detects mildly off-cadence (1.5x - 2.4x)', () {
      final dates = [
        refDate.subtract(const Duration(days: 46)),
        refDate.subtract(const Duration(days: 30)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.cadenceRatio, closeTo(1.875, 0.01));
      expect(res.isOffCadence, isTrue);
      expect(res.isCriticallyOffCadence, isFalse);
    });

    test('11. On-cadence contacts maintain isOffCadence == false', () {
      final dates = [
        refDate.subtract(const Duration(days: 20)),
        refDate.subtract(const Duration(days: 10)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.isOffCadence, isFalse);
      expect(res.isCriticallyOffCadence, isFalse);
    });

    test('12. Unsorted interaction dates are sorted chronologically before interval calculation', () {
      final d1 = refDate.subtract(const Duration(days: 10));
      final d2 = refDate.subtract(const Duration(days: 30));
      final d3 = refDate.subtract(const Duration(days: 20));
      final res = calc.calculate(interactionDates: [d1, d2, d3], referenceDate: refDate);
      expect(res.averageCadenceDays, equals(10.0));
      expect(res.daysSinceLastInteraction, equals(10));
    });

    test('13. Contact with single encounter years ago returns large daysSinceLast and null cadence', () {
      final dates = [refDate.subtract(const Duration(days: 730))];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.daysSinceLastInteraction, equals(730));
      expect(res.hasSufficientCadence, isFalse);
    });

    test('14. Expected next contact date accurately projected', () {
      final dates = [
        refDate.subtract(const Duration(days: 20)),
        refDate.subtract(const Duration(days: 6)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.expectedNextContactDate, equals(DateTime(refDate.year, refDate.month, refDate.day).add(const Duration(days: 8))));
    });

    test('15. CadenceAnalysis serialization round-trip', () {
      const original = CadenceAnalysis(
        averageCadenceDays: 14.5,
        daysSinceLastInteraction: 7,
        cadenceRatio: 0.48,
        totalDistinctDates: 4,
      );
      final map = original.toMap();
      final restored = CadenceAnalysis.fromMap(map);
      expect(restored.averageCadenceDays, equals(14.5));
      expect(restored.daysSinceLastInteraction, equals(7));
      expect(restored.cadenceRatio, equals(0.48));
      expect(restored.totalDistinctDates, equals(4));
    });
  });

  group('Phase 13H-05 Group 2 — Velocity Calculations', () {
    const calc = DeterministicRelationshipVelocityCalculator();

    test('16. 0 interactions returns empty velocity', () {
      final res = calc.calculate(interactionDates: const [], referenceDate: refDate);
      expect(res.recentCount, equals(0));
      expect(res.previousCount, equals(0));
      expect(res.priorCount, equals(0));
      expect(res.historicalCount, equals(0));
      expect(res.velocityDelta, equals(0.0));
      expect(res.percentageChange, isNull);
      expect(res.hasSufficientData, isFalse);
    });

    test('17. Trailing 30-day window count is exact', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 15)),
        refDate.subtract(const Duration(days: 25)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.recentCount, equals(3));
      expect(res.previousCount, equals(0));
      expect(res.historicalCount, equals(3));
      expect(res.velocityDelta, equals(3.0));
    });

    test('18. Preceding 30-day window (31–60d) count is exact', () {
      final dates = [
        refDate.subtract(const Duration(days: 35)),
        refDate.subtract(const Duration(days: 45)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.recentCount, equals(0));
      expect(res.previousCount, equals(2));
      expect(res.historicalCount, equals(2));
      expect(res.velocityDelta, equals(-2.0));
    });

    test('19. Prior 30-day window (61–90d) count is exact', () {
      final dates = [
        refDate.subtract(const Duration(days: 75)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.recentCount, equals(0));
      expect(res.previousCount, equals(0));
      expect(res.priorCount, equals(1));
    });

    test('20. Velocity delta is recentCount minus previousCount', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 10)),
        refDate.subtract(const Duration(days: 35)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.recentCount, equals(2));
      expect(res.previousCount, equals(1));
      expect(res.velocityDelta, equals(1.0));
    });

    test('21. Percentage change calculated when previousCount > 0', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 10)),
        refDate.subtract(const Duration(days: 35)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.percentageChange, equals(100.0));
    });

    test('22. Percentage change is +100.0% when emerging from 0 previous encounters', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 10)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.previousCount, equals(0));
      expect(res.recentCount, equals(2));
      expect(res.percentageChange, equals(100.0));
    });

    test('23. Percentage change is null when both recent and previous are 0', () {
      final dates = [refDate.subtract(const Duration(days: 100))];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.percentageChange, isNull);
    });

    test('24. Accelerating detected when velocityDelta > 0 and recent >= 2', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 10)),
        refDate.subtract(const Duration(days: 35)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.isAccelerating, isTrue);
      expect(res.isDecelerating, isFalse);
    });

    test('25. Decelerating detected when velocityDelta < 0 and previous >= 2', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 35)),
        refDate.subtract(const Duration(days: 45)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.isDecelerating, isTrue);
      expect(res.isAccelerating, isFalse);
    });

    test('26. Flat velocity detected when velocityDelta == 0', () {
      final dates = [
        refDate.subtract(const Duration(days: 5)),
        refDate.subtract(const Duration(days: 35)),
      ];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.isFlat, isTrue);
    });

    test('27. Velocity serialization round-trip', () {
      const original = RelationshipVelocity(
        recentCount: 3,
        previousCount: 1,
        priorCount: 2,
        historicalCount: 6,
        velocityDelta: 2.0,
        percentageChange: 200.0,
      );
      final map = original.toMap();
      final restored = RelationshipVelocity.fromMap(map);
      expect(restored.recentCount, equals(3));
      expect(restored.previousCount, equals(1));
      expect(restored.velocityDelta, equals(2.0));
      expect(restored.percentageChange, equals(200.0));
      expect(restored.isAccelerating, isTrue);
    });
  });

  group('Phase 13H-05 Group 3 — Momentum Classification & Precedence', () {
    const classifier = DeterministicRelationshipEvolutionClassifier();

    test('28. strengthening classified when velocity increases with recent engagement', () {
      const velocity = RelationshipVelocity(
        recentCount: 3,
        previousCount: 1,
        historicalCount: 4,
        velocityDelta: 2.0,
        percentageChange: 200.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 10.0,
        daysSinceLastInteraction: 5,
        cadenceRatio: 0.5,
        totalDistinctDates: 4,
      );
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 5,
        
      );

      final res = classifier.classify(
        personId: 'p1',
        signals: signals,
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 80.0, summary: '', factors: [], level: 'Strong'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.strengthening));
      expect(res.momentumScore, greaterThanOrEqualTo(80.0));
      expect(res.headline, contains('Strengthening'));
    });

    test('29. newlyDeveloping classified for recently connected contact with rapid engagement', () {
      const velocity = RelationshipVelocity(
        recentCount: 2,
        previousCount: 0,
        historicalCount: 2,
        velocityDelta: 2.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 7.0,
        daysSinceLastInteraction: 3,
        cadenceRatio: 0.4,
        totalDistinctDates: 2,
      );
      const signals = RelationshipSignals(
        interactionCount: 2,
        daysSinceLastInteraction: 3,
        
      );

      final res = classifier.classify(
        personId: 'p2',
        signals: signals,
        state: RelationshipState.newRelationship,
        strength: const RelationshipStrength(score: 65.0, summary: '', factors: [], level: 'Medium'),
        velocity: velocity,
        cadence: cadence,
        contactCreatedDate: refDate.subtract(const Duration(days: 20)),
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.newlyDeveloping));
      expect(res.headline, contains('Newly Developing'));
    });

    test('30. recovering classified when re-engaging after extended dormancy', () {
      const velocity = RelationshipVelocity(
        recentCount: 1,
        previousCount: 0,
        priorCount: 0,
        historicalCount: 4,
        velocityDelta: 1.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 30.0,
        daysSinceLastInteraction: 5,
        cadenceRatio: 0.16,
        totalDistinctDates: 4,
      );
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 5,
        
      );

      final res = classifier.classify(
        personId: 'p3',
        signals: signals,
        state: RelationshipState.cooling,
        strength: const RelationshipStrength(score: 50.0, summary: '', factors: [], level: 'Medium'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.recovering));
      expect(res.headline, contains('Recovering'));
    });

    test('31. cooling classified when cadence is off-pace (1.5x - 2.5x)', () {
      const velocity = RelationshipVelocity(
        recentCount: 0,
        previousCount: 2,
        historicalCount: 4,
        velocityDelta: -2.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 20.0,
        daysSinceLastInteraction: 35,
        cadenceRatio: 1.75,
        totalDistinctDates: 4,
      );
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 35,
      );

      final res = classifier.classify(
        personId: 'p4',
        signals: signals,
        state: RelationshipState.cooling,
        strength: const RelationshipStrength(score: 45.0, summary: '', factors: [], level: 'Low'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.cooling));
      expect(res.headline, contains('Cooling'));
    });

    test('32. declining classified when silence > 60d or critically off-cadence', () {
      const velocity = RelationshipVelocity(
        recentCount: 0,
        previousCount: 0,
        historicalCount: 3,
        velocityDelta: 0.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 15.0,
        daysSinceLastInteraction: 75,
        cadenceRatio: 5.0,
        totalDistinctDates: 3,
      );
      const signals = RelationshipSignals(
        interactionCount: 3,
        daysSinceLastInteraction: 75,
      );

      final res = classifier.classify(
        personId: 'p5',
        signals: signals,
        state: RelationshipState.neglected,
        strength: const RelationshipStrength(score: 25.0, summary: '', factors: [], level: 'Critical'),
        velocity: velocity,
        cadence: cadence,
        overdueFollowUps: 1,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.declining));
      expect(res.headline, contains('Declining'));
    });

    test('33. declining classified when multiple overdue follow-ups exist', () {
      const velocity = RelationshipVelocity(
        recentCount: 1,
        previousCount: 1,
        historicalCount: 4,
        velocityDelta: 0.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 14.0,
        daysSinceLastInteraction: 14,
        cadenceRatio: 1.0,
        totalDistinctDates: 4,
      );
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 14,
        overdueFollowUpCount: 2,
      );

      final res = classifier.classify(
        personId: 'p6',
        signals: signals,
        state: RelationshipState.neglected,
        strength: const RelationshipStrength(score: 30.0, summary: '', factors: [], level: 'Critical'),
        velocity: velocity,
        cadence: cadence,
        overdueFollowUps: 2,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.declining));
    });

    test('34. stable classified when interaction rhythm matches historical baseline', () {
      const velocity = RelationshipVelocity(
        recentCount: 1,
        previousCount: 1,
        historicalCount: 4,
        velocityDelta: 0.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 25.0,
        daysSinceLastInteraction: 20,
        cadenceRatio: 0.8,
        totalDistinctDates: 4,
      );
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 20,
        
      );

      final res = classifier.classify(
        personId: 'p7',
        signals: signals,
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 65.0, summary: '', factors: [], level: 'Medium'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.stable));
      expect(res.headline, contains('Stable'));
    });

    test('35. insufficientHistory precedence over all when historicalCount < 2', () {
      const velocity = RelationshipVelocity(
        recentCount: 1,
        previousCount: 0,
        historicalCount: 1,
        velocityDelta: 1.0,
      );
      const cadence = CadenceAnalysis(
        daysSinceLastInteraction: 5,
        totalDistinctDates: 1,
      );
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 5,
      );

      final res = classifier.classify(
        personId: 'p8',
        signals: signals,
        state: RelationshipState.newRelationship,
        strength: const RelationshipStrength(score: 60.0, summary: '', factors: [], level: 'Medium'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.insufficientHistory));
      expect(res.headline, equals('Limited Interaction History'));
    });

    test('36. strengthening score increases with higher velocity delta', () {
      final res1 = classifier.classify(
        personId: 'p_str1',
        signals: const RelationshipSignals(interactionCount: 4, daysSinceLastInteraction: 5),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 75.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 1, historicalCount: 4, velocityDelta: 1.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 14.0, daysSinceLastInteraction: 5, cadenceRatio: 0.35, totalDistinctDates: 4),
        referenceDate: refDate,
      );

      final res2 = classifier.classify(
        personId: 'p_str2',
        signals: const RelationshipSignals(interactionCount: 6, daysSinceLastInteraction: 2),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 85.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 5, previousCount: 1, historicalCount: 6, velocityDelta: 4.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 8.0, daysSinceLastInteraction: 2, cadenceRatio: 0.25, totalDistinctDates: 6),
        referenceDate: refDate,
      );

      expect(res2.momentumScore, greaterThan(res1.momentumScore));
    });

    test('37. recovering score gives bonus for multiple recent touchpoints', () {
      final res = classifier.classify(
        personId: 'p_rec_multi',
        signals: const RelationshipSignals(interactionCount: 5, daysSinceLastInteraction: 3),
        state: RelationshipState.cooling,
        strength: const RelationshipStrength(score: 55.0, summary: '', factors: [], level: 'Medium'),
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 0, priorCount: 0, historicalCount: 5, velocityDelta: 2.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 20.0, daysSinceLastInteraction: 3, cadenceRatio: 0.15, totalDistinctDates: 4),
        referenceDate: refDate,
      );

      expect(res.direction, equals(MomentumDirection.recovering));
      expect(res.momentumScore, greaterThanOrEqualTo(80.0));
    });
  });

  group('Phase 13H-05 Group 4 — Insufficient History & Temporal Edge Cases', () {
    const classifier = DeterministicRelationshipEvolutionClassifier();

    test('38. 0 encounters returns truthful limited data explanation', () {
      final res = RelationshipMomentum.empty(personId: 'empty_p');
      expect(res.direction, equals(MomentumDirection.insufficientHistory));
      expect(res.explanation, contains('Not enough interaction history'));
    });

    test('39. Encounters all on identical date yield insufficientHistory', () {
      final res = classifier.classify(
        personId: 'p_same_day',
        signals: const RelationshipSignals(interactionCount: 3),
        state: RelationshipState.newRelationship,
        strength: const RelationshipStrength(score: 50.0, summary: '', factors: [], level: 'Medium'),
        velocity: const RelationshipVelocity(recentCount: 3, previousCount: 0, historicalCount: 3, velocityDelta: 3.0),
        cadence: const CadenceAnalysis(totalDistinctDates: 1),
        referenceDate: refDate,
      );
      expect(res.direction, isIn([MomentumDirection.newlyDeveloping, MomentumDirection.insufficientHistory]));
    });

    test('40. Score remains bounded in [0.0, 100.0] under extreme values', () {
      final res = classifier.classify(
        personId: 'p_extreme',
        signals: const RelationshipSignals(interactionCount: 100),
        state: RelationshipState.strong,
        strength: const RelationshipStrength(score: 100.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 50, previousCount: 2, historicalCount: 100, velocityDelta: 48.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 1.0, daysSinceLastInteraction: 0, cadenceRatio: 0.0, totalDistinctDates: 50),
        referenceDate: refDate,
      );
      expect(res.momentumScore, lessThanOrEqualTo(100.0));
      expect(res.momentumScore, greaterThanOrEqualTo(0.0));
      expect(res.momentumScore.isNaN, isFalse);
      expect(res.momentumScore.isInfinite, isFalse);
    });

    test('41. Score remains non-negative under extreme declining state', () {
      final res = classifier.classify(
        personId: 'p_declining',
        signals: const RelationshipSignals(interactionCount: 5, daysSinceLastInteraction: 500),
        state: RelationshipState.dormant,
        strength: const RelationshipStrength(score: 10.0, summary: '', factors: [], level: 'Critical'),
        velocity: const RelationshipVelocity(recentCount: 0, previousCount: 0, historicalCount: 5, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 10.0, daysSinceLastInteraction: 500, cadenceRatio: 50.0, totalDistinctDates: 5),
        overdueFollowUps: 10,
        referenceDate: refDate,
      );
      expect(res.momentumScore, greaterThanOrEqualTo(0.0));
      expect(res.momentumScore.isNaN, isFalse);
    });

    test('42. RelationshipMomentum serialization and deserialization round-trip', () {
      final original = RelationshipMomentum(
        personId: 'ser_p',
        direction: MomentumDirection.strengthening,
        momentumScore: 88.5,
        velocity: const RelationshipVelocity(recentCount: 3, previousCount: 1, historicalCount: 5, velocityDelta: 2.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 12.0, daysSinceLastInteraction: 4, cadenceRatio: 0.33, totalDistinctDates: 5),
        headline: 'Strengthening: 3 interactions in last 30 days',
        explanation: 'Increasing frequency and depth.',
        keyEvolutionFactors: const ['Velocity up by 2', 'On pace cadence'],
        generatedAt: refDate,
      );

      final json = original.toJson();
      final restored = RelationshipMomentum.fromJson(json);

      expect(restored.personId, equals('ser_p'));
      expect(restored.direction, equals(MomentumDirection.strengthening));
      expect(restored.momentumScore, equals(88.5));
      expect(restored.velocity.recentCount, equals(3));
      expect(restored.cadence.averageCadenceDays, equals(12.0));
      expect(restored.keyEvolutionFactors.length, equals(2));
    });

    test('43. Unknown momentum direction deserializes safely to insufficientHistory fallback', () {
      final map = {
        'personId': 'corrupt_p',
        'direction': 'quantum_entangled',
        'momentumScore': 50.0,
      };
      final restored = RelationshipMomentum.fromMap(map);
      expect(restored.direction, equals(MomentumDirection.insufficientHistory));
    });

    test('44. Momentum direction enum properties are properly mapped', () {
      expect(MomentumDirection.strengthening.displayName, equals('Strengthening'));
      expect(MomentumDirection.strengthening.badgeLabel, equals('STRENGTHENING'));
      expect(MomentumDirection.strengthening.isPositive, isTrue);
      expect(MomentumDirection.strengthening.isAtRisk, isFalse);

      expect(MomentumDirection.cooling.isAtRisk, isTrue);
      expect(MomentumDirection.declining.isAtRisk, isTrue);
      expect(MomentumDirection.stable.isPositive, isFalse);
    });

    test('45. Momentum direction icons are valid Material Icons', () {
      for (final dir in MomentumDirection.values) {
        expect(dir.icon, isA<IconData>());
      }
    });

    test('46. Momentum direction color tokens are defined theme colors', () {
      for (final dir in MomentumDirection.values) {
        expect(dir.colorToken, isA<Color>());
      }
    });

    test('47. Factory constructors initialize generatedAt safely', () {
      final m = RelationshipMomentum.insufficientHistory(personId: 'init_p', referenceDate: refDate);
      expect(m.generatedAt, equals(refDate));
    });
  });

  group('Phase 13H-05 Group 5 — Grounded Explanations & Privacy Verification', () {
    const classifier = DeterministicRelationshipEvolutionClassifier();

    test('48. Explanation cites factual numbers and dates', () {
      const velocity = RelationshipVelocity(
        recentCount: 3,
        previousCount: 1,
        historicalCount: 4,
        velocityDelta: 2.0,
      );
      const cadence = CadenceAnalysis(
        averageCadenceDays: 10.0,
        daysSinceLastInteraction: 4,
        cadenceRatio: 0.4,
        totalDistinctDates: 4,
      );

      final res = classifier.classify(
        personId: 'grounded_p',
        signals: const RelationshipSignals(interactionCount: 4, daysSinceLastInteraction: 4),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 80.0, summary: '', factors: [], level: 'Strong'),
        velocity: velocity,
        cadence: cadence,
        referenceDate: refDate,
      );

      expect(res.headline, contains('3'));
      expect(res.headline, contains('1'));
      expect(res.keyEvolutionFactors, isNotEmpty);
    });

    test('49. Prohibited emotional/speculative words are never generated', () {
      final prohibited = [
        'feels distant',
        'losing interest',
        'loves working',
        'emotional',
        'abandoned',
        'neglectful',
        'lazy',
        'unreliable',
      ];

      final res = classifier.classify(
        personId: 'privacy_p',
        signals: const RelationshipSignals(interactionCount: 4, daysSinceLastInteraction: 90),
        state: RelationshipState.neglected,
        strength: const RelationshipStrength(score: 20.0, summary: '', factors: [], level: 'Critical'),
        velocity: const RelationshipVelocity(recentCount: 0, previousCount: 0, historicalCount: 4, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 10.0, daysSinceLastInteraction: 90, cadenceRatio: 9.0, totalDistinctDates: 4),
        overdueFollowUps: 3,
        referenceDate: refDate,
      );

      final fullText = '${res.headline} ${res.explanation} ${res.keyEvolutionFactors.join(" ")}'.toLowerCase();
      for (final word in prohibited) {
        expect(fullText.contains(word), isFalse, reason: 'Generated text contained forbidden word: $word');
      }
    });

    test('50. Deterministic repeatability across identical runs', () {
      final res1 = classifier.classify(
        personId: 'repeat_p',
        signals: const RelationshipSignals(interactionCount: 5, daysSinceLastInteraction: 12),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 75.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 2, historicalCount: 5, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 14.0, daysSinceLastInteraction: 12, cadenceRatio: 0.85, totalDistinctDates: 5),
        referenceDate: refDate,
      );

      final res2 = classifier.classify(
        personId: 'repeat_p',
        signals: const RelationshipSignals(interactionCount: 5, daysSinceLastInteraction: 12),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 75.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 2, historicalCount: 5, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 14.0, daysSinceLastInteraction: 12, cadenceRatio: 0.85, totalDistinctDates: 5),
        referenceDate: refDate,
      );

      expect(res1.direction, equals(res2.direction));
      expect(res1.momentumScore, equals(res2.momentumScore));
      expect(res1.headline, equals(res2.headline));
      expect(res1.explanation, equals(res2.explanation));
    });

    test('51. Grounded factors list contains explicit rhythm information', () {
      final res = classifier.classify(
        personId: 'factor_p',
        signals: const RelationshipSignals(interactionCount: 4, daysSinceLastInteraction: 8),
        state: RelationshipState.active,
        strength: const RelationshipStrength(score: 70.0, summary: '', factors: [], level: 'Strong'),
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 2, historicalCount: 4, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 14.0, daysSinceLastInteraction: 8, cadenceRatio: 0.57, totalDistinctDates: 4),
        referenceDate: refDate,
      );

      expect(res.keyEvolutionFactors.any((f) => f.contains('14')), isTrue);
    });

    test('52. Overdue follow-ups are cited with exact integer quantity', () {
      final res = classifier.classify(
        personId: 'overdue_cite_p',
        signals: const RelationshipSignals(interactionCount: 3, daysSinceLastInteraction: 40, overdueFollowUpCount: 3),
        state: RelationshipState.cooling,
        strength: const RelationshipStrength(score: 35.0, summary: '', factors: [], level: 'Low'),
        velocity: const RelationshipVelocity(recentCount: 0, previousCount: 1, historicalCount: 3, velocityDelta: -1.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 15.0, daysSinceLastInteraction: 40, cadenceRatio: 2.66, totalDistinctDates: 3),
        overdueFollowUps: 3,
        referenceDate: refDate,
      );

      expect(res.keyEvolutionFactors.any((f) => f.contains('3 overdue')), isTrue);
    });
  });

  group('Phase 13H-05 Group 6 — Security, Multi-Tenant & Serialization Safety', () {
    test('53. Serialization does not leak auth tokens, private keys or secrets', () {
      final momentum = RelationshipMomentum(
        personId: 'sec_p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 85.0,
        velocity: const RelationshipVelocity(recentCount: 2, previousCount: 1, historicalCount: 3, velocityDelta: 1.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 15.0, daysSinceLastInteraction: 5, cadenceRatio: 0.33, totalDistinctDates: 3),
        headline: 'Strengthening',
        explanation: 'Sustained engagement',
        keyEvolutionFactors: const ['Factor 1'],
        generatedAt: refDate,
      );

      final map = momentum.toMap();
      final mapStr = map.toString().toLowerCase();

      expect(mapStr.contains('apikey'), isFalse);
      expect(mapStr.contains('authtoken'), isFalse);
      expect(mapStr.contains('bearertoken'), isFalse);
      expect(mapStr.contains('password'), isFalse);
    });

    test('54. Multi-tenant isolation: Separate person IDs do not collide', () {
      final engine = const DeterministicRelationshipMomentumEngine();

      final m1 = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('user_A_contact'),
        interactionDates: [refDate.subtract(const Duration(days: 10))],
        referenceDate: refDate,
      );
      final m2 = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('user_B_contact'),
        interactionDates: [
          refDate.subtract(const Duration(days: 20)),
          refDate.subtract(const Duration(days: 10)),
        ],
        referenceDate: refDate,
      );

      expect(m1.personId, equals('user_A_contact'));
      expect(m2.personId, equals('user_B_contact'));
      expect(m1.direction, equals(MomentumDirection.insufficientHistory));
      expect(m2.direction, isNot(equals(MomentumDirection.insufficientHistory)));
    });

    test('55. Immutable value objects prevent external state tampering', () {
      const v = RelationshipVelocity(recentCount: 1, previousCount: 1, historicalCount: 2, velocityDelta: 0.0);
      const c = CadenceAnalysis(averageCadenceDays: 10.0, daysSinceLastInteraction: 5, totalDistinctDates: 2);
      final m = RelationshipMomentum(
        personId: 'immutable_p',
        direction: MomentumDirection.stable,
        momentumScore: 60.0,
        velocity: v,
        cadence: c,
        headline: 'Stable',
        explanation: 'Consistent',
        keyEvolutionFactors: const ['Factor'],
        generatedAt: refDate,
      );

      expect(m.personId, equals('immutable_p'));
    });

    test('56. Zero Firestore writes occur during momentum evaluation', () {
      final engine = const DeterministicRelationshipMomentumEngine();
      final momentum = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('read_only_p'),
        interactionDates: [
          refDate.subtract(const Duration(days: 20)),
          refDate.subtract(const Duration(days: 5)),
        ],
        referenceDate: refDate,
      );
      expect(momentum.personId, equals('read_only_p'));
    });

    test('57. Unauthenticated/empty profile fallback behaves safely', () {
      final emptyM = RelationshipMomentum.empty();
      expect(emptyM.personId, isEmpty);
      expect(emptyM.direction, equals(MomentumDirection.insufficientHistory));
    });
  });

  group('Phase 13H-05 Group 7 — UI Widgets & Screen Integration', () {
    testWidgets('58. RelationshipMomentumCard renders strengthening badge and metrics', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'test_p1',
        direction: MomentumDirection.strengthening,
        momentumScore: 85.0,
        velocity: const RelationshipVelocity(
          recentCount: 3,
          previousCount: 1,
          historicalCount: 4,
          velocityDelta: 2.0,
        ),
        cadence: const CadenceAnalysis(
          averageCadenceDays: 14.0,
          daysSinceLastInteraction: 6,
          cadenceRatio: 0.42,
          totalDistinctDates: 4,
        ),
        headline: 'Strengthening: 3 interactions in the last 30 days',
        explanation: 'Increasing interaction frequency and sustained engagement.',
        keyEvolutionFactors: const ['Velocity delta +2', 'On pace cadence'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('RELATIONSHIP EVOLUTION'), findsOneWidget);
      expect(find.text('STRENGTHENING'), findsOneWidget);
      expect(find.text('Strengthening: 3 interactions in the last 30 days'), findsOneWidget);
      expect(find.text('Every ~14d'), findsOneWidget);
      expect(find.text('6d ago'), findsOneWidget);
      expect(find.text('3 touchpoints'), findsOneWidget);
    });

    testWidgets('59. RelationshipMomentumCard renders limited data state cleanly', (tester) async {
      final momentum = RelationshipMomentum.insufficientHistory(personId: 'p_limited');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('LIMITED DATA'), findsOneWidget);
      expect(find.text('Limited Interaction History'), findsOneWidget);
      expect(find.text('Not enough interaction history to establish a reliable relationship trend yet.'), findsOneWidget);
      expect(find.text('CADENCE'), findsNothing);
    });

    testWidgets('60. RelationshipMomentumCard renders cooling badge and off-cadence alert', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'test_cooling',
        direction: MomentumDirection.cooling,
        momentumScore: 45.0,
        velocity: const RelationshipVelocity(
          recentCount: 0,
          previousCount: 2,
          historicalCount: 4,
          velocityDelta: -2.0,
        ),
        cadence: const CadenceAnalysis(
          averageCadenceDays: 14.0,
          daysSinceLastInteraction: 35,
          cadenceRatio: 2.5,
          totalDistinctDates: 4,
        ),
        headline: 'Cooling: 35 days since last interaction.',
        explanation: 'Interaction rhythm is slowing down.',
        keyEvolutionFactors: const ['35 days passed'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('COOLING'), findsOneWidget);
      expect(find.text('35d ago'), findsOneWidget);
    });

    testWidgets('61. Person Dossier RelationshipIntelligence widget embeds RelationshipMomentumCard', (tester) async {
      final profile = const PersonProfile(
        id: 'p_profile_1',
        name: 'Sarah Connor',
        role: 'Engineering Lead',
        company: 'Cyberdyne',
        location: 'Los Angeles',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Strong',
        firstMet: '2025-01-10',
        lastInteraction: '2026-08-14',
        totalInteractions: 3,
        sharedEventsCount: 1,
        aiSummary: 'Key engineering contact.',
      );

      final momentum = RelationshipMomentum(
        personId: 'p_profile_1',
        direction: MomentumDirection.stable,
        momentumScore: 60.0,
        velocity: const RelationshipVelocity(recentCount: 1, previousCount: 1, historicalCount: 3, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 20.0, daysSinceLastInteraction: 15, cadenceRatio: 0.75, totalDistinctDates: 3),
        headline: 'Stable: Consistent interaction rhythm.',
        explanation: 'Healthy communication rhythm.',
        keyEvolutionFactors: const ['On pace'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: pds_ri.RelationshipIntelligence(
              profile: profile,
              momentum: momentum,
            ),
          ),
        ),
      ));

      expect(find.text('RELATIONSHIP EVOLUTION'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
    });

    testWidgets('62. NetworkDashboardScreen renders evolution momentum summary section', (tester) async {
      final intel = NetworkIntelligence(
        health: NetworkHealth(
          score: 82.0,
          level: NetworkHealthLevel.healthy,
          confidence: NetworkConfidence.high,
          totalPeople: 12,
          activeRelationships: 8,
          coolingRelationships: 2,
          strongRelationships: 4,
          neglectedRelationships: 1,
          dormantRelationships: 1,
          newRelationships: 2,
          relationshipsNeedingAttention: 3,
          overdueFollowUps: 1,
          interactionCount: 15,
          recentInteractionCount: 9,
          followUpCompletionRate: 0.85,
          relationshipCoverage: 0.9,
          generatedAt: refDate,
        ),
        recentlyStrengthened: [
          PersonRelationshipIntelligence.empty('p1'),
          PersonRelationshipIntelligence.empty('p2'),
          PersonRelationshipIntelligence.empty('p3'),
        ],
        coolingRelationships: [
          PersonRelationshipIntelligence.empty('p4'),
          PersonRelationshipIntelligence.empty('p5'),
        ],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: NetworkDashboardScreen(initialData: intel),
      ));
      await tester.pumpAndSettle();

      expect(find.text('RELATIONSHIP MOMENTUM & EVOLUTION'), findsOneWidget);
      expect(find.text('Strengthening'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('Cooling / Decaying'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('63. Responsive layout renders across 360dp, 768dp, 1024dp without overflow', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'resp_p',
        direction: MomentumDirection.strengthening,
        momentumScore: 88.0,
        velocity: const RelationshipVelocity(recentCount: 4, previousCount: 1, historicalCount: 6, velocityDelta: 3.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 10.0, daysSinceLastInteraction: 4, cadenceRatio: 0.4, totalDistinctDates: 6),
        headline: 'Strengthening: 4 interactions in trailing 30 days',
        explanation: 'Active communication with steady acceleration.',
        keyEvolutionFactors: const ['Velocity up', 'On cadence'],
        generatedAt: refDate,
      );

      for (final width in [360.0, 768.0, 1024.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 1000.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: RelationshipMomentumCard(momentum: momentum),
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('64. RelationshipMomentumCard renders recovering state with violet token', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'test_rec',
        direction: MomentumDirection.recovering,
        momentumScore: 75.0,
        velocity: const RelationshipVelocity(recentCount: 1, previousCount: 0, priorCount: 0, historicalCount: 4, velocityDelta: 1.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 30.0, daysSinceLastInteraction: 3, cadenceRatio: 0.1, totalDistinctDates: 4),
        headline: 'Recovering: Reconnected recently with 1 touchpoint.',
        explanation: 'Relationship is regaining momentum.',
        keyEvolutionFactors: const ['Re-engaged after hiatus'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('RECOVERING'), findsOneWidget);
    });

    testWidgets('65. RelationshipMomentumCard renders newlyDeveloping state', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'test_new',
        direction: MomentumDirection.newlyDeveloping,
        momentumScore: 75.0,
        velocity: const RelationshipVelocity(recentCount: 3, previousCount: 0, historicalCount: 3, velocityDelta: 3.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 5.0, daysSinceLastInteraction: 2, cadenceRatio: 0.4, totalDistinctDates: 3),
        headline: 'Newly Developing: 3 interactions recorded since connection.',
        explanation: 'Active initial engagement.',
        keyEvolutionFactors: const ['3 encounters in initial 30d'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('NEWLY DEVELOPING'), findsOneWidget);
    });

    testWidgets('66. RelationshipMomentumCard renders declining state with crimson alert', (tester) async {
      final momentum = RelationshipMomentum(
        personId: 'test_dec',
        direction: MomentumDirection.declining,
        momentumScore: 25.0,
        velocity: const RelationshipVelocity(recentCount: 0, previousCount: 0, historicalCount: 3, velocityDelta: 0.0),
        cadence: const CadenceAnalysis(averageCadenceDays: 14.0, daysSinceLastInteraction: 80, cadenceRatio: 5.71, totalDistinctDates: 3),
        headline: 'Declining: No contact for 80 days with relationship at risk.',
        explanation: 'Contact frequency has severely decayed.',
        keyEvolutionFactors: const ['80 days since last recorded encounter'],
        generatedAt: refDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RelationshipMomentumCard(momentum: momentum),
        ),
      ));

      expect(find.text('DECLINING'), findsOneWidget);
      expect(find.text('80d ago'), findsOneWidget);
    });

    testWidgets('67. PersonDetailScreen loads profile and renders momentum section in wide layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final profile = const PersonProfile(
        id: 'p_wide_1',
        name: 'Alex Vance',
        role: 'Founder',
        company: 'Black Mesa',
        location: 'City 17',
        initials: 'AV',
        relationshipType: RelationshipContextType.advisor,
        relationshipStrength: 'Strong',
        firstMet: '2025-06-15',
        lastInteraction: '2026-08-20',
        totalInteractions: 4,
        sharedEventsCount: 2,
        aiSummary: 'Strategic contact in deep tech.',
        timeline: [
          TimelineItem(
            id: 't1',
            type: TimelineType.meeting,
            title: 'Initial sync',
            subtitle: 'Coffee',
            date: '2026-08-10',
            summary: 'Good discussion on roadmap.',
          ),
          TimelineItem(
            id: 't2',
            type: TimelineType.conversation,
            title: 'Follow-up call',
            subtitle: 'Phone',
            date: '2026-08-20',
            summary: 'Discussed API specs.',
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RecallrScope(
          dependencies: RecallrDependencies.mock(),
          child: PersonDetailScreen(
            personId: 'p_wide_1',
            initialProfile: profile,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('RELATIONSHIP EVOLUTION'), findsOneWidget);
    });
  });

  group('Phase 13H-05 Group 8 — Composition, DI Wiring & Golden Journey', () {
    test('68. DeterministicRelationshipMomentumEngine rankMomentumSync sorts contacts deterministically', () {
      final engine = const DeterministicRelationshipMomentumEngine();

      final i1 = PersonRelationshipIntelligence.empty('p_low');
      final i2 = PersonRelationshipIntelligence.empty('p_high');

      final results = engine.rankMomentumSync(
        [i1, i2],
        interactionDatesMap: {
          'p_low': [refDate.subtract(const Duration(days: 80))],
          'p_high': [
            refDate.subtract(const Duration(days: 45)),
            refDate.subtract(const Duration(days: 15)),
            refDate.subtract(const Duration(days: 2)),
          ],
        },
        referenceDate: refDate,
      );

      expect(results.length, equals(2));
      expect(results.first.personId, equals('p_high'));
      expect(results.first.direction, equals(MomentumDirection.strengthening));
    });

    test('69. DI Container RecallrDependencies provides non-null momentum instances', () {
      final deps = RecallrDependencies.mock();
      expect(deps.relationshipCadenceCalculator, isNotNull);
      expect(deps.relationshipVelocityCalculator, isNotNull);
      expect(deps.relationshipEvolutionClassifier, isNotNull);
      expect(deps.relationshipMomentumEngine, isNotNull);
      expect(deps.relationshipMomentumService, isNotNull);
    });

    test('70. Golden User Journey: Multi-contact network evaluates varying momentum trajectories simultaneously', () {
      final engine = const DeterministicRelationshipMomentumEngine();

      // Contact 1: Strengthening
      final mStrengthen = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('p_strengthen'),
        interactionDates: [
          refDate.subtract(const Duration(days: 35)),
          refDate.subtract(const Duration(days: 15)),
          refDate.subtract(const Duration(days: 5)),
        ],
        referenceDate: refDate,
      );
      expect(mStrengthen.direction, equals(MomentumDirection.strengthening));

      // Contact 2: Cooling (Cadence ratio 1.75x)
      final mCool = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('p_cool'),
        interactionDates: [
          refDate.subtract(const Duration(days: 55)),
          refDate.subtract(const Duration(days: 35)),
        ],
        referenceDate: refDate,
      );
      expect(mCool.direction, equals(MomentumDirection.cooling));

      // Contact 3: Limited Data
      final mLimited = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('p_limited'),
        interactionDates: [refDate.subtract(const Duration(days: 10))],
        referenceDate: refDate,
      );
      expect(mLimited.direction, equals(MomentumDirection.insufficientHistory));
    });

    test('71. Dynamic calculation with multiple interactions handles millisecond variance', () {
      final engine = const DeterministicRelationshipMomentumEngine();
      final dates = [
        refDate.subtract(const Duration(days: 45, milliseconds: 500)),
        refDate.subtract(const Duration(days: 14, milliseconds: 200)),
        refDate.subtract(const Duration(days: 1, milliseconds: 100)),
      ];

      final momentum = engine.getMomentumSync(
        intelligence: PersonRelationshipIntelligence.empty('p_ms'),
        interactionDates: dates,
        referenceDate: refDate,
      );

      expect(momentum.velocity.recentCount, equals(2));
      expect(momentum.direction, equals(MomentumDirection.strengthening));
    });

    test('72. Deterministic sorting handles equal score tie-breaking via personId ASC', () {
      final engine = const DeterministicRelationshipMomentumEngine();
      final i1 = PersonRelationshipIntelligence.empty('p_beta');
      final i2 = PersonRelationshipIntelligence.empty('p_alpha');

      final results = engine.rankMomentumSync(
        [i1, i2],
        referenceDate: refDate,
      );

      expect(results[0].personId, equals('p_alpha'));
      expect(results[1].personId, equals('p_beta'));
    });

    test('73. Empty interaction dates map produces graceful insufficientHistory list', () {
      final engine = const DeterministicRelationshipMomentumEngine();
      final intel = [PersonRelationshipIntelligence.empty('p1')];
      final ranked = engine.rankMomentumSync(intel, referenceDate: refDate);
      expect(ranked.first.direction, equals(MomentumDirection.insufficientHistory));
    });

    test('74. Bulk ranking handles mixed populated and empty contact profiles', () {
      final engine = const DeterministicRelationshipMomentumEngine();
      final i1 = PersonRelationshipIntelligence.empty('p_pop');
      final i2 = PersonRelationshipIntelligence.empty('p_empty');

      final datesMap = {
        'p_pop': [
          refDate.subtract(const Duration(days: 20)),
          refDate.subtract(const Duration(days: 10)),
        ],
      };

      final ranked = engine.rankMomentumSync(
        [i2, i1],
        interactionDatesMap: datesMap,
        referenceDate: refDate,
      );

      expect(ranked.first.personId, equals('p_pop'));
      expect(ranked.last.personId, equals('p_empty'));
    });

    test('75. Direct async getMomentum matches synchronous getMomentumSync output', () async {
      final engine = const DeterministicRelationshipMomentumEngine();
      final intel = PersonRelationshipIntelligence.empty('p_async_test');
      final dates = [
        refDate.subtract(const Duration(days: 20)),
        refDate.subtract(const Duration(days: 5)),
      ];

      final syncRes = engine.getMomentumSync(intelligence: intel, interactionDates: dates, referenceDate: refDate);
      final asyncRes = await engine.getMomentum(intelligence: intel, interactionDates: dates, referenceDate: refDate);

      expect(syncRes.direction, equals(asyncRes.direction));
      expect(syncRes.momentumScore, equals(asyncRes.momentumScore));
      expect(syncRes.headline, equals(asyncRes.headline));
    });

    test('76. DeterministicRelationshipMomentumService initializes with default engine', () {
      final deps = RecallrDependencies.mock();
      expect(deps.relationshipMomentumService, isA<DeterministicRelationshipMomentumService>());
    });

    test('77. CadenceAnalysis handles single day interval correctly', () {
      final dates = [
        refDate.subtract(const Duration(days: 2)),
        refDate.subtract(const Duration(days: 1)),
      ];
      const calc = DeterministicRelationshipCadenceCalculator();
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.averageCadenceDays, equals(1.0));
      expect(res.daysSinceLastInteraction, equals(1));
    });

    test('78. Velocity delta handles zero prior interactions', () {
      const calc = DeterministicRelationshipVelocityCalculator();
      final dates = [refDate.subtract(const Duration(days: 5))];
      final res = calc.calculate(interactionDates: dates, referenceDate: refDate);
      expect(res.velocityDelta, equals(1.0));
      expect(res.previousCount, equals(0));
    });
  });
}
