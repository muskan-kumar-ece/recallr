import 'package:flutter/foundation.dart';
import 'relationship_signals.dart';
import 'relationship_state.dart';
import 'relationship_strength.dart';

/// Canonical aggregate model for derived relationship intelligence for a person.
@immutable
class PersonRelationshipIntelligence {
  final String personId;
  final RelationshipSignals signals;
  final RelationshipStrength strength;
  final RelationshipState state;
  final DateTime generatedAt;
  final List<String> explanations;
  final List<StrengthFactor> topFactors;

  const PersonRelationshipIntelligence({
    required this.personId,
    required this.signals,
    required this.strength,
    required this.state,
    required this.generatedAt,
    required this.explanations,
    required this.topFactors,
  });

  /// Factory creating an empty or baseline intelligence object.
  factory PersonRelationshipIntelligence.empty(String personId) {
    return PersonRelationshipIntelligence(
      personId: personId,
      signals: RelationshipSignals.empty(),
      strength: RelationshipStrength.zero(),
      state: RelationshipState.newRelationship,
      generatedAt: DateTime.now(),
      explanations: const [
        'Recently added contact with no recorded interaction history.',
      ],
      topFactors: const [],
    );
  }

  /// Whether this relationship has enough history to be considered established.
  bool get isEstablished =>
      signals.interactionCount >= 2 || signals.memoryCount >= 2;

  /// Whether this relationship is in good standing (Active or Strong).
  bool get isHealthy =>
      state == RelationshipState.active || state == RelationshipState.strong;

  /// Whether this relationship requires attention (Cooling or Neglected).
  bool get requiresAttention =>
      state == RelationshipState.cooling || state == RelationshipState.neglected;

  Map<String, dynamic> toMap() => {
    'personId': personId,
    'state': state.toValue(),
    'strengthScore': strength.score,
    'strengthLevel': strength.level,
    'explanations': explanations,
    'generatedAt': generatedAt.toIso8601String(),
  };

  Map<String, dynamic> toJson() => toMap();

  factory PersonRelationshipIntelligence.fromMap(Map<String, dynamic> map) {
    return PersonRelationshipIntelligence(
      personId: map['personId'] as String? ?? '',
      signals: RelationshipSignals.empty(),
      strength: RelationshipStrength(
        score: (map['strengthScore'] as num?)?.toDouble() ?? 0.0,
        factors: const [],
        level: map['strengthLevel'] as String? ?? 'Active',
        summary: '',
      ),
      state: RelationshipState.fromValue(map['state'] as String? ?? 'active'),
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      explanations: (map['explanations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      topFactors: const [],
    );
  }

  factory PersonRelationshipIntelligence.fromJson(Map<String, dynamic> json) =>
      PersonRelationshipIntelligence.fromMap(json);
}