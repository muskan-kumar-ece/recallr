import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic calculation of interaction cadence.
abstract class RelationshipCadenceCalculator {
  CadenceAnalysis calculate({
    required List<DateTime> interactionDates,
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic cadence calculator.
@immutable
class DeterministicRelationshipCadenceCalculator implements RelationshipCadenceCalculator {
  const DeterministicRelationshipCadenceCalculator();

  @override
  CadenceAnalysis calculate({
    required List<DateTime> interactionDates,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    // 1. Filter out future dates and normalize to calendar day (midnight)
    final validDates = interactionDates
        .where((d) => !d.isAfter(now))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();

    // 2. Sort distinct encounter days chronologically
    validDates.sort((a, b) => a.compareTo(b));

    if (validDates.isEmpty) {
      return CadenceAnalysis.empty();
    }

    final daysSinceLast = now.difference(validDates.last).inDays;

    if (validDates.length < 2) {
      return CadenceAnalysis(
        averageCadenceDays: null,
        daysSinceLastInteraction: daysSinceLast,
        cadenceRatio: null,
        expectedNextContactDate: null,
        totalDistinctDates: validDates.length,
      );
    }

    // 3. Compute consecutive day intervals
    final intervals = <int>[];
    for (int i = 1; i < validDates.length; i++) {
      final diff = validDates[i].difference(validDates[i - 1]).inDays;
      if (diff > 0) {
        intervals.add(diff);
      }
    }

    if (intervals.isEmpty) {
      return CadenceAnalysis(
        averageCadenceDays: null,
        daysSinceLastInteraction: daysSinceLast,
        cadenceRatio: null,
        expectedNextContactDate: null,
        totalDistinctDates: validDates.length,
      );
    }

    // 4. Calculate arithmetic mean cadence in days
    final totalIntervalDays = intervals.reduce((a, b) => a + b);
    final avgCadence = totalIntervalDays / intervals.length;

    // 5. Cadence ratio & Expected next contact date
    final double? cadenceRatio = avgCadence > 0 ? (daysSinceLast / avgCadence) : 0.0;
    final expectedNext = validDates.last.add(Duration(days: avgCadence.round()));

    return CadenceAnalysis(
      averageCadenceDays: avgCadence,
      daysSinceLastInteraction: daysSinceLast,
      cadenceRatio: cadenceRatio,
      expectedNextContactDate: expectedNext,
      totalDistinctDates: validDates.length,
    );
  }
}
