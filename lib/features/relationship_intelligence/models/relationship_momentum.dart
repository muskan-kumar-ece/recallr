import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Supported relationship evolution & momentum directions in Recallr.
enum MomentumDirection {
  strengthening,
  stable,
  cooling,
  declining,
  recovering,
  newlyDeveloping,
  insufficientHistory;

  String get displayName {
    switch (this) {
      case MomentumDirection.strengthening:
        return 'Strengthening';
      case MomentumDirection.stable:
        return 'Stable';
      case MomentumDirection.cooling:
        return 'Cooling';
      case MomentumDirection.declining:
        return 'Declining';
      case MomentumDirection.recovering:
        return 'Recovering';
      case MomentumDirection.newlyDeveloping:
        return 'Newly Developing';
      case MomentumDirection.insufficientHistory:
        return 'Insufficient History';
    }
  }

  String get badgeLabel {
    switch (this) {
      case MomentumDirection.strengthening:
        return 'STRENGTHENING';
      case MomentumDirection.stable:
        return 'STABLE';
      case MomentumDirection.cooling:
        return 'COOLING';
      case MomentumDirection.declining:
        return 'DECLINING';
      case MomentumDirection.recovering:
        return 'RECOVERING';
      case MomentumDirection.newlyDeveloping:
        return 'NEWLY DEVELOPING';
      case MomentumDirection.insufficientHistory:
        return 'LIMITED DATA';
    }
  }

  IconData get icon {
    switch (this) {
      case MomentumDirection.strengthening:
        return Icons.trending_up_rounded;
      case MomentumDirection.stable:
        return Icons.trending_flat_rounded;
      case MomentumDirection.cooling:
        return Icons.trending_down_rounded;
      case MomentumDirection.declining:
        return Icons.arrow_downward_rounded;
      case MomentumDirection.recovering:
        return Icons.restart_alt_rounded;
      case MomentumDirection.newlyDeveloping:
        return Icons.auto_awesome_rounded;
      case MomentumDirection.insufficientHistory:
        return Icons.help_outline_rounded;
    }
  }

  Color get colorToken {
    switch (this) {
      case MomentumDirection.strengthening:
        return RecallrColors.emeraldVerified;
      case MomentumDirection.stable:
        return RecallrColors.aiCyanHighlight;
      case MomentumDirection.cooling:
        return RecallrColors.warmAmberGold;
      case MomentumDirection.declining:
        return RecallrColors.crimsonAlert;
      case MomentumDirection.recovering:
        return RecallrColors.aiElectricViolet;
      case MomentumDirection.newlyDeveloping:
        return RecallrColors.aiElectricViolet;
      case MomentumDirection.insufficientHistory:
        return RecallrColors.textTertiary;
    }
  }

  bool get isPositive =>
      this == MomentumDirection.strengthening ||
      this == MomentumDirection.recovering ||
      this == MomentumDirection.newlyDeveloping;

  bool get isAtRisk =>
      this == MomentumDirection.cooling ||
      this == MomentumDirection.declining;
}

/// Evaluates encounter volume and velocity across temporal windows.
@immutable
class RelationshipVelocity {
  final int recentCount;      // Trailing 30 days (0–30d)
  final int previousCount;    // Preceding 30 days (31–60d)
  final int priorCount;       // Prior period (61–90d)
  final int historicalCount;  // All-time total interactions
  final double velocityDelta; // recentCount - previousCount
  final double? percentageChange; // Null if previous == 0 && recent == 0

  const RelationshipVelocity({
    required this.recentCount,
    required this.previousCount,
    this.priorCount = 0,
    required this.historicalCount,
    required this.velocityDelta,
    this.percentageChange,
  });

  factory RelationshipVelocity.empty() {
    return const RelationshipVelocity(
      recentCount: 0,
      previousCount: 0,
      priorCount: 0,
      historicalCount: 0,
      velocityDelta: 0.0,
      percentageChange: null,
    );
  }

  bool get isAccelerating => velocityDelta > 0 && recentCount >= 2;
  bool get isDecelerating => velocityDelta < 0 && previousCount >= 2;
  bool get isFlat => velocityDelta == 0.0;
  bool get hasSufficientData => historicalCount >= 2 && (recentCount > 0 || previousCount > 0 || priorCount > 0);

  Map<String, dynamic> toMap() => {
    'recentCount': recentCount,
    'previousCount': previousCount,
    'priorCount': priorCount,
    'historicalCount': historicalCount,
    'velocityDelta': velocityDelta,
    'percentageChange': percentageChange,
    'isAccelerating': isAccelerating,
    'isDecelerating': isDecelerating,
    'hasSufficientData': hasSufficientData,
  };

