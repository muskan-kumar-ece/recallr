import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/core/widgets/widgets.dart';
import 'package:recaller/features/home/widgets/relationship_attention_section.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/services/relationship/relationship_action_engine.dart';
import 'package:recaller/services/relationship/relationship_action_explanation.dart';
import 'package:recaller/services/relationship/relationship_action_priority_calculator.dart';
import 'package:recaller/services/relationship/relationship_state_classifier.dart';
import 'package:recaller/services/relationship/relationship_strength_calculator.dart';

void main() {
  group('Phase 13H-02 — Relationship Action Domain Models', () {
    test('RelationshipActionType has expected labels and icons', () {
      expect(RelationshipActionType.reconnect.label, equals('Reconnect'));
      expect(RelationshipActionType.reconnect.icon, equals(Icons.sync_alt_rounded));

      expect(RelationshipActionType.completeOverdueFollowUp.label, equals('Complete Overdue Commitment'));
      expect(RelationshipActionType.completeOverdueFollowUp.icon, equals(Icons.error_outline_rounded));

      expect(RelationshipActionType.followUp.label, equals('Follow-up'));
      expect(RelationshipActionType.reviewRelationship.label, equals('Relationship Review'));
      expect(RelationshipActionType.reviewRecentInteraction.label, equals('Review Interaction'));
      expect(RelationshipActionType.captureMissingContext.label, equals('Capture Missing Details'));
    });

    test('RelationshipActionPriority has correct ranks and color tokens', () {
      expect(RelationshipActionPriority.urgent.rank, equals(4));
      expect(RelationshipActionPriority.high.rank, equals(3));
      expect(RelationshipActionPriority.medium.rank, equals(2));
      expect(RelationshipActionPriority.low.rank, equals(1));

      expect(RelationshipActionPriority.urgent.badgeLabel, equals('URGENT'));
      expect(RelationshipActionPriority.high.badgeLabel, equals('HIGH'));
      expect(RelationshipActionPriority.medium.badgeLabel, equals('MEDIUM'));
      expect(RelationshipActionPriority.low.badgeLabel, equals('LOW'));

      expect(RelationshipActionPriority.urgent.colorToken, equals(RecallrColors.crimsonAlert));
      expect(RelationshipActionPriority.high.colorToken, equals(RecallrColors.warmAmberGold));
      expect(RelationshipActionPriority.medium.colorToken, equals(RecallrColors.aiCyanHighlight));
      expect(RelationshipActionPriority.low.colorToken, equals(RecallrColors.textSecondary));
    });

    test('RelationshipActionStatus lifecycle values', () {
      expect(RelationshipActionStatus.suggested.label, equals('Suggested'));
      expect(RelationshipActionStatus.dismissed.label, equals('Dismissed'));
      expect(RelationshipActionStatus.snoozed.label, equals('Snoozed'));
      expect(RelationshipActionStatus.completed.label, equals('Completed'));
    });

    test('RelationshipAction serialization round-trip fidelity', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final action = RelationshipAction(
        id: 'action_p1_reconnect_cooling',
        personId: 'p1',
        personName: 'Sarah Chen',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.high,
        status: RelationshipActionStatus.suggested,
        title: 'Reconnect with Sarah Chen',
        description: 'Last interaction was 47 days ago.',
        reason: 'Relationship state is Cooling.',
        recommendedAt: 'This week',
        targetRoute: '/person/p1',
        relationshipState: RelationshipState.cooling,
        relationshipScore: 68.0,
        deduplicationKey: 'action_p1_reconnect_cooling',
        generatedAt: now,
      );

      final map = action.toMap();
      final reconstructed = RelationshipAction.fromMap(map);

      expect(reconstructed.id, equals('action_p1_reconnect_cooling'));
      expect(reconstructed.personId, equals('p1'));
      expect(reconstructed.personName, equals('Sarah Chen'));
      expect(reconstructed.type, equals(RelationshipActionType.reconnect));
      expect(reconstructed.priority, equals(RelationshipActionPriority.high));
      expect(reconstructed.status, equals(RelationshipActionStatus.suggested));
      expect(reconstructed.title, equals('Reconnect with Sarah Chen'));
      expect(reconstructed.relationshipState, equals(RelationshipState.cooling));
      expect(reconstructed.relationshipScore, equals(68.0));
      expect(reconstructed.isSuggested, isTrue);
      expect(reconstructed.isHighPriority, isTrue);
    });

    test('RelationshipAction copyWith overrides targeted fields', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final action = RelationshipAction(
        id: 'act_1',
        personId: 'p1',
        personName: 'Sarah Chen',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.medium,
        title: 'Reconnect',
        description: 'Desc',
        reason: 'Reason',
        recommendedAt: 'Soon',
        targetRoute: '/person/p1',
        deduplicationKey: 'key_1',
        generatedAt: now,
      );

      final updated = action.copyWith(
        priority: RelationshipActionPriority.urgent,
        status: RelationshipActionStatus.completed,
      );

      expect(updated.id, equals('act_1'));
      expect(updated.priority, equals(RelationshipActionPriority.urgent));
      expect(updated.status, equals(RelationshipActionStatus.completed));
      expect(updated.isHighPriority, isTrue);
      expect(updated.isSuggested, isFalse);
    });
  });

  group('Phase 13H-02 — Deterministic Priority Calculator', () {
    const calc = DeterministicRelationshipActionPriorityCalculator();

    test('Overdue follow-up on strong relationship is URGENT', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 8,
          memoryCount: 4,
          captureCount: 2,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 82.0, factors: [], level: 'Strong', summary: ''),
        state: RelationshipState.strong,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.completeOverdueFollowUp,
      );
      expect(priority, equals(RelationshipActionPriority.urgent));
    });

    test('Multiple overdue follow-ups is URGENT', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 3,
          memoryCount: 1,
          captureCount: 0,
          activeFollowUpCount: 2,
          overdueFollowUpCount: 2,
          daysSinceLastInteraction: 20,
        ),
        strength: const RelationshipStrength(score: 55.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.completeOverdueFollowUp,
      );
      expect(priority, equals(RelationshipActionPriority.urgent));
    });

    test('Single overdue follow-up on normal active relationship is HIGH', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 2,
          memoryCount: 1,
          captureCount: 0,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 15,
        ),
        strength: const RelationshipStrength(score: 45.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.completeOverdueFollowUp,
      );
      expect(priority, equals(RelationshipActionPriority.high));
    });

    test('Neglected relationship with interaction history is HIGH priority reconnect', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 6,
          memoryCount: 3,
          captureCount: 1,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 110,
        ),
        strength: const RelationshipStrength(score: 62.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.neglected,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(priority, equals(RelationshipActionPriority.high));
    });

    test('Cooling relationship with high score is HIGH priority reconnect', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 5,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 45,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(priority, equals(RelationshipActionPriority.high));
    });

    test('Cooling relationship with standard score is MEDIUM priority reconnect', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 2,
          memoryCount: 1,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 40,
        ),
        strength: const RelationshipStrength(score: 40.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(priority, equals(RelationshipActionPriority.medium));
    });

    test('Dormant relationship is LOW priority reconnect', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 1,
          memoryCount: 0,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 200,
        ),
        strength: const RelationshipStrength(score: 15.0, factors: [], level: 'Dormant', summary: ''),
        state: RelationshipState.dormant,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(priority, equals(RelationshipActionPriority.low));
    });

    test('Recent interaction within trailing 48h is MEDIUM priority review', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 3,
          memoryCount: 1,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 1,
        ),
        strength: const RelationshipStrength(score: 50.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reviewRecentInteraction,
      );
      expect(priority, equals(RelationshipActionPriority.medium));
    });

    test('Sparse context contact with multiple interactions is MEDIUM priority capture', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p1',
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 0,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 45.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = calc.calculate(
        intelligence: intel,
        type: RelationshipActionType.captureMissingContext,
      );
      expect(priority, equals(RelationshipActionPriority.medium));
    });
  });

  group('Phase 13H-02 — Relationship Action Explanation Generator', () {
    const profile = PersonProfile(
      id: 'per_sarah',
      name: 'Sarah Chen',
      role: 'VP AI Engineering',
      company: 'NexusAI',
      location: 'San Francisco',
      initials: 'SC',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'Strong',
      firstMet: '2025-01-10',
      lastInteraction: '47 days ago',
      totalInteractions: 8,
      sharedEventsCount: 2,
      aiSummary: 'Technical leader focused on AI models.',
    );

    test('Generates grounded action titles for all types', () {
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.reconnect),
        equals('Reconnect with Sarah Chen'),
      );
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.completeOverdueFollowUp),
        equals('Complete Overdue Commitment for Sarah Chen'),
      );
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.followUp),
        equals('Follow up with Sarah Chen'),
      );
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.reviewRelationship),
        equals('Review Relationship with Sarah Chen'),
      );
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.reviewRecentInteraction),
        equals('Review Recent Interaction with Sarah Chen'),
      );
      expect(
        RelationshipActionExplanation.generateTitle(profile: profile, type: RelationshipActionType.captureMissingContext),
        equals('Capture Details for Sarah Chen'),
      );
    });

    test('Generates grounded description for cooling relationship', () {
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 8,
          memoryCount: 4,
          captureCount: 2,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 47,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final desc = RelationshipActionExplanation.generateDescription(
        profile: profile,
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(desc, contains('47 days ago'));
      expect(desc, contains('8 recorded interactions'));
    });

    test('Generates grounded description for overdue commitments', () {
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 10,
        ),
        strength: const RelationshipStrength(score: 55.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final desc = RelationshipActionExplanation.generateDescription(
        profile: profile,
        intelligence: intel,
        type: RelationshipActionType.completeOverdueFollowUp,
      );
      expect(desc, contains('1 overdue commitment with Sarah Chen'));
    });

    test('Generates evidence reason with state and interaction count', () {
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 8,
          memoryCount: 4,
          captureCount: 2,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 47,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final reason = RelationshipActionExplanation.generateReason(
        profile: profile,
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(reason, contains('Cooling'));
      expect(reason, contains('47d since last contact'));
      expect(reason, contains('8 previous interactions'));
    });

    test('Calculates recommended timing accurately', () {
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 8,
          memoryCount: 4,
          captureCount: 2,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 47,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      expect(
        RelationshipActionExplanation.calculateRecommendedTiming(
          type: RelationshipActionType.completeOverdueFollowUp,
          priority: RelationshipActionPriority.urgent,
          intelligence: intel,
        ),
        equals('Today'),
      );

      expect(
        RelationshipActionExplanation.calculateRecommendedTiming(
          type: RelationshipActionType.reviewRecentInteraction,
          priority: RelationshipActionPriority.medium,
          intelligence: intel,
        ),
        equals('Today'),
      );

      expect(
        RelationshipActionExplanation.calculateRecommendedTiming(
          type: RelationshipActionType.reconnect,
          priority: RelationshipActionPriority.high,
          intelligence: intel,
        ),
        equals('Within 2–3 days'),
      );

      expect(
        RelationshipActionExplanation.calculateRecommendedTiming(
          type: RelationshipActionType.reconnect,
          priority: RelationshipActionPriority.medium,
          intelligence: intel,
        ),
        equals('Within this week'),
      );
    });
  });

  group('Phase 13H-02 — Deterministic Relationship Action Engine', () {
    const engine = DeterministicRelationshipActionEngine();

    test('Evaluates completeOverdueFollowUp when contact has overdue follow-ups', () {
      const profile = PersonProfile(
        id: 'per_arjun',
        name: 'Arjun Mehta',
        role: 'Founder',
        company: 'Veloce',
        location: 'Bengaluru',
        initials: 'AM',
        relationshipType: RelationshipContextType.founder,
        relationshipStrength: 'Active',
        firstMet: '2025-06-01',
        lastInteraction: '10 days ago',
        totalInteractions: 4,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 10,
        ),
        strength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.isNotEmpty, isTrue);

      final overdueAction = actions.firstWhere((a) => a.type == RelationshipActionType.completeOverdueFollowUp);
      expect(overdueAction.personId, equals('per_arjun'));
      expect(overdueAction.personName, equals('Arjun Mehta'));
      expect(overdueAction.priority, equals(RelationshipActionPriority.high));
      expect(overdueAction.recommendedAt, equals('Today'));
      expect(overdueAction.deduplicationKey, contains('action_per_arjun_completeOverdueFollowUp'));
    });

    test('Evaluates reconnect for cooling contact with rich history', () {
      const profile = PersonProfile(
        id: 'per_sarah',
        name: 'Sarah Chen',
        role: 'VP AI Engineering',
        company: 'NexusAI',
        location: 'San Francisco',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2025-01-10',
        lastInteraction: '47 days ago',
        totalInteractions: 8,
        sharedEventsCount: 2,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 8,
          memoryCount: 4,
          captureCount: 2,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 47,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.isNotEmpty, isTrue);

      final reconnectAction = actions.firstWhere((a) => a.type == RelationshipActionType.reconnect);
      expect(reconnectAction.personId, equals('per_sarah'));
      expect(reconnectAction.priority, equals(RelationshipActionPriority.high));
      expect(reconnectAction.deduplicationKey, contains('action_per_sarah_reconnect_cooling_47_8'));
    });

    test('Does NOT evaluate reconnect for brand new contact with 0 history', () {
      const profile = PersonProfile(
        id: 'per_new',
        name: 'New Contact',
        role: 'Engineer',
        company: 'Acme',
        location: 'Remote',
        initials: 'NC',
        relationshipType: RelationshipContextType.colleague,
        relationshipStrength: 'New Connection',
        firstMet: 'Today',
        lastInteraction: 'Never',
        totalInteractions: 0,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 0,
          memoryCount: 0,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: null,
        ),
        strength: const RelationshipStrength(score: 0.0, factors: [], level: 'New', summary: ''),
        state: RelationshipState.newRelationship,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.isEmpty, isTrue);
    });

    test('Evaluates reviewRecentInteraction for interaction within trailing 48h', () {
      const profile = PersonProfile(
        id: 'per_recent',
        name: 'Elena Rostova',
        role: 'Principal Architect',
        company: 'DataScale',
        location: 'Zurich',
        initials: 'ER',
        relationshipType: RelationshipContextType.advisor,
        relationshipStrength: 'Active',
        firstMet: '2025-02-01',
        lastInteraction: '1 day ago',
        totalInteractions: 3,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 3,
          memoryCount: 2,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 1,
        ),
        strength: const RelationshipStrength(score: 65.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.reviewRecentInteraction), isTrue);
    });

    test('Evaluates captureMissingContext for contact with 3+ interactions and 0 memories', () {
      const profile = PersonProfile(
        id: 'per_sparse',
        name: 'David Kim',
        role: 'Designer',
        company: 'Studio',
        location: 'Seoul',
        initials: 'DK',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2025-03-01',
        lastInteraction: '5 days ago',
        totalInteractions: 4,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 0,
          captureCount: 0,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 50.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.captureMissingContext), isTrue);
    });

    test('Evaluates reviewRelationship for strong relationship with 20 days since contact', () {
      const profile = PersonProfile(
        id: 'per_strong',
        name: 'Maria Garcia',
        role: 'Director',
        company: 'VentureX',
        location: 'Madrid',
        initials: 'MG',
        relationshipType: RelationshipContextType.investor,
        relationshipStrength: 'Strong',
        firstMet: '2024-11-01',
        lastInteraction: '20 days ago',
        totalInteractions: 12,
        sharedEventsCount: 3,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 12,
          memoryCount: 6,
          captureCount: 2,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 20,
        ),
        strength: const RelationshipStrength(score: 85.0, factors: [], level: 'Strong', summary: ''),
        state: RelationshipState.strong,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.reviewRelationship), isTrue);
    });

    test('Deduplication keys are deterministic and reproducible across multiple evaluations', () {
      const profile = PersonProfile(
        id: 'per_dedup',
        name: 'Marcus Vance',
        role: 'Executive',
        company: 'GlobalCorp',
        location: 'New York',
        initials: 'MV',
        relationshipType: RelationshipContextType.mentor,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '40 days ago',
        totalInteractions: 5,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 5,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 40,
        ),
        strength: const RelationshipStrength(score: 65.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final eval1 = engine.evaluateActions(profile, intel);
      final eval2 = engine.evaluateActions(profile, intel);

      expect(eval1.length, equals(eval2.length));
      for (int i = 0; i < eval1.length; i++) {
        expect(eval1[i].deduplicationKey, equals(eval2[i].deduplicationKey));
        expect(eval1[i].id, equals(eval2[i].id));
      }
    });

    test('Actions are strictly ordered by priority rank (highest first)', () {
      const profile = PersonProfile(
        id: 'per_multi',
        name: 'Multi Action Contact',
        role: 'Founder',
        company: 'ScaleCo',
        location: 'Austin',
        initials: 'MC',
        relationshipType: RelationshipContextType.founder,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '1 day ago',
        totalInteractions: 4,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      // Contact has both an overdue follow-up (URGENT/HIGH) and a recent interaction (MEDIUM)
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 1,
        ),
        strength: const RelationshipStrength(score: 75.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.length, greaterThanOrEqualTo(2));
      for (int i = 0; i < actions.length - 1; i++) {
        expect(actions[i].priority.rank, greaterThanOrEqualTo(actions[i + 1].priority.rank));
      }
    });

    test('getPrimaryAction returns highest priority action', () {
      const profile = PersonProfile(
        id: 'per_primary',
        name: 'Primary Contact',
        role: 'Partner',
        company: 'VC',
        location: 'SF',
        initials: 'PC',
        relationshipType: RelationshipContextType.investor,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '1 day ago',
        totalInteractions: 4,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 4,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 1,
        ),
        strength: const RelationshipStrength(score: 75.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final primary = engine.getPrimaryAction(profile, intel);
      expect(primary, isNotNull);
      expect(primary!.type, equals(RelationshipActionType.completeOverdueFollowUp));
    });

    test('getPrimaryAction returns null for contact with no eligible actions', () {
      const profile = PersonProfile(
        id: 'per_none',
        name: 'No Action Contact',
        role: 'Client',
        company: 'Corp',
        location: 'Chicago',
        initials: 'NA',
        relationshipType: RelationshipContextType.client,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '5 days ago',
        totalInteractions: 2,
        sharedEventsCount: 1,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 2,
          memoryCount: 2,
          captureCount: 1,
          activeFollowUpCount: 0,
          overdueFollowUpCount: 0,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 55.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final primary = engine.getPrimaryAction(profile, intel);
      expect(primary, isNull);
    });
  });

  group('Phase 13H-02 — UI Widget Integrations', () {
    const profile = PersonProfile(
      id: 'per_ui_test',
      name: 'Sarah Chen',
      role: 'VP AI Engineering',
      company: 'NexusAI',
      location: 'San Francisco',
      initials: 'SC',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'Active',
      firstMet: '2025-01-10',
      lastInteraction: '47 days ago',
      totalInteractions: 8,
      sharedEventsCount: 2,
      aiSummary: 'Technical leader.',
    );

    final action = RelationshipAction(
      id: 'action_sarah_reconnect',
      personId: profile.id,
      personName: profile.name,
      type: RelationshipActionType.reconnect,
      priority: RelationshipActionPriority.high,
      status: RelationshipActionStatus.suggested,
      title: 'Reconnect with Sarah Chen',
      description: 'Your last interaction was 47 days ago. You have 8 recorded interactions together.',
      reason: 'Relationship state is Cooling.',
      recommendedAt: 'Within 2–3 days',
      targetRoute: '/person/per_ui_test',
      relationshipState: RelationshipState.cooling,
      relationshipScore: 68.0,
      deduplicationKey: 'action_sarah_reconnect',
      generatedAt: DateTime.now(),
    );

    testWidgets('RelationshipIntelligence renders RECOMMENDED NEXT STEP card when action is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipIntelligence(
                profile: profile,
                primaryAction: action,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECOMMENDED NEXT STEP'), findsOneWidget);
      expect(find.text('Reconnect with Sarah Chen'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Recommended: Within 2–3 days'), findsOneWidget);
      expect(find.text('Create Follow-up'), findsOneWidget);
    });

    testWidgets('RelationshipIntelligence hides RECOMMENDED NEXT STEP card when primaryAction is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: RelationshipIntelligence(
                profile: profile,
                primaryAction: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECOMMENDED NEXT STEP'), findsNothing);
    });

    testWidgets('RelationshipIntelligence triggers onCreateFollowUp callback when button tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipIntelligence(
                profile: profile,
                primaryAction: action,
                onCreateFollowUp: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(RecallrButton, 'Create Follow-up');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('RelationshipAttentionSection renders list of actions in Home Command Center', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipAttentionSection(
                actions: [action],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Relationship Attention'), findsOneWidget);
      expect(find.text('1 Action'), findsOneWidget);
      expect(find.text('Sarah Chen'), findsOneWidget);
      expect(find.text('Reconnect with Sarah Chen'), findsOneWidget);
      expect(find.text('View Person'), findsOneWidget);
      expect(find.text('Create Follow-up'), findsOneWidget);
    });

    testWidgets('RelationshipAttentionSection renders SizedBox.shrink when actions list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RelationshipAttentionSection(
              actions: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Relationship Attention'), findsNothing);
    });

    testWidgets('RelationshipAttentionSection triggers callbacks when action buttons tapped', (tester) async {
      bool viewTapped = false;
      bool createTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipAttentionSection(
                actions: [action],
                onActionTap: (_) => viewTapped = true,
                onCreateFollowUp: (_) => createTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Person'));
      await tester.pumpAndSettle();
      expect(viewTapped, isTrue);

      await tester.tap(find.text('Create Follow-up'));
      await tester.pumpAndSettle();
      expect(createTapped, isTrue);
    });
  });

  group('Phase 13H-02 — Deep Edge Cases & Integration Tests', () {
    const engine = DeterministicRelationshipActionEngine();
    const priorityCalc = DeterministicRelationshipActionPriorityCalculator();

    test('fromMap handles missing or malformed fields gracefully with safe fallbacks', () {
      final minimalMap = <String, dynamic>{
        'personId': 'per_fallback',
        'personName': 'Fallback Contact',
      };

      final action = RelationshipAction.fromMap(minimalMap, 'doc_fallback');
      expect(action.id, equals('doc_fallback'));
      expect(action.personId, equals('per_fallback'));
      expect(action.personName, equals('Fallback Contact'));
      expect(action.type, equals(RelationshipActionType.followUp));
      expect(action.priority, equals(RelationshipActionPriority.medium));
      expect(action.status, equals(RelationshipActionStatus.suggested));
      expect(action.relationshipState, equals(RelationshipState.newRelationship));
      expect(action.relationshipScore, equals(0.0));
      expect(action.recommendedAt, equals('Soon'));
    });

    test('Explanation handles contact with empty name without throwing', () {
      const emptyProfile = PersonProfile(
        id: 'per_empty',
        name: '',
        role: 'Unknown',
        company: '',
        location: '',
        initials: '?',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'New',
        firstMet: '',
        lastInteraction: '',
        totalInteractions: 0,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final title = RelationshipActionExplanation.generateTitle(
        profile: emptyProfile,
        type: RelationshipActionType.reconnect,
      );
      expect(title, equals('Reconnect with Contact'));

      final intel = PersonRelationshipIntelligence(
        personId: 'per_empty',
        signals: const RelationshipSignals(interactionCount: 0),
        strength: const RelationshipStrength(score: 0.0, factors: [], level: 'New', summary: ''),
        state: RelationshipState.newRelationship,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final desc = RelationshipActionExplanation.generateDescription(
        profile: emptyProfile,
        intelligence: intel,
        type: RelationshipActionType.reconnect,
      );
      expect(desc, contains('this contact'));
    });

    test('Boundary: contact with 1 interaction and 0 memories is not eligible for reconnect', () {
      const profile = PersonProfile(
        id: 'per_single',
        name: 'Single Interaction',
        role: 'Founder',
        company: 'Seed',
        location: 'NYC',
        initials: 'SI',
        relationshipType: RelationshipContextType.founder,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '40 days ago',
        totalInteractions: 1,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 1,
          memoryCount: 0,
          captureCount: 0,
          daysSinceLastInteraction: 40,
        ),
        strength: const RelationshipStrength(score: 25.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.reconnect), isFalse);
    });

    test('Boundary: contact with 1 interaction but 1 saved memory IS eligible for reconnect when cooling', () {
      const profile = PersonProfile(
        id: 'per_mem',
        name: 'Mem Contact',
        role: 'Advisor',
        company: 'Advisors Inc',
        location: 'NYC',
        initials: 'MC',
        relationshipType: RelationshipContextType.advisor,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '40 days ago',
        totalInteractions: 1,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 1,
          memoryCount: 1,
          captureCount: 0,
          daysSinceLastInteraction: 40,
        ),
        strength: const RelationshipStrength(score: 35.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.reconnect), isTrue);
    });

    test('Boundary: contact with 3 interactions and 1 memory does not trigger captureMissingContext', () {
      const profile = PersonProfile(
        id: 'per_not_sparse',
        name: 'Has Context',
        role: 'Engineer',
        company: 'Tech',
        location: 'SF',
        initials: 'HC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '5 days ago',
        totalInteractions: 3,
        sharedEventsCount: 0,
        aiSummary: '',
      );

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 3,
          memoryCount: 1,
          captureCount: 0,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 50.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.any((a) => a.type == RelationshipActionType.captureMissingContext), isFalse);
    });

    test('Priority calculation: followUp on active relationship returns medium priority', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p_active',
        signals: const RelationshipSignals(
          interactionCount: 2,
          activeFollowUpCount: 1,
          daysSinceLastInteraction: 5,
        ),
        strength: const RelationshipStrength(score: 45.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = priorityCalc.calculate(
        intelligence: intel,
        type: RelationshipActionType.followUp,
      );
      expect(priority, equals(RelationshipActionPriority.medium));
    });

    test('Priority calculation: reviewRelationship on strong relationship returns medium priority', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'p_strong',
        signals: const RelationshipSignals(
          interactionCount: 10,
          memoryCount: 5,
          daysSinceLastInteraction: 20,
        ),
        strength: const RelationshipStrength(score: 80.0, factors: [], level: 'Strong', summary: ''),
        state: RelationshipState.strong,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final priority = priorityCalc.calculate(
        intelligence: intel,
        type: RelationshipActionType.reviewRelationship,
      );
      expect(priority, equals(RelationshipActionPriority.medium));
    });

    test('Snoozing or dismissing action does not modify other action properties', () {
      final action = RelationshipAction(
        id: 'act_snooze',
        personId: 'p1',
        personName: 'Contact',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.medium,
        title: 'Title',
        description: 'Desc',
        reason: 'Reason',
        recommendedAt: 'Soon',
        targetRoute: '/person/p1',
        deduplicationKey: 'key_snooze',
        generatedAt: DateTime.now(),
      );

      final snoozed = action.copyWith(status: RelationshipActionStatus.snoozed);
      expect(snoozed.status, equals(RelationshipActionStatus.snoozed));
      expect(snoozed.isSuggested, isFalse);
      expect(snoozed.title, equals(action.title));
      expect(snoozed.deduplicationKey, equals(action.deduplicationKey));

      final dismissed = action.copyWith(status: RelationshipActionStatus.dismissed);
      expect(dismissed.status, equals(RelationshipActionStatus.dismissed));
      expect(dismissed.isSuggested, isFalse);
    });

    test('Deterministic pipeline: StrengthCalc -> StateClassifier -> ActionEngine yields consistent results', () {
      const profile = PersonProfile(
        id: 'per_pipe',
        name: 'Pipeline Contact',
        role: 'VP AI',
        company: 'Nexus',
        location: 'SF',
        initials: 'PC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '45 days ago',
        totalInteractions: 6,
        sharedEventsCount: 1,
        memories: [
          MemoryItem(
            id: 'm1',
            category: 'Notes',
            text: 'Discussed model architecture',
            source: 'Meeting Note',
          ),
        ],
        aiSummary: '',
      );

      final signals = RelationshipSignals.fromDomainData(profile: profile);
      const strengthCalc = DeterministicRelationshipStrengthCalculator();
      const stateClassifier = DeterministicRelationshipStateClassifier();

      final strength = strengthCalc.calculate(signals);
      final state = stateClassifier.classify(signals: signals, strength: strength);

      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: signals,
        strength: strength,
        state: state,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final primary = engine.getPrimaryAction(profile, intel);
      expect(primary, isNotNull);
      expect(primary!.type, equals(RelationshipActionType.reconnect));
      expect(primary.priority, equals(RelationshipActionPriority.high));
      expect(primary.relationshipState, equals(RelationshipState.cooling));
    });

    test('Priority rank order sorting comparator works symmetrically', () {
      final list = [
        RelationshipActionPriority.low,
        RelationshipActionPriority.urgent,
        RelationshipActionPriority.medium,
        RelationshipActionPriority.high,
      ];
      list.sort((a, b) => b.rank.compareTo(a.rank));

      expect(list[0], equals(RelationshipActionPriority.urgent));
      expect(list[1], equals(RelationshipActionPriority.high));
      expect(list[2], equals(RelationshipActionPriority.medium));
      expect(list[3], equals(RelationshipActionPriority.low));
    });

    test('Multiple overdue follow-ups explanation formats plural commitments', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'per_multi_overdue',
        signals: const RelationshipSignals(
          interactionCount: 4,
          overdueFollowUpCount: 3,
        ),
        strength: const RelationshipStrength(score: 50.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final desc = RelationshipActionExplanation.generateDescription(
        profile: const PersonProfile(
          id: 'per_multi_overdue',
          name: 'Priya Patel',
          role: 'Engineer',
          company: 'Tech',
          location: 'SF',
          initials: 'PP',
          relationshipType: RelationshipContextType.colleague,
          relationshipStrength: 'Active',
          firstMet: '',
          lastInteraction: '',
          totalInteractions: 4,
          sharedEventsCount: 0,
          aiSummary: '',
        ),
        intelligence: intel,
        type: RelationshipActionType.completeOverdueFollowUp,
      );

      expect(desc, contains('3 overdue commitments with Priya Patel'));
    });

    test('Recent interaction on same day (days=0) generates "interacted today" copy', () {
      final intel = PersonRelationshipIntelligence(
        personId: 'per_today',
        signals: const RelationshipSignals(
          interactionCount: 2,
          daysSinceLastInteraction: 0,
        ),
        strength: const RelationshipStrength(score: 60.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.active,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final desc = RelationshipActionExplanation.generateDescription(
        profile: const PersonProfile(
          id: 'per_today',
          name: 'Tom Zhao',
          role: 'Founder',
          company: 'Acme',
          location: 'SF',
          initials: 'TZ',
          relationshipType: RelationshipContextType.founder,
          relationshipStrength: 'Active',
          firstMet: '',
          lastInteraction: 'Today',
          totalInteractions: 2,
          sharedEventsCount: 0,
          aiSummary: '',
        ),
        intelligence: intel,
        type: RelationshipActionType.reviewRecentInteraction,
      );

      expect(desc, contains('interacted with Tom Zhao today'));
    });

    test('Multi-action qualification generates multiple prioritized actions for a single contact', () {
      const profile = PersonProfile(
        id: 'per_multi_qual',
        name: 'Multi Qual Contact',
        role: 'Founder',
        company: 'Veloce',
        location: 'Bengaluru',
        initials: 'MQ',
        relationshipType: RelationshipContextType.founder,
        relationshipStrength: 'Active',
        firstMet: '2025-01-01',
        lastInteraction: '45 days ago',
        totalInteractions: 6,
        sharedEventsCount: 1,
        memories: [
          MemoryItem(
            id: 'm1',
            category: 'Notes',
            text: 'Context notes',
            source: 'Note',
          ),
        ],
        aiSummary: '',
      );

      // Contact has both an overdue follow-up and is cooling with history
      final intel = PersonRelationshipIntelligence(
        personId: profile.id,
        signals: const RelationshipSignals(
          interactionCount: 6,
          memoryCount: 1,
          activeFollowUpCount: 1,
          overdueFollowUpCount: 1,
          daysSinceLastInteraction: 45,
        ),
        strength: const RelationshipStrength(score: 68.0, factors: [], level: 'Active', summary: ''),
        state: RelationshipState.cooling,
        generatedAt: DateTime.now(),
        explanations: const [],
        topFactors: const [],
      );

      final actions = engine.evaluateActions(profile, intel);
      expect(actions.length, greaterThanOrEqualTo(2));
      expect(actions.any((a) => a.type == RelationshipActionType.completeOverdueFollowUp), isTrue);
      expect(actions.any((a) => a.type == RelationshipActionType.reconnect), isTrue);
      expect(actions.first.priority.rank, greaterThanOrEqualTo(actions.last.priority.rank));
    });

    testWidgets('RelationshipAttentionSection renders up to 3 action cards simultaneously without layout crash', (tester) async {
      final action1 = RelationshipAction(
        id: 'act_1',
        personId: 'p1',
        personName: 'Contact 1',
        type: RelationshipActionType.completeOverdueFollowUp,
        priority: RelationshipActionPriority.urgent,
        title: 'Overdue Commitment 1',
        description: 'Desc 1',
        reason: 'Reason 1',
        recommendedAt: 'Today',
        targetRoute: '/person/p1',
        deduplicationKey: 'key_1',
        generatedAt: DateTime.now(),
      );

      final action2 = RelationshipAction(
        id: 'act_2',
        personId: 'p2',
        personName: 'Contact 2',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.high,
        title: 'Reconnect 2',
        description: 'Desc 2',
        reason: 'Reason 2',
        recommendedAt: 'This week',
        targetRoute: '/person/p2',
        deduplicationKey: 'key_2',
        generatedAt: DateTime.now(),
      );

      final action3 = RelationshipAction(
        id: 'act_3',
        personId: 'p3',
        personName: 'Contact 3',
        type: RelationshipActionType.reviewRecentInteraction,
        priority: RelationshipActionPriority.medium,
        title: 'Review 3',
        description: 'Desc 3',
        reason: 'Reason 3',
        recommendedAt: 'Today',
        targetRoute: '/person/p3',
        deduplicationKey: 'key_3',
        generatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipAttentionSection(
                actions: [action1, action2, action3],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Relationship Attention'), findsOneWidget);
      expect(find.text('3 Actions'), findsOneWidget);
      expect(find.text('Contact 1'), findsOneWidget);
      expect(find.text('Contact 2'), findsOneWidget);
      expect(find.text('Contact 3'), findsOneWidget);
    });

    test('copyWith targetRoute correctly updates navigation path', () {
      final action = RelationshipAction(
        id: 'act_route',
        personId: 'p1',
        personName: 'Contact',
        type: RelationshipActionType.reconnect,
        priority: RelationshipActionPriority.medium,
        title: 'Title',
        description: 'Desc',
        reason: 'Reason',
        recommendedAt: 'Soon',
        targetRoute: '/person/p1',
        deduplicationKey: 'key_route',
        generatedAt: DateTime.now(),
      );

      final updated = action.copyWith(targetRoute: '/person/custom_p1');
      expect(updated.targetRoute, equals('/person/custom_p1'));
      expect(updated.personId, equals('p1'));
    });
  });
}
