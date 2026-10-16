import 'package:flutter/foundation.dart';
import '../../activity/models/activity_models.dart';
import '../../capture/models/capture_models.dart';
import '../../follow_ups/models/follow_up_models.dart';
import '../../person_detail/models/person_profile_model.dart';

/// Structured, deterministic signals derived from authentic relationship records.
@immutable
class RelationshipSignals {
  final int interactionCount;
  final DateTime? recentInteractionDate;
  final int? daysSinceLastInteraction;
  final double interactionFrequency;
  final int relationshipAgeDays;
  final int memoryCount;
  final int captureCount;
  final int activeFollowUpCount;
  final int overdueFollowUpCount;
  final int completedFollowUpCount;
  final int recentInteractionCount;
  final int recentActivityCount;

  const RelationshipSignals({
    required this.interactionCount,
    this.recentInteractionDate,
    this.daysSinceLastInteraction,
    this.interactionFrequency = 0.0,
    this.relationshipAgeDays = 0,
    this.memoryCount = 0,
    this.captureCount = 0,
    this.activeFollowUpCount = 0,
    this.overdueFollowUpCount = 0,
    this.completedFollowUpCount = 0,
    this.recentInteractionCount = 0,
    this.recentActivityCount = 0,
  });

  /// Whether the person has had any interaction in the past 30 days.
  bool get hasRecentInteraction =>
      daysSinceLastInteraction != null && daysSinceLastInteraction! <= 30;

  /// Whether there are active pending follow-ups.
  bool get hasActiveFollowUp => activeFollowUpCount > 0;

  /// Whether there are overdue commitments.
  bool get hasOverdueFollowUp => overdueFollowUpCount > 0;

  /// Total follow-up count across all statuses.
  int get totalFollowUps =>
      activeFollowUpCount + overdueFollowUpCount + completedFollowUpCount;

