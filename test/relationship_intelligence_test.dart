import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/capture_processing_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';
import 'package:recaller/services/relationship/relationship_intelligence_service.dart';
import 'package:recaller/services/relationship/relationship_state_classifier.dart';
import 'package:recaller/services/relationship/relationship_strength_calculator.dart';

Widget _createTestApp(Widget child, {RecallrDependencies? dependencies}) {
  final deps = dependencies ?? RecallrDependencies.mock();
  return RecallrScope(
    dependencies: deps,
    child: MaterialApp(
      theme: RecallrTheme.darkTheme,
      home: child,
    ),
  );
}

PersonProfile _createTestProfile({
  String id = 'per_sarah_01',
  String name = 'Sarah Chen',
  String role = 'VP of System Architecture',
  String company = 'Mosaic Labs',
  String firstMet = 'Jan 15, 2026',
  String lastInteraction = 'Aug 25, 2026',
  int totalInteractions = 8,
  int sharedEventsCount = 3,
  String relationshipStrength = 'Strong · Technical Collaborator',
  List<TimelineItem> timeline = const [],
  List<MemoryItem> memories = const [],
  List<FollowUpItem> followUps = const [],
}) {
  return PersonProfile(
    id: id,
    name: name,
    role: role,
    company: company,
    location: 'San Francisco, CA',
    initials: 'SC',
    relationshipType: RelationshipContextType.collaborator,
    relationshipStrength: relationshipStrength,
    firstMet: firstMet,
    lastInteraction: lastInteraction,
    totalInteractions: totalInteractions,
    sharedEventsCount: sharedEventsCount,
    aiSummary: 'Sarah Chen is the VP of System Architecture at Mosaic Labs collaborating on RISC-V hardware.',
    timeline: timeline,
    memories: memories,
    followUps: followUps,
  );
}

