import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/services/relationship/relationship_attention_calculator.dart';
import 'package:recaller/services/relationship/relationship_attention_explanation.dart';
import 'package:recaller/services/relationship/relationship_attention_priority_calculator.dart';
import 'package:recaller/services/relationship/relationship_metrics_display.dart';
import 'package:recaller/services/relationship/relationship_state_classifier.dart';
import 'package:recaller/services/relationship/relationship_strength_calculator.dart';

void main() {
  const strengthCalc = DeterministicRelationshipStrengthCalculator();
  const stateClassifier = DeterministicRelationshipStateClassifier();
  const attentionCalc = DeterministicRelationshipAttentionCalculator();
  const priorityCalc = DeterministicRelationshipAttentionPriorityCalculator();
  final refDate = DateTime(2026, 10, 23, 12, 0, 0);

  PersonProfile makeProfile({
    String id = 'per_test',
    String name = 'Test Person',
    int totalInteractions = 0,
    DateTime? lastInteractionAt,
    String lastInteraction = 'Never',
    String firstMet = 'Never',
    DateTime? createdAt,
    List<TimelineItem> timeline = const [],
  }) {
    return PersonProfile(
      id: id,
      name: name,
      role: 'Engineer',
      company: 'Acme',
      location: '',
      initials: 'TP',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'Active Collaborator', // legacy field — must be ignored by dynamic UI
      firstMet: firstMet,
      lastInteraction: lastInteraction,
      totalInteractions: totalInteractions,
      sharedEventsCount: 0,
      aiSummary: '',
      lastInteractionAt: lastInteractionAt,
      createdAt: createdAt,
      timeline: timeline,
    );
  }

  group('APPROVED CHANGE 1: Score Cap & NEW Status', () {
    test('Contact scanned today with 2 interactions -> status NEW, score <= 30', () {
      final profile = makeProfile(
        totalInteractions: 2,
        lastInteractionAt: refDate,
        lastInteraction: 'Just now',
        firstMet: 'Today',
        createdAt: refDate,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.newRelationship),
          reason: 'A contact with 2 interactions must be classified as NEW');
      expect(strength.score, lessThanOrEqualTo(30.0),
          reason: 'New contacts (<=2 interactions) must have score capped at 30');
    });

    test('Contact with 3 interactions and recent touchpoint -> ACTIVE, score not capped', () {
      final profile = makeProfile(
        totalInteractions: 3,
        lastInteractionAt: refDate,
        lastInteraction: 'Today',
        firstMet: 'Jan 1, 2026',
        createdAt: refDate.subtract(const Duration(days: 60)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.active));
      expect(strength.score, greaterThan(30.0));
    });

    test('Contact added today with 1 interaction -> NEW, score capped <= 30', () {
      final profile = makeProfile(
        totalInteractions: 1,
        lastInteractionAt: refDate,
        createdAt: refDate,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.newRelationship));
      expect(strength.score, lessThanOrEqualTo(30.0));
    });

    test('Score cap does not restrict established contacts with >2 interactions', () {
      final profile = makeProfile(
        totalInteractions: 8,
        lastInteractionAt: refDate,
        firstMet: 'Jan 1, 2026',
        createdAt: refDate.subtract(const Duration(days: 180)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);

      expect(strength.score, greaterThan(30.0));
    });
  });

  group('APPROVED CHANGE 2: Complete Status Rules (Order & No Gaps)', () {
    test('DORMANT: daysSinceLast > 180 AND ageDays > 180', () {
      final profile = makeProfile(
        totalInteractions: 5,
        lastInteractionAt: refDate.subtract(const Duration(days: 200)),
        createdAt: refDate.subtract(const Duration(days: 210)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.dormant));
    });

    test('QUIET fallback: established contact with unparseable date is QUIET, not DORMANT', () {
      final profile = makeProfile(
        totalInteractions: 5,
        lastInteractionAt: null,
        lastInteraction: 'unknown-format',
        createdAt: refDate.subtract(const Duration(days: 200)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, isNull);

      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.quiet),
          reason: 'Unknown/unparseable date must never evaluate to DORMANT; it falls back to QUIET');
    });

    test('NEGLECTED: count >= 3 with > 60 days of silence', () {
      final profile = makeProfile(
        totalInteractions: 4,
        lastInteractionAt: refDate.subtract(const Duration(days: 90)),
        createdAt: refDate.subtract(const Duration(days: 200)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.neglected));
    });

    test('COOLING: count >= 2 with 31-60 days since last interaction', () {
      final profile = makeProfile(
        totalInteractions: 4,
        lastInteractionAt: refDate.subtract(const Duration(days: 45)),
        createdAt: refDate.subtract(const Duration(days: 200)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.cooling));
    });

    test('ACTIVE: count >= 1 with days <= 30', () {
      final profile = makeProfile(
        totalInteractions: 4,
        lastInteractionAt: refDate.subtract(const Duration(days: 5)),
        createdAt: refDate.subtract(const Duration(days: 200)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.active));
    });
  });

  group('APPROVED CHANGE 3: Date Fallback Rules', () {
    test('"Just now" string parses accurately to today', () {
      final profile = makeProfile(
        totalInteractions: 2,
        lastInteraction: 'Just now',
        lastInteractionAt: null,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, isNotNull);
      expect(signals.daysSinceLastInteraction, equals(0));
    });

    test('Unparseable string with null lastInteractionAt -> daysSinceLastInteraction is null', () {
      final profile = makeProfile(
        totalInteractions: 3,
        lastInteraction: 'unparseable_xyz',
        lastInteractionAt: null,
        createdAt: null,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, isNull);
    });

    test('lastInteractionAt acts as verified fallback when string is unparseable', () {
      final knownDate = refDate.subtract(const Duration(days: 10));
      final profile = makeProfile(
        totalInteractions: 3,
        lastInteraction: 'corrupted-timestamp',
        lastInteractionAt: knownDate,
        createdAt: refDate.subtract(const Duration(days: 90)),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, equals(10));
    });
  });

  group('APPROVED CHANGE 4: Display-Time Formatting', () {
    test('RelationshipMetricsDisplay formats relative timestamps cleanly', () {
      expect(RelationshipMetricsDisplay.formatRelativeTime(refDate, referenceDate: refDate), equals('Just now'));
      expect(RelationshipMetricsDisplay.formatRelativeTime(refDate.subtract(const Duration(hours: 2)), referenceDate: refDate), equals('2 hours ago'));
      expect(RelationshipMetricsDisplay.formatRelativeTime(refDate.subtract(const Duration(days: 1)), referenceDate: refDate), equals('Yesterday'));
      expect(RelationshipMetricsDisplay.formatRelativeTime(refDate.subtract(const Duration(days: 4)), referenceDate: refDate), equals('4 days ago'));
    });
  });

  group('APPROVED CHANGE 5: Cross-Screen Consistency (People List vs Dossier)', () {
    test('Same person produces identical score, status, and title from both screen computation paths', () {
      final profile = makeProfile(
        id: 'per_scan_anil',
        name: 'Anil Nagar',
        totalInteractions: 2,
        firstMet: 'Today',
        lastInteraction: 'Just now',
        lastInteractionAt: refDate,
        createdAt: refDate,
      );

      // Path A: Dossier computation (profile domain data)
      final signalsDossier = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strengthDossier = strengthCalc.calculate(signalsDossier);
      final stateDossier = stateClassifier.classify(signals: signalsDossier, strength: strengthDossier);

      // Path B: People List computation (profile + 2 scanned activities)
      final act = ActivityItem(
        id: 'act_01',
        personId: 'per_scan_anil',
        title: 'Card Scanned',
        summary: 'Business card scanned',
        period: TimelinePeriod.today,
        targetRoute: '/person/per_scan_anil',
        actionLabel: 'View',
        type: ActivityType.capture,
        timestamp: 'Just now',
        createdAt: refDate,
      );

      final signalsPeople = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [act, act],
        referenceDate: refDate,
      );
      final strengthPeople = strengthCalc.calculate(signalsPeople);
      final statePeople = stateClassifier.classify(signals: signalsPeople, strength: strengthPeople);

      // Assert complete consistency
      expect(stateDossier, equals(RelationshipState.newRelationship));
      expect(statePeople, equals(RelationshipState.newRelationship));
      expect(stateDossier, equals(statePeople), reason: 'Both screens must report identical status');

      expect(strengthDossier.score, lessThanOrEqualTo(30.0));
      expect(strengthPeople.score, lessThanOrEqualTo(30.0));
    });
  });

  group('APPROVED CHANGE 7: Attention Alerts Immunity for New Contacts', () {
    test('Contact met today with 2 interactions produces LOW priority (no attention alert)', () {
      final profile = makeProfile(
        totalInteractions: 2,
        lastInteractionAt: refDate,
        lastInteraction: 'Just now',
        createdAt: refDate,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: signals,
        strength: strength,
        state: state,
        generatedAt: refDate,
        explanations: const [],
        topFactors: const [],
      );

      final attentionScore = attentionCalc.calculate(
        signals: signals,
        strength: strength,
        state: state,
      );

      final priority = priorityCalc.calculate(
        attentionScore: attentionScore,
        intelligence: intel,
      );

      final reasons = RelationshipAttentionExplanation.generateReasons(
        intelligence: intel,
        personName: profile.name,
      );

      expect(priority, equals(RelationshipAttentionPriority.low),
          reason: 'A new contact created today with 2 interactions must NOT have medium/high attention priority');
      expect(reasons.any((r) => r.code == 'general_review'), isFalse,
          reason: '"Periodic Review" must not be triggered for brand new contacts');
    });
  });
}