  /// Factory constructing signals deterministically from real domain objects.
  factory RelationshipSignals.fromDomainData({
    required PersonProfile profile,
    List<ActivityItem> activities = const [],
    List<FollowUpItem> followUps = const [],
    List<CaptureItem> captures = const [],
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    // Deduplicate activities by id if present
    final distinctActivities = <ActivityItem>[];
    final seenActivityIds = <String>{};
    for (final act in activities) {
      if (act.id.isEmpty || seenActivityIds.add(act.id)) {
        distinctActivities.add(act);
      }
    }

    // 1. Gather all timestamps from profile timeline and activities
    final rawDates = <DateTime>[];

    for (final act in distinctActivities) {
      if (act.createdAt != null) {
        rawDates.add(act.createdAt!);
      } else {
        final parsed = _parseDateString(act.timestamp);
        if (parsed != null) {
          rawDates.add(parsed);
        }
      }
    }

    for (final tl in profile.timeline) {
      final parsed = _parseDateString(tl.date);
      if (parsed != null) {
        rawDates.add(parsed);
      }
    }

    // Deduplicate and sort newest first
    final interactionDates = rawDates.toSet().toList()..sort((a, b) => b.compareTo(a));

    DateTime? latestInteractionDate;
    int? daysSinceLatest;

    if (interactionDates.isNotEmpty) {
      latestInteractionDate = interactionDates.first;
      final diff = now.difference(latestInteractionDate).inDays;
      daysSinceLatest = diff < 0 ? 0 : diff;
    } else if (profile.lastInteraction.isNotEmpty && profile.lastInteraction != 'Never') {
      final parsed = _parseDateString(profile.lastInteraction);
      if (parsed != null) {
        latestInteractionDate = parsed;
        final diff = now.difference(parsed).inDays;
        daysSinceLatest = diff < 0 ? 0 : diff;
      }
    }

    // 2. Compute relationship age
    int ageDays = 0;
    if (profile.firstMet.isNotEmpty && profile.firstMet != 'Unknown') {
      final firstMetDate = _parseDateString(profile.firstMet);
      if (firstMetDate != null) {
        final diff = now.difference(firstMetDate).inDays;
        ageDays = diff < 0 ? 0 : diff;
      }
    }

    // Fallback: earliest interaction date if firstMet missing
    if (ageDays == 0 && interactionDates.isNotEmpty) {
      final earliest = interactionDates.last;
      final diff = now.difference(earliest).inDays;
      ageDays = diff < 0 ? 0 : diff;
    }

    // 3. Count recent interactions (within 30 days)
    final recentInteractions = interactionDates.where((d) {
      final diff = now.difference(d).inDays;
      return diff >= 0 && diff <= 30;
    }).length;

    // 4. Calculate total interaction count
    final totalInteractions = profile.totalInteractions > 0
        ? profile.totalInteractions
        : (distinctActivities.isNotEmpty
            ? distinctActivities.length
            : interactionDates.length);

    // 5. Compute frequency (interactions per 30-day period)
    double frequency = 0.0;
    if (ageDays > 0) {
      final monthPeriods = (ageDays / 30.0).clamp(1.0, 120.0);
      frequency = totalInteractions / monthPeriods;
    } else if (totalInteractions > 0) {
      frequency = totalInteractions.toDouble();
    }

    // 6. Follow-up aggregations
    int activeFUs = 0;
    int overdueFUs = 0;
    int completedFUs = 0;

    final effectiveFollowUps = followUps.isNotEmpty ? followUps : profile.followUps;

    for (final fu in effectiveFollowUps) {
      if (fu.isCompleted || fu.status == FollowUpStatus.completed) {
        completedFUs++;
      } else {
        final parsedDue = _parseDateString(fu.dueDate);
        if (fu.status == FollowUpStatus.overdue ||
            fu.commitmentType == CommitmentType.overdue ||
            (parsedDue != null && parsedDue.isBefore(now))) {
          overdueFUs++;
        } else {
          activeFUs++;
        }
      }
    }

    // 7. Memory and capture counts
    final memCount = profile.memories.length;
    final capCount = captures.length;

    return RelationshipSignals(
      interactionCount: totalInteractions,
      recentInteractionDate: latestInteractionDate,
      daysSinceLastInteraction: daysSinceLatest,
      interactionFrequency: frequency,
      relationshipAgeDays: ageDays,
      memoryCount: memCount,
      captureCount: capCount,
      activeFollowUpCount: activeFUs,
      overdueFollowUpCount: overdueFUs,
      completedFollowUpCount: completedFUs,
      recentInteractionCount: recentInteractions,
      recentActivityCount: recentInteractions,
    );
  }

  /// Empty / baseline signals for unpopulated records.
  factory RelationshipSignals.empty() {
    return const RelationshipSignals(
      interactionCount: 0,
      recentInteractionDate: null,
      daysSinceLastInteraction: null,
      interactionFrequency: 0.0,
      relationshipAgeDays: 0,
      memoryCount: 0,
      captureCount: 0,
      activeFollowUpCount: 0,
      overdueFollowUpCount: 0,
      completedFollowUpCount: 0,
      recentInteractionCount: 0,
      recentActivityCount: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'interactionCount': interactionCount,
      'recentInteractionDate': recentInteractionDate?.toIso8601String(),
      'daysSinceLastInteraction': daysSinceLastInteraction,
      'interactionFrequency': interactionFrequency,
      'relationshipAgeDays': relationshipAgeDays,
      'memoryCount': memoryCount,
      'captureCount': captureCount,
      'activeFollowUpCount': activeFollowUpCount,
      'overdueFollowUpCount': overdueFollowUpCount,
      'completedFollowUpCount': completedFollowUpCount,
      'recentInteractionCount': recentInteractionCount,
      'recentActivityCount': recentActivityCount,
    };
  }

  factory RelationshipSignals.fromMap(Map<String, dynamic> map) {
    return RelationshipSignals(
      interactionCount: (map['interactionCount'] as num?)?.toInt() ?? 0,
      recentInteractionDate: map['recentInteractionDate'] != null
          ? DateTime.tryParse(map['recentInteractionDate'] as String)
          : null,
      daysSinceLastInteraction: (map['daysSinceLastInteraction'] as num?)?.toInt(),
      interactionFrequency: (map['interactionFrequency'] as num?)?.toDouble() ?? 0.0,
      relationshipAgeDays: (map['relationshipAgeDays'] as num?)?.toInt() ?? 0,
      memoryCount: (map['memoryCount'] as num?)?.toInt() ?? 0,
      captureCount: (map['captureCount'] as num?)?.toInt() ?? 0,
      activeFollowUpCount: (map['activeFollowUpCount'] as num?)?.toInt() ?? 0,
      overdueFollowUpCount: (map['overdueFollowUpCount'] as num?)?.toInt() ?? 0,
      completedFollowUpCount: (map['completedFollowUpCount'] as num?)?.toInt() ?? 0,
      recentInteractionCount: (map['recentInteractionCount'] as num?)?.toInt() ?? 0,
      recentActivityCount: (map['recentActivityCount'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDateString(String dateStr) {
    if (dateStr.isEmpty) return null;
    final normalized = dateStr.trim();
    if (normalized == 'Never' || normalized == 'Unknown') {
      return null;
    }
    if (normalized.toLowerCase() == 'today') {
      return DateTime.now();
    }
    if (normalized.toLowerCase() == 'yesterday') {
      return DateTime.now().subtract(const Duration(days: 1));
    }

    final daysAgoMatch = RegExp(r'^(\d+)\s+days?\s+ago$', caseSensitive: false).firstMatch(normalized);
    if (daysAgoMatch != null) {
      final d = int.tryParse(daysAgoMatch.group(1)!);
      if (d != null) {
        return DateTime.now().subtract(Duration(days: d));
      }
    }

    // ISO format: YYYY-MM-DD
    try {
      return DateTime.parse(normalized);
    } catch (_) {}

    // Month DD, YYYY e.g. Aug 18, 2026 or August 18, 2026
    final monthMap = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };

    final parts = normalized.replaceAll(',', '').split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final month = monthMap[parts[0].toLowerCase()];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}