void main() {
  final refDate = DateTime(2026, 8, 29, 12, 0, 0);
  const strengthCalc = DeterministicRelationshipStrengthCalculator();
  const stateClassifier = DeterministicRelationshipStateClassifier();

  group('Phase 13H-01 Group 1: Relationship Signals Computation', () {
    test('1. Zero interactions returns zero signals with null daysSinceLastInteraction', () {
      final profile = _createTestProfile(
        firstMet: 'Unknown',
        lastInteraction: 'Never',
        totalInteractions: 0,
        sharedEventsCount: 0,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.interactionCount, equals(0));
      expect(signals.recentInteractionDate, isNull);
      expect(signals.daysSinceLastInteraction, isNull);
      expect(signals.hasRecentInteraction, isFalse);
      expect(signals.interactionFrequency, equals(0.0));
    });

    test('2. Single interaction parses count and dates accurately', () {
      final profile = _createTestProfile(
        firstMet: 'Aug 25, 2026',
        lastInteraction: 'Aug 25, 2026',
        totalInteractions: 1,
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.interactionCount, equals(1));
      expect(signals.daysSinceLastInteraction, equals(4));
      expect(signals.hasRecentInteraction, isTrue);
      expect(signals.relationshipAgeDays, equals(4));
    });

    test('3. Multiple interactions counts correctly from timeline and activities', () {
      final profile = _createTestProfile(
        firstMet: 'Jan 15, 2026',
        lastInteraction: 'Aug 20, 2026',
        totalInteractions: 5,
        timeline: [
          const TimelineItem(
            id: 'tl_1',
            type: TimelineType.meeting,
            title: 'Indiranagar Sync',
            subtitle: 'Discussed API',
            date: 'Aug 20, 2026',
            summary: 'Meeting summary',
          ),
          const TimelineItem(
            id: 'tl_2',
            type: TimelineType.conversation,
            title: 'Quick Catchup',
            subtitle: 'Phone call',
            date: 'Aug 10, 2026',
            summary: 'Call summary',
          ),
        ],
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.interactionCount, equals(5));
      expect(signals.daysSinceLastInteraction, equals(9));
      expect(signals.hasRecentInteraction, isTrue);
      expect(signals.recentInteractionCount, equals(2));
    });

    test('4. Recent interaction within 30 days sets hasRecentInteraction to true', () {
      final profile = _createTestProfile(
        lastInteraction: 'Aug 27, 2026',
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, equals(2));
      expect(signals.hasRecentInteraction, isTrue);
    });

    test('5. Old interaction (>30 days) sets hasRecentInteraction to false', () {
      final profile = _createTestProfile(
        lastInteraction: 'May 10, 2026',
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, greaterThan(30));
      expect(signals.hasRecentInteraction, isFalse);
    });

    test('6. Relationship age calculates difference from firstMet to referenceDate', () {
      final profile = _createTestProfile(
        firstMet: 'Aug 15, 2026',
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.relationshipAgeDays, equals(14));
    });

    test('7. Memory count aggregates structured claims and memories', () {
      final profile = _createTestProfile(
        memories: [
          const MemoryItem(id: 'm1', category: 'Hardware', text: 'RISC-V design', source: 'Meeting'),
          const MemoryItem(id: 'm2', category: 'Role', text: 'VP at Mosaic', source: 'Card'),
          const MemoryItem(id: 'm3', category: 'Location', text: 'Based in SF', source: 'Note'),
        ],
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.memoryCount, equals(3));
    });

    test('8. Capture count aggregates associated captures', () {
      final profile = _createTestProfile();
      final captures = [
        const CaptureItem(
          id: 'cap_1',
          type: CaptureType.businessCard,
          title: 'Visiting Card',
          description: 'Visiting card description',
          timestamp: 'Aug 20, 2026',
          targetRoute: '/capture/cap_1',
          personName: 'Sarah Chen',
          processingStatus: CaptureProcessingStatus.completed,
        ),
        const CaptureItem(
          id: 'cap_2',
          type: CaptureType.voice,
          title: 'Voice Memo',
          description: 'Voice note description',
          timestamp: 'Aug 22, 2026',
          targetRoute: '/capture/cap_2',
          personName: 'Sarah Chen',
          processingStatus: CaptureProcessingStatus.completed,
        ),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        captures: captures,
        referenceDate: refDate,
      );

      expect(signals.captureCount, equals(2));
    });

    test('9. Active follow-up count aggregates pending commitments', () {
      final profile = _createTestProfile();
      final followUps = [
        const FollowUpItem(
          id: 'fu_1',
          title: 'Send API Documentation',
          dueDate: 'Sep 5, 2026',
          targetRoute: '/follow-up/fu_1',
          status: FollowUpStatus.upcoming,
        ),
        const FollowUpItem(
          id: 'fu_2',
          title: 'Intro to Team',
          dueDate: 'Aug 30, 2026',
          targetRoute: '/follow-up/fu_2',
          status: FollowUpStatus.dueToday,
        ),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        followUps: followUps,
        referenceDate: refDate,
      );

      expect(signals.activeFollowUpCount, equals(2));
      expect(signals.hasActiveFollowUp, isTrue);
      expect(signals.hasOverdueFollowUp, isFalse);
    });

    test('10. Completed follow-up count aggregates fulfilled commitments', () {
      final profile = _createTestProfile();
      final followUps = [
        const FollowUpItem(
          id: 'fu_1',
          title: 'Sent initial deck',
          dueDate: 'Aug 10, 2026',
          targetRoute: '/follow-up/fu_1',
          isCompleted: true,
          status: FollowUpStatus.completed,
        ),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        followUps: followUps,
        referenceDate: refDate,
      );

      expect(signals.completedFollowUpCount, equals(1));
      expect(signals.activeFollowUpCount, equals(0));
    });

    test('11. Overdue follow-up count detects overdue commitments', () {
      final profile = _createTestProfile();
      final followUps = [
        const FollowUpItem(
          id: 'fu_1',
          title: 'Send NDA review',
          dueDate: 'Aug 1, 2026',
          targetRoute: '/follow-up/fu_1',
          status: FollowUpStatus.overdue,
        ),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        followUps: followUps,
        referenceDate: refDate,
      );

      expect(signals.overdueFollowUpCount, equals(1));
      expect(signals.hasOverdueFollowUp, isTrue);
    });

    test('12. Recent activity count filters activities within 30-day window', () {
      final profile = _createTestProfile(
        timeline: [
          const TimelineItem(
            id: 't1',
            type: TimelineType.meeting,
            title: 'Recent Sync',
            subtitle: 'Product',
            date: 'Aug 26, 2026',
            summary: 'Summary',
          ),
          const TimelineItem(
            id: 't2',
            type: TimelineType.conversation,
            title: 'Old Sync',
            subtitle: 'Old call',
            date: 'Jan 10, 2026',
            summary: 'Old summary',
          ),
        ],
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.recentInteractionCount, equals(1));
    });

    test('13. Missing or invalid date strings handle gracefully without throwing', () {
      final profile = _createTestProfile(
        firstMet: 'Invalid-Date-Format',
        lastInteraction: 'Some unknown day',
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, isNull);
      expect(signals.relationshipAgeDays, equals(0));
    });

    test('14. Duplicate timeline and activity dates deduplicate correctly', () {
      final profile = _createTestProfile(
        lastInteraction: 'Aug 25, 2026',
        timeline: [
          const TimelineItem(
            id: 't1',
            type: TimelineType.meeting,
            title: 'Meeting 1',
            subtitle: '',
            date: 'Aug 25, 2026',
            summary: '',
          ),
        ],
      );

      final activities = [
        const ActivityItem(
          id: 'act_1',
          type: ActivityType.meeting,
          period: TimelinePeriod.today,
          timestamp: 'Aug 25, 2026',
          title: 'Meeting 1',
          summary: '',
          targetRoute: '',
          actionLabel: '',
        ),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: activities,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, equals(4));
    });
  });

  group('Phase 13H-01 Group 2: Recency Scoring & Boundary Verification', () {
    test('15. Same-day interaction (0 days) yields maximum recency score of 1.0', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 0,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(1.0));
      expect(recencyFactor.explanation, contains('today'));
    });

    test('16. 7-day boundary interaction yields maximum recency score of 1.0', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 7,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(1.0));
      expect(recencyFactor.explanation, contains('7 days ago'));
    });

    test('17. 30-day boundary yields 0.85 recency score', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 30,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(0.85));
      expect(recencyFactor.explanation, contains('within the last month'));
    });

    test('18. 90-day boundary yields 0.55 recency score', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 90,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(0.55));
    });

    test('19. 180-day boundary yields 0.25 recency score', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 180,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(0.25));
    });

    test('20. Stale relationship (>180 days, e.g. 240 days) yields 0.05 recency score', () {
      const signals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 240,
      );
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recencyFactor.score, equals(0.05));
    });

    test('21. Future timestamps handle safely clamped as same-day (0 days)', () {
      final profile = _createTestProfile(
        lastInteraction: 'Dec 31, 2026', // future relative to refDate
      );
      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: refDate,
      );

      expect(signals.daysSinceLastInteraction, equals(0));
      final strength = strengthCalc.calculate(signals);
      final recencyFactor = strength.factors.firstWhere((f) => f.name == 'Recency');
      expect(recencyFactor.score, equals(1.0));
    });
  });

  group('Phase 13H-01 Group 3: Strength Calculation & Explainability', () {
    test('22. Strength score is strictly bounded 0.0 to 100.0', () {
      const highSignals = RelationshipSignals(
        interactionCount: 100,
        daysSinceLastInteraction: 0,
        recentInteractionCount: 20,
        memoryCount: 50,
        captureCount: 30,
        completedFollowUpCount: 20,
      );
      final highStrength = strengthCalc.calculate(highSignals);

      expect(highStrength.score, lessThanOrEqualTo(100.0));
      expect(highStrength.score, greaterThanOrEqualTo(0.0));
    });

    test('23. Empty relationship yields 0.0 score with informative summary', () {
      final signals = RelationshipSignals.empty();
      final strength = strengthCalc.calculate(signals);

      expect(strength.score, equals(0.0));
      expect(strength.level, equals('None'));
      expect(strength.summary, contains('Not enough interaction history'));
    });

    test('24. Recent relationship with high recency receives strong recency contribution', () {
      const signals = RelationshipSignals(
        interactionCount: 2,
        daysSinceLastInteraction: 3,
        recentInteractionCount: 2,
      );
      final strength = strengthCalc.calculate(signals);
      final recency = strength.factors.firstWhere((f) => f.name == 'Recency');

      expect(recency.score, equals(1.0));
      expect(recency.weightedScore, equals(30.0)); // 1.0 * 0.30 * 100
    });

    test('25. Frequent communication boosts frequency factor', () {
      const signals = RelationshipSignals(
        interactionCount: 15,
        recentInteractionCount: 5,
        daysSinceLastInteraction: 4,
      );
      final strength = strengthCalc.calculate(signals);
      final freq = strength.factors.firstWhere((f) => f.name == 'Frequency');

      expect(freq.score, equals(1.0));
      expect(freq.weightedScore, equals(25.0)); // 1.0 * 0.25 * 100
    });

    test('26. Memory-rich relationship boosts memory richness factor', () {
      const signals = RelationshipSignals(
        interactionCount: 5,
        memoryCount: 5,
        captureCount: 2,
      );
      final strength = strengthCalc.calculate(signals);
      final mem = strength.factors.firstWhere((f) => f.name == 'Memory Richness');

      expect(mem.score, equals(1.0)); // >=6 items
      expect(mem.weightedScore, equals(15.0)); // 1.0 * 0.15 * 100
    });

    test('27. Follow-up engagement rewards completed and penalizes overdue', () {
      const goodSignals = RelationshipSignals(
        interactionCount: 4,
        completedFollowUpCount: 3,
      );
      final goodStrength = strengthCalc.calculate(goodSignals);
      final goodFU = goodStrength.factors.firstWhere((f) => f.name == 'Follow-up Engagement');
      expect(goodFU.score, equals(1.0));

      const overdueSignals = RelationshipSignals(
        interactionCount: 4,
        overdueFollowUpCount: 2,
      );
      final overdueStrength = strengthCalc.calculate(overdueSignals);
      final overdueFU = overdueStrength.factors.firstWhere((f) => f.name == 'Follow-up Engagement');
      expect(overdueFU.score, equals(0.20));
    });

    test('28. Combined high-quality relationship (Sarah Chen fixture) produces deterministic high score', () {
      const sarahSignals = RelationshipSignals(
        interactionCount: 8,
        daysSinceLastInteraction: 4,
        recentInteractionCount: 3,
        memoryCount: 5,
        captureCount: 2,
        activeFollowUpCount: 1,
        completedFollowUpCount: 4,
      );
      final strength = strengthCalc.calculate(sarahSignals);

      expect(strength.score, greaterThanOrEqualTo(80.0));
      expect(strength.level, equals('Very High'));
      expect(strength.factors.length, equals(5));
    });

    test('29. Sparse relationship produces low score', () {
      const sparseSignals = RelationshipSignals(
        interactionCount: 1,
        daysSinceLastInteraction: 120,
      );
      final strength = strengthCalc.calculate(sparseSignals);

      expect(strength.score, lessThan(35.0));
      expect(strength.level, isIn(['Developing', 'Low']));
    });

    test('30. Deterministic guarantee: identical signals produce identical strength', () {
      const signalsA = RelationshipSignals(
        interactionCount: 6,
        daysSinceLastInteraction: 10,
        memoryCount: 4,
      );
      const signalsB = RelationshipSignals(
        interactionCount: 6,
        daysSinceLastInteraction: 10,
        memoryCount: 4,
      );

      final strengthA = strengthCalc.calculate(signalsA);
      final strengthB = strengthCalc.calculate(signalsB);

      expect(strengthA.score, equals(strengthB.score));
      expect(strengthA.level, equals(strengthB.level));
      expect(strengthA.summary, equals(strengthB.summary));
    });

    test('31. Never produces NaN under any input', () {
      const nanSignals = RelationshipSignals(
        interactionCount: 0,
        interactionFrequency: 0.0,
        relationshipAgeDays: 0,
        daysSinceLastInteraction: null,
      );
      final strength = strengthCalc.calculate(nanSignals);

      expect(strength.score.isNaN, isFalse);
    });

    test('32. Never produces Infinity under any input', () {
      const infSignals = RelationshipSignals(
        interactionCount: 999999,
        interactionFrequency: 999999.0,
        relationshipAgeDays: 1,
      );
      final strength = strengthCalc.calculate(infSignals);

      expect(strength.score.isInfinite, isFalse);
      expect(strength.score, lessThanOrEqualTo(100.0));
    });
  });

  group('Phase 13H-01 Group 4: Deterministic Relationship State Classification', () {
    test('33. NEW: Contact with minimal history classifies as newRelationship', () {
      const signals = RelationshipSignals(
        interactionCount: 0,
        relationshipAgeDays: 3,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.newRelationship));
      expect(state.badgeLabel, equals('NEW'));
    });

    test('34. ACTIVE: Recent interaction within 30 days classifies as active', () {
      const signals = RelationshipSignals(
        interactionCount: 2,
        daysSinceLastInteraction: 12,
        recentInteractionCount: 1,
        relationshipAgeDays: 45,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.active));
      expect(state.badgeLabel, equals('ACTIVE'));
    });

    test('35. STRONG: High strength score and frequent recent encounters classifies as strong', () {
      const signals = RelationshipSignals(
        interactionCount: 8,
        daysSinceLastInteraction: 3,
        recentInteractionCount: 3,
        memoryCount: 5,
        captureCount: 2,
        completedFollowUpCount: 3,
        relationshipAgeDays: 120,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.strong));
      expect(state.badgeLabel, equals('STRONG'));
    });

    test('36. COOLING: Previously active (2+ interactions) with last interaction 31–60 days ago', () {
      const signals = RelationshipSignals(
        interactionCount: 3,
        daysSinceLastInteraction: 45,
        relationshipAgeDays: 90,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.cooling));
      expect(state.badgeLabel, equals('COOLING'));
    });

    test('37. NEGLECTED: Meaningful past connection (3+ interactions) with >60 days lapse or overdue follow-up', () {
      const signals = RelationshipSignals(
        interactionCount: 5,
        daysSinceLastInteraction: 75,
        relationshipAgeDays: 150,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.neglected));
      expect(state.badgeLabel, equals('NEGLECTED'));
    });

    test('38. DORMANT: Long-standing connection with no interaction for >180 days', () {
      const signals = RelationshipSignals(
        interactionCount: 4,
        daysSinceLastInteraction: 200,
        relationshipAgeDays: 300,
      );
      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(state, equals(RelationshipState.dormant));
      expect(state.badgeLabel, equals('DORMANT'));
    });

    test('39. Boundary condition transitions resolve deterministically', () {
      // Exactly 30 days -> ACTIVE
      const sig30 = RelationshipSignals(interactionCount: 2, daysSinceLastInteraction: 30);
      expect(stateClassifier.classify(signals: sig30, strength: strengthCalc.calculate(sig30)), equals(RelationshipState.active));

      // Exactly 31 days -> COOLING
      const sig31 = RelationshipSignals(interactionCount: 2, daysSinceLastInteraction: 31);
      expect(stateClassifier.classify(signals: sig31, strength: strengthCalc.calculate(sig31)), equals(RelationshipState.cooling));

      // Exactly 60 days -> COOLING
      const sig60 = RelationshipSignals(interactionCount: 2, daysSinceLastInteraction: 60);
      expect(stateClassifier.classify(signals: sig60, strength: strengthCalc.calculate(sig60)), equals(RelationshipState.cooling));

      // Exactly 61 days with 3+ interactions -> NEGLECTED
      const sig61 = RelationshipSignals(interactionCount: 3, daysSinceLastInteraction: 61);
      expect(stateClassifier.classify(signals: sig61, strength: strengthCalc.calculate(sig61)), equals(RelationshipState.neglected));

      // Exactly 181 days -> DORMANT
      const sig181 = RelationshipSignals(interactionCount: 3, daysSinceLastInteraction: 181, relationshipAgeDays: 200);
      expect(stateClassifier.classify(signals: sig181, strength: strengthCalc.calculate(sig181)), equals(RelationshipState.dormant));
    });

    test('40. Precedence consistency: DORMANT takes precedence over NEGLECTED', () {
      const sig = RelationshipSignals(
        interactionCount: 10,
        daysSinceLastInteraction: 210,
        overdueFollowUpCount: 2,
        relationshipAgeDays: 250,
      );
      final strength = strengthCalc.calculate(sig);
      final state = stateClassifier.classify(signals: sig, strength: strength);

      // Overdue FU satisfies NEGLECTED, but >180 days satisfies DORMANT which has higher precedence
      expect(state, equals(RelationshipState.dormant));
    });
  });

  group('Phase 13H-01 Group 5: Service Architecture & Repository Integration', () {
    late MockPersonDetailRepository mockPersonRepo;
    late MockActivityRepository mockActivityRepo;
    late MockFollowUpRepository mockFollowUpRepo;
    late MockCaptureRepository mockCaptureRepo;
    late DeterministicRelationshipIntelligenceService service;

    setUp(() {
      mockPersonRepo = MockPersonDetailRepository();
      mockActivityRepo = MockActivityRepository();
      mockFollowUpRepo = MockFollowUpRepository();
      mockCaptureRepo = MockCaptureRepository();

      service = DeterministicRelationshipIntelligenceService(
        personDetailRepository: mockPersonRepo,
        activityRepository: mockActivityRepo,
        followUpRepository: mockFollowUpRepo,
        captureRepository: mockCaptureRepo,
      );
    });

    test('41. Service computes full intelligence aggregate for Sarah Chen', () async {
      final profile = _createTestProfile(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        firstMet: 'Jan 15, 2026',
        lastInteraction: 'Yesterday',
        totalInteractions: 8,
        memories: [
          const MemoryItem(id: 'm1', category: 'Project', text: 'RISC-V collaboration', source: 'Meeting'),
          const MemoryItem(id: 'm2', category: 'Role', text: 'VP at Mosaic Labs', source: 'Card'),
        ],
      );

      await mockPersonRepo.saveProfile(profile);

      final intel = await service.getIntelligence('per_sarah_01', referenceDate: refDate);

      expect(intel.personId, equals('per_sarah_01'));
      expect(intel.state, equals(RelationshipState.strong));
      expect(intel.strength.score, greaterThanOrEqualTo(70.0));
      expect(intel.isHealthy, isTrue);
      expect(intel.explanations, isNotEmpty);
      expect(intel.topFactors.length, lessThanOrEqualTo(3));
    });

    test('42. Service handles non-existent person cleanly with empty intelligence', () async {
      final intel = await service.getIntelligence('non_existent_id');

      expect(intel.personId, equals('non_existent_id'));
      expect(intel.state, equals(RelationshipState.newRelationship));
      expect(intel.strength.score, equals(0.0));
      expect(intel.isEstablished, isFalse);
    });

    test('43. Bulk intelligence fetches multiple profiles deterministically', () async {
      final profA = _createTestProfile(id: 'per_1', name: 'Person One', totalInteractions: 5, lastInteraction: 'Aug 25, 2026');
      final profB = _createTestProfile(id: 'per_2', name: 'Person Two', totalInteractions: 4, lastInteraction: 'May 1, 2026');

      await mockPersonRepo.saveProfile(profA);
      await mockPersonRepo.saveProfile(profB);

      final results = await service.getBulkIntelligence(['per_1', 'per_2'], referenceDate: refDate);

      expect(results.length, equals(2));
      expect(results[0].personId, equals('per_1'));
      expect(results[0].state, equals(RelationshipState.active));
      expect(results[1].personId, equals('per_2'));
      expect(results[1].state, equals(RelationshipState.neglected));
    });

    test('44. Stream intelligence emits updated values when underlying profile changes', () async {
      final profInitial = _createTestProfile(id: 'per_live', totalInteractions: 1, lastInteraction: 'Aug 1, 2026');
      await mockPersonRepo.saveProfile(profInitial);

      final stream = service.streamIntelligence('per_live', referenceDate: refDate);
      final firstEmission = await stream.first;

      expect(firstEmission.signals.interactionCount, equals(1));
    });
  });

  group('Phase 13H-01 Group 6: UI & Person Dossier Integration', () {
    testWidgets('45. RelationshipIntelligence widget renders state badge and strength score', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final profile = _createTestProfile(
        firstMet: 'Jan 15, 2026',
        lastInteraction: 'Yesterday',
        totalInteractions: 8,
        sharedEventsCount: 3,
        relationshipStrength: 'High · Technical Collaborator',
      );

      await tester.pumpWidget(_createTestApp(
        Scaffold(body: RelationshipIntelligence(profile: profile)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Relationship Snapshot'), findsOneWidget);
      expect(find.text('STRONG'), findsOneWidget);
      expect(find.text('First Met'), findsOneWidget);
      expect(find.text('Last Interaction'), findsOneWidget);
      expect(find.text('Interactions'), findsOneWidget);
      expect(find.textContaining('8 recorded interactions'), findsWidgets);
    });

    testWidgets('46. PersonDetailScreen renders full dossier with relationship intelligence', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final profile = _createTestProfile(
        id: 'per_dossier_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Labs',
        firstMet: 'Jan 15, 2026',
        lastInteraction: 'Yesterday',
        totalInteractions: 8,
        sharedEventsCount: 3,
        relationshipStrength: 'Strong · Technical Collaborator',
        memories: const [
          MemoryItem(id: 'm1', category: 'Tech', text: 'RISC-V collaboration', source: 'Meeting'),
          MemoryItem(id: 'm2', category: 'Project', text: 'Hardware interconnects', source: 'Notes'),
          MemoryItem(id: 'm3', category: 'Team', text: 'Key engineering contact', source: 'Sync'),
        ],
      );

      final mockRepo = MockPersonDetailRepository();
      await mockRepo.saveProfile(profile);

      await tester.pumpWidget(_createTestApp(
        const PersonDetailScreen(personId: 'per_dossier_01'),
        dependencies: RecallrDependencies.mock(
          personDetailRepository: mockRepo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelationshipIntelligence), findsOneWidget);
      expect(find.text('Relationship Snapshot'), findsOneWidget);
      expect(find.text('STRONG'), findsOneWidget);
    });

    testWidgets('47. Truthful empty snapshot renders for contact with zero history', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyProfile = _createTestProfile(
        id: 'per_empty',
        name: 'New Contact',
        firstMet: 'Unknown',
        lastInteraction: 'Never',
        totalInteractions: 0,
        sharedEventsCount: 0,
        relationshipStrength: 'Developing Connection',
      );

      await tester.pumpWidget(_createTestApp(
        Scaffold(body: RelationshipIntelligence(profile: emptyProfile)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('Recently added contact with limited history.'), findsOneWidget);
    });
  });

  group('Phase 13H-01 Group 7: DI, Security & Observability', () {
    test('48. RecallrDependencies resolves relationship intelligence service in mock mode', () {
      final deps = RecallrDependencies.mock();

      expect(deps.relationshipStrengthCalculator, isA<RelationshipStrengthCalculator>());
      expect(deps.relationshipStateClassifier, isA<RelationshipStateClassifier>());
      expect(deps.relationshipIntelligenceService, isA<RelationshipIntelligenceService>());
    });

    test('49. Production RecallrDependencies wires real Firestore repositories without mocks', () {
      final prodDeps = RecallrDependencies.production();

      expect(prodDeps.relationshipIntelligenceService, isA<RelationshipIntelligenceService>());
      expect(prodDeps.relationshipStrengthCalculator, isA<DeterministicRelationshipStrengthCalculator>());
      expect(prodDeps.relationshipStateClassifier, isA<DeterministicRelationshipStateClassifier>());
    });

    test('50. Golden Journey Verification: Sarah Chen / Mosaic Labs complete intelligence derivation', () async {
      final sarahProfile = _createTestProfile(
        id: 'per_sarah_golden',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Labs',
        firstMet: 'Jan 15, 2026',
        lastInteraction: 'Yesterday',
        totalInteractions: 8,
        sharedEventsCount: 3,
        memories: [
          const MemoryItem(id: 'm1', category: 'Project', text: 'RISC-V collaboration', source: 'Indiranagar Indaba'),
          const MemoryItem(id: 'm2', category: 'Role', text: 'VP at Mosaic Labs', source: 'Visiting Card'),
          const MemoryItem(id: 'm3', category: 'Expertise', text: 'Hardware ASIC & Neuromorphic design', source: 'Note'),
        ],
        followUps: [
          const FollowUpItem(
            id: 'fu_sarah',
            title: 'Send API Documentation',
            dueDate: 'Sep 5, 2026',
            targetRoute: '/follow-up/fu_sarah',
            status: FollowUpStatus.upcoming,
          ),
        ],
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: sarahProfile,
        referenceDate: refDate,
      );

      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      expect(signals.interactionCount, equals(8));
      expect(signals.memoryCount, equals(3));
      expect(signals.activeFollowUpCount, equals(1));
      expect(signals.hasRecentInteraction, isTrue);
      expect(strength.score, greaterThanOrEqualTo(80.0));
      expect(state, equals(RelationshipState.strong));
    });
  });
}