  factory RelationshipVelocity.fromMap(Map<String, dynamic> map) {
    return RelationshipVelocity(
      recentCount: (map['recentCount'] as num?)?.toInt() ?? 0,
      previousCount: (map['previousCount'] as num?)?.toInt() ?? 0,
      priorCount: (map['priorCount'] as num?)?.toInt() ?? 0,
      historicalCount: (map['historicalCount'] as num?)?.toInt() ?? 0,
      velocityDelta: (map['velocityDelta'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (map['percentageChange'] as num?)?.toDouble(),
    );
  }
}

/// Evaluates historical encounter rhythm, cadence, and expected timing.
@immutable
class CadenceAnalysis {
  final double? averageCadenceDays;
  final int? daysSinceLastInteraction;
  final double? cadenceRatio; // daysSinceLastInteraction / averageCadenceDays
  final DateTime? expectedNextContactDate;
  final int totalDistinctDates;

  const CadenceAnalysis({
    this.averageCadenceDays,
    this.daysSinceLastInteraction,
    this.cadenceRatio,
    this.expectedNextContactDate,
    this.totalDistinctDates = 0,
  });

  factory CadenceAnalysis.empty() {
    return const CadenceAnalysis(
      averageCadenceDays: null,
      daysSinceLastInteraction: null,
      cadenceRatio: null,
      expectedNextContactDate: null,
      totalDistinctDates: 0,
    );
  }

  bool get hasSufficientCadence =>
      averageCadenceDays != null && averageCadenceDays! > 0 && totalDistinctDates >= 2;

  bool get hasCadenceHistory => totalDistinctDates >= 2;

  bool get isOffCadence =>
      cadenceRatio != null && cadenceRatio! >= 1.5;

  bool get isCriticallyOffCadence =>
      cadenceRatio != null && cadenceRatio! >= 2.5;

  Map<String, dynamic> toMap() => {
    'averageCadenceDays': averageCadenceDays,
    'daysSinceLastInteraction': daysSinceLastInteraction,
    'cadenceRatio': cadenceRatio,
    'expectedNextContactDate': expectedNextContactDate?.toIso8601String(),
    'totalDistinctDates': totalDistinctDates,
    'hasSufficientCadence': hasSufficientCadence,
    'isOffCadence': isOffCadence,
    'isCriticallyOffCadence': isCriticallyOffCadence,
  };

  factory CadenceAnalysis.fromMap(Map<String, dynamic> map) {
    return CadenceAnalysis(
      averageCadenceDays: (map['averageCadenceDays'] as num?)?.toDouble(),
      daysSinceLastInteraction: (map['daysSinceLastInteraction'] as num?)?.toInt(),
      cadenceRatio: (map['cadenceRatio'] as num?)?.toDouble(),
      expectedNextContactDate: map['expectedNextContactDate'] != null
          ? DateTime.tryParse(map['expectedNextContactDate'] as String)
          : null,
      totalDistinctDates: (map['totalDistinctDates'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Comprehensive derived domain entity representing a contact's relationship evolution.
@immutable
class RelationshipMomentum {
  final String personId;
  final MomentumDirection direction;
  final double momentumScore; // 0.0 to 100.0 (50.0 is neutral/stable)
  final RelationshipVelocity velocity;
  final CadenceAnalysis cadence;
  final String headline;
  final String explanation;
  final List<String> keyEvolutionFactors;
  final DateTime generatedAt;

  const RelationshipMomentum({
    required this.personId,
    required this.direction,
    required this.momentumScore,
    required this.velocity,
    required this.cadence,
    required this.headline,
    required this.explanation,
    required this.keyEvolutionFactors,
    required this.generatedAt,
  });

  factory RelationshipMomentum.simple({
    required String personId,
    required MomentumDirection direction,
    double momentumScore = 50.0,
    String headline = '',
    String explanation = '',
    List<String> keyEvolutionFactors = const [],
    RelationshipVelocity? velocity,
    CadenceAnalysis? cadence,
    DateTime? generatedAt,
  }) {
    return RelationshipMomentum(
      personId: personId,
      direction: direction,
      momentumScore: momentumScore,
      velocity: velocity ?? RelationshipVelocity.empty(),
      cadence: cadence ?? CadenceAnalysis.empty(),
      headline: headline,
      explanation: explanation,
      keyEvolutionFactors: keyEvolutionFactors,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  factory RelationshipMomentum.insufficientHistory({
    required String personId,
    RelationshipVelocity? velocity,
    CadenceAnalysis? cadence,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    return RelationshipMomentum(
      personId: personId,
      direction: MomentumDirection.insufficientHistory,
      momentumScore: 50.0,
      velocity: velocity ?? RelationshipVelocity.empty(),
      cadence: cadence ?? CadenceAnalysis.empty(),
      headline: 'Limited Interaction History',
      explanation: 'Not enough interaction history to establish a reliable relationship trend yet.',
      keyEvolutionFactors: const ['Less than 2 distinct encounters recorded'],
      generatedAt: now,
    );
  }

  factory RelationshipMomentum.empty({
    String personId = '',
    DateTime? referenceDate,
  }) {
    return RelationshipMomentum.insufficientHistory(
      personId: personId,
      referenceDate: referenceDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'personId': personId,
    'direction': direction.name,
    'momentumScore': momentumScore,
    'velocity': velocity.toMap(),
    'cadence': cadence.toMap(),
    'headline': headline,
    'explanation': explanation,
    'keyEvolutionFactors': keyEvolutionFactors,
    'generatedAt': generatedAt.toIso8601String(),
  };

  Map<String, dynamic> toJson() => toMap();

  factory RelationshipMomentum.fromMap(Map<String, dynamic> map) {
    final dirStr = map['direction'] as String? ?? 'insufficientHistory';
    final dir = MomentumDirection.values.firstWhere(
      (d) => d.name == dirStr,
      orElse: () => MomentumDirection.insufficientHistory,
    );

    return RelationshipMomentum(
      personId: map['personId'] as String? ?? '',
      direction: dir,
      momentumScore: (map['momentumScore'] as num?)?.toDouble() ?? 50.0,
      velocity: map['velocity'] is Map<String, dynamic>
          ? RelationshipVelocity.fromMap(map['velocity'] as Map<String, dynamic>)
          : RelationshipVelocity.empty(),
      cadence: map['cadence'] is Map<String, dynamic>
          ? CadenceAnalysis.fromMap(map['cadence'] as Map<String, dynamic>)
          : CadenceAnalysis.empty(),
      headline: map['headline'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      keyEvolutionFactors: (map['keyEvolutionFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory RelationshipMomentum.fromJson(Map<String, dynamic> json) =>
      RelationshipMomentum.fromMap(json);
}
