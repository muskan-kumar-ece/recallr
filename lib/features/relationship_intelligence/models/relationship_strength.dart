import 'package:flutter/foundation.dart';

/// An individual, explainable scoring factor contributing to RelationshipStrength.
@immutable
class StrengthFactor {
  final String name;
  final double score; // Normalized 0.0 to 1.0
  final double weight; // Fractional weight 0.0 to 1.0
  final String explanation;

  const StrengthFactor({
    required this.name,
    required this.score,
    required this.weight,
    required this.explanation,
  });

  /// The weighted contribution of this factor (0.0 to 100.0).
  double get weightedScore => (score * weight * 100.0).clamp(0.0, 100.0);

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'weight': weight,
    'explanation': explanation,
    'weightedScore': weightedScore,
  };

  factory StrengthFactor.fromJson(Map<String, dynamic> json) {
    return StrengthFactor(
      name: json['name']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  factory StrengthFactor.fromMap(Map<String, dynamic> map) =>
      StrengthFactor.fromJson(map);
}

/// Deterministic relationship strength calculation bounded 0.0 to 100.0.
@immutable
class RelationshipStrength {
  final double score;
  final List<StrengthFactor> factors;
  final String level;
  final String summary;

  const RelationshipStrength({
    required this.score,
    required this.factors,
    required this.level,
    required this.summary,
  });

  /// Factory creating an empty or zero-strength representation.
  factory RelationshipStrength.zero({String? reason}) {
    return RelationshipStrength(
      score: 0.0,
      factors: const [],
      level: 'None',
      summary: reason ?? 'Not enough interaction history to compute relationship strength.',
    );
  }

  /// Empty alias for zero().
  factory RelationshipStrength.empty() => RelationshipStrength.zero();

  /// Clamps and constructs RelationshipStrength ensuring score is strictly 0.0 to 100.0.
  factory RelationshipStrength.fromFactors({
    required List<StrengthFactor> factors,
  }) {
    if (factors.isEmpty) {
      return RelationshipStrength.zero();
    }

    double totalWeighted = 0.0;
    for (final factor in factors) {
      totalWeighted += factor.score.clamp(0.0, 1.0) * factor.weight.clamp(0.0, 1.0);
    }

    final double computedScore = (totalWeighted * 100.0).clamp(0.0, 100.0);

    String levelStr;
    if (computedScore >= 80.0) {
      levelStr = 'Very High';
    } else if (computedScore >= 60.0) {
      levelStr = 'High';
    } else if (computedScore >= 35.0) {
      levelStr = 'Moderate';
    } else if (computedScore >= 15.0) {
      levelStr = 'Developing';
    } else {
      levelStr = 'Low';
    }

    final summaryStr = _generateSummary(computedScore, factors);

    return RelationshipStrength(
      score: double.parse(computedScore.toStringAsFixed(1)),
      factors: List.unmodifiable(factors),
      level: levelStr,
      summary: summaryStr,
    );
  }

  static String _generateSummary(double score, List<StrengthFactor> factors) {
    if (score >= 75.0) {
      return 'Strong, active relationship supported by frequent encounters and verified context.';
    } else if (score >= 50.0) {
      return 'Healthy ongoing connection with regular interactions and clear context.';
    } else if (score >= 25.0) {
      return 'Developing relationship with initial meetings and touchpoints recorded.';
    } else {
      return 'Early-stage or dormant connection with limited recent interaction.';
    }
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
    'score': score,
    'level': level,
    'summary': summary,
    'factors': factors.map((f) => f.toJson()).toList(),
  };

  factory RelationshipStrength.fromJson(Map<String, dynamic> json) {
    final factorsRaw = json['factors'];
    final factors = factorsRaw is List
        ? factorsRaw
            .map((f) => StrengthFactor.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList()
        : const <StrengthFactor>[];

    return RelationshipStrength(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      level: json['level']?.toString() ?? 'Low',
      summary: json['summary']?.toString() ?? '',
      factors: factors,
    );
  }

  factory RelationshipStrength.fromMap(Map<String, dynamic> map) =>
      RelationshipStrength.fromJson(map);
}
