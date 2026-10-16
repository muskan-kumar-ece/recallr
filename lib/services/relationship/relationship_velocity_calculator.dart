import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic calculation of interaction velocity across temporal windows.
abstract class RelationshipVelocityCalculator {
  RelationshipVelocity calculate({
    required List<DateTime> interactionDates,
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic velocity calculator.
@immutable
class DeterministicRelationshipVelocityCalculator implements RelationshipVelocityCalculator {
  const DeterministicRelationshipVelocityCalculator();

  @override
  RelationshipVelocity calculate({
    required List<DateTime> interactionDates,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final cutoffTrailing30 = now.subtract(const Duration(days: 30));
    final cutoffPreceding30 = now.subtract(const Duration(days: 60));
    final cutoffPrior30 = now.subtract(const Duration(days: 90));

    // Filter out future dates
    final validDates = interactionDates.where((d) => !d.isAfter(now)).toList();

    int recent = 0;   // 0–30d
    int previous = 0; // 31–60d
    int prior = 0;    // 61–90d

    for (final d in validDates) {
      if (d.isAfter(cutoffTrailing30)) {
        recent++;
      } else if (d.isAfter(cutoffPreceding30)) {
        previous++;
      } else if (d.isAfter(cutoffPrior30)) {
        prior++;
      }
    }

    final historical = validDates.length;
    final delta = (recent - previous).toDouble();

    final double? pctChange;
    if (previous == 0 && recent == 0) {
      pctChange = null;
    } else if (previous == 0 && recent > 0) {
      pctChange = 100.0; // Emerged from 0
    } else {
      pctChange = (delta / previous) * 100.0;
    }

    return RelationshipVelocity(
      recentCount: recent,
      previousCount: previous,
      priorCount: prior,
      historicalCount: historical,
      velocityDelta: delta,
      percentageChange: pctChange,
    );
  }
}
