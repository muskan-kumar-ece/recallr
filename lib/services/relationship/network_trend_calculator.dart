import 'package:flutter/foundation.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic network trend analysis over temporal windows.
abstract class NetworkTrendCalculator {
  List<NetworkTrend> calculate({
    required List<ActivityItem> activities,
    required List<FollowUpItem> followUps,
    required List<PersonRelationshipIntelligence> intelligenceList,
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic temporal trend calculator.
@immutable
class DeterministicNetworkTrendCalculator implements NetworkTrendCalculator {
  const DeterministicNetworkTrendCalculator();

  @override
  List<NetworkTrend> calculate({
    required List<ActivityItem> activities,
    required List<FollowUpItem> followUps,
    required List<PersonRelationshipIntelligence> intelligenceList,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final cutoffTrailing30 = now.subtract(const Duration(days: 30));
    final cutoffPreceding30 = now.subtract(const Duration(days: 60));

    final trends = <NetworkTrend>[];

    // 1. Interaction Velocity Trend
    int trailing30Interactions = 0;
    int preceding30Interactions = 0;

    for (final act in activities) {
      final d = act.createdAt ?? DateTime.tryParse(act.timestamp);
      if (d == null) continue;
      if (d.isAfter(cutoffTrailing30) && !d.isAfter(now)) {
        trailing30Interactions++;
      } else if (d.isAfter(cutoffPreceding30) && !d.isAfter(cutoffTrailing30)) {
        preceding30Interactions++;
      }
    }

    if (activities.isEmpty && intelligenceList.isEmpty) {
      trends.add(NetworkTrend.insufficientData(
        periodLabel: 'vs previous 30 days',
        description: 'Not enough interaction history to compute momentum.',
      ));
    } else if (preceding30Interactions == 0 && trailing30Interactions == 0) {
      trends.add(const NetworkTrend(
        type: NetworkTrendType.stable,
        currentValue: 0.0,
        previousValue: 0.0,
        delta: 0.0,
        percentageChange: 0.0,
        periodLabel: 'vs previous 30 days',
        description: 'No interaction activity in the last 60 days.',
      ));
    } else {
      final delta = (trailing30Interactions - preceding30Interactions).toDouble();
      final double? pct;
      if (preceding30Interactions > 0) {
        pct = (delta / preceding30Interactions) * 100.0;
      } else {
        pct = 100.0; // Grew from zero
      }

      final NetworkTrendType type;
      if (delta > 0) {
        type = NetworkTrendType.growing;
      } else if (delta < 0) {
        type = NetworkTrendType.cooling;
      } else {
        type = NetworkTrendType.stable;
      }

      final formattedPct = pct >= 0 ? '+${pct.toInt()}%' : '${pct.toInt()}%';
      final desc = delta > 0
          ? '$trailing30Interactions interactions recorded ($formattedPct momentum vs previous 30 days).'
          : (delta < 0
              ? 'Interaction activity dropped to $trailing30Interactions ($formattedPct vs previous 30 days).'
              : 'Interaction volume remained steady at $trailing30Interactions interactions.');

      trends.add(NetworkTrend(
        type: type,
        currentValue: trailing30Interactions.toDouble(),
        previousValue: preceding30Interactions.toDouble(),
        delta: delta,
        percentageChange: pct,
        periodLabel: 'vs previous 30 days',
        description: desc,
      ));
    }

    // 2. Follow-Up Reliability Trend
    int completedCount = 0;
    int overdueCount = 0;
    int pendingCount = 0;

    for (final f in followUps) {
      if (f.isCompleted || f.status == FollowUpStatus.completed) {
        completedCount++;
      } else if (f.status == FollowUpStatus.overdue || f.commitmentType == CommitmentType.overdue) {
        overdueCount++;
      } else {
        pendingCount++;
      }
    }

    final totalFollowUps = completedCount + overdueCount + pendingCount;
    if (totalFollowUps == 0) {
      trends.add(NetworkTrend.insufficientData(
        periodLabel: 'all-time commitments',
        description: 'No active or completed follow-up commitments recorded yet.',
      ));
    } else {
      final rate = (completedCount / totalFollowUps) * 100.0;
      final NetworkTrendType type = overdueCount == 0
          ? NetworkTrendType.strengthening
          : (rate >= 60.0 ? NetworkTrendType.stable : NetworkTrendType.declining);

      trends.add(NetworkTrend(
        type: type,
        currentValue: rate,
        previousValue: 100.0,
        delta: overdueCount.toDouble(),
        percentageChange: rate,
        periodLabel: '$completedCount of $totalFollowUps completed',
        description: overdueCount > 0
            ? '${rate.toInt()}% completion rate with $overdueCount overdue commitment${overdueCount == 1 ? '' : 's'}.'
            : '${rate.toInt()}% completion rate with zero overdue commitments.',
      ));
    }

    // 3. Cooling Relationships Trend
    int coolingCount = 0;
    int neglectedCount = 0;
    for (final intel in intelligenceList) {
      if (intel.state == RelationshipState.cooling) {
        coolingCount++;
      } else if (intel.state == RelationshipState.neglected) {
        neglectedCount++;
      }
    }

    if (intelligenceList.isNotEmpty) {
      final atRiskTotal = coolingCount + neglectedCount;
      if (atRiskTotal > 0) {
        trends.add(NetworkTrend(
          type: NetworkTrendType.cooling,
          currentValue: atRiskTotal.toDouble(),
          previousValue: 0.0,
          delta: atRiskTotal.toDouble(),
          percentageChange: null,
          periodLabel: 'current network status',
          description: '$atRiskTotal relationship${atRiskTotal == 1 ? '' : 's'} at risk of fading ($coolingCount cooling, $neglectedCount neglected).',
        ));
      } else {
        trends.add(const NetworkTrend(
          type: NetworkTrendType.strengthening,
          currentValue: 0.0,
          previousValue: 0.0,
          delta: 0.0,
          percentageChange: null,
          periodLabel: 'current network status',
          description: 'Zero cooling or neglected relationships in your active network.',
        ));
      }
    }

    return trends;
  }
}
