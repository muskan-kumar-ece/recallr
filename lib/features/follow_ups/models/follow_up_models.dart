import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Commitment classification for professional relationship memory.
enum CommitmentType {
  iPromised,
  theyPromised,
  followUp,
  waiting,
  overdue;

  String get badgeText {
    switch (this) {
      case CommitmentType.iPromised:
        return 'I PROMISED';
      case CommitmentType.theyPromised:
        return 'THEY PROMISED';
      case CommitmentType.followUp:
        return 'FOLLOW-UP';
      case CommitmentType.waiting:
        return 'WAITING';
      case CommitmentType.overdue:
        return 'OVERDUE';
    }
  }

  IconData get icon {
    switch (this) {
      case CommitmentType.iPromised:
        return Icons.assignment_late_outlined;
      case CommitmentType.theyPromised:
        return Icons.reply_outlined;
      case CommitmentType.followUp:
        return Icons.alarm_on_outlined;
      case CommitmentType.waiting:
        return Icons.hourglass_top_rounded;
      case CommitmentType.overdue:
        return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CommitmentType.iPromised:
        return RecallrColors.warmAmberGold;
      case CommitmentType.theyPromised:
        return RecallrColors.aiElectricViolet;
      case CommitmentType.followUp:
        return RecallrColors.aiCyanHighlight;
      case CommitmentType.waiting:
        return RecallrColors.textSecondary;
      case CommitmentType.overdue:
        return RecallrColors.crimsonAlert;
    }
  }
}

/// Follow-up lifecycle status.
enum FollowUpStatus {
  dueToday,
  upcoming,
  waiting,
  overdue,
  completed;

  String get label {
    switch (this) {
      case FollowUpStatus.dueToday:
        return 'Due Today';
      case FollowUpStatus.upcoming:
        return 'Upcoming';
      case FollowUpStatus.waiting:
        return 'Waiting';
      case FollowUpStatus.overdue:
        return 'Overdue';
      case FollowUpStatus.completed:
        return 'Completed';
    }
  }
}

/// Priority tier of the commitment.
enum FollowUpPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case FollowUpPriority.high:
        return 'High';
      case FollowUpPriority.medium:
        return 'Medium';
      case FollowUpPriority.low:
        return 'Low';
    }
  }
}

/// Filter options for Follow-ups & Commitments Hub.
enum FollowUpFilter {
  all,
  dueToday,
  upcoming,
  waiting,
  overdue,
  completed;

  String get label {
    switch (this) {
      case FollowUpFilter.all:
        return 'All';
      case FollowUpFilter.dueToday:
        return 'Due Today';
      case FollowUpFilter.upcoming:
        return 'Upcoming';
      case FollowUpFilter.waiting:
        return 'Waiting';
      case FollowUpFilter.overdue:
        return 'Overdue';
      case FollowUpFilter.completed:
        return 'Completed';
    }
  }

  bool matches(FollowUpItem item) {
    switch (this) {
      case FollowUpFilter.all:
        return true;
      case FollowUpFilter.dueToday:
        return item.status == FollowUpStatus.dueToday;
      case FollowUpFilter.upcoming:
        return item.status == FollowUpStatus.upcoming;
      case FollowUpFilter.waiting:
        return item.status == FollowUpStatus.waiting;
      case FollowUpFilter.overdue:
        return item.status == FollowUpStatus.overdue || item.commitmentType == CommitmentType.overdue;
      case FollowUpFilter.completed:
        return item.isCompleted || item.status == FollowUpStatus.completed;
    }
  }
}

/// Summary metrics for the Follow-up Command Center.
class FollowUpSummaryStats {
  final int todayCount;
  final int upcomingCount;
  final int waitingCount;
  final int overdueCount;
  final int completedCount;

  const FollowUpSummaryStats({
    required this.todayCount,
    required this.upcomingCount,
    required this.waitingCount,
    required this.overdueCount,
    required this.completedCount,
  });

  factory FollowUpSummaryStats.fromItems(List<FollowUpItem> items) {
    return FollowUpSummaryStats(
      todayCount: items.where((f) => f.status == FollowUpStatus.dueToday && !f.isCompleted).length,
      upcomingCount: items.where((f) => f.status == FollowUpStatus.upcoming && !f.isCompleted).length,
      waitingCount: items.where((f) => f.status == FollowUpStatus.waiting && !f.isCompleted).length,
      overdueCount: items.where((f) => f.status == FollowUpStatus.overdue && !f.isCompleted).length,
      completedCount: items.where((f) => f.isCompleted).length,
    );
  }

  int get totalActive => todayCount + upcomingCount + waitingCount + overdueCount;
}

/// Domain model representing a single memory-backed relationship commitment.
class FollowUpItem {
  final String id;
  final String title;
  final String context;
  final CommitmentType commitmentType;
  final FollowUpStatus status;
  final FollowUpPriority priority;
  final String dueDate;
  final String createdDate;
  final String? personId;
  final String? personName;
  final String? personRole;
  final String? companyId;
  final String? companyName;
  final String? sourceInteractionId;
  final String? sourceMemoryTitle;
  final String? sourceMemoryDate;
  final String? location;
  final bool isVerified;
  final String targetRoute;
  final bool isCompleted;
  final String? completedAt;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FollowUpItem({
    required this.id,
    required this.title,
    this.context = '',
    this.commitmentType = CommitmentType.followUp,
    this.status = FollowUpStatus.dueToday,
    this.priority = FollowUpPriority.medium,
    required this.dueDate,
    this.createdDate = '',
    this.personId,
    this.personName,
    this.personRole,
    this.companyId,
    this.companyName,
    this.sourceInteractionId,
    this.sourceMemoryTitle,
    this.sourceMemoryDate,
    this.location,
    this.isVerified = true,
    required this.targetRoute,
    this.isCompleted = false,
    this.completedAt,
    this.metadata,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIPromised => commitmentType == CommitmentType.iPromised;
  bool get isTheyPromised => commitmentType == CommitmentType.theyPromised;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'context': context,
      'commitmentType': commitmentType.name,
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate,
      'createdDate': createdDate,
      'personId': personId,
      'personName': personName,
      'personRole': personRole,
      'companyId': companyId,
      'companyName': companyName,
      'sourceInteractionId': sourceInteractionId,
      'sourceMemoryTitle': sourceMemoryTitle,
      'sourceMemoryDate': sourceMemoryDate,
      'location': location,
      'isVerified': isVerified,
      'targetRoute': targetRoute,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'metadata': metadata,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory FollowUpItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    String? parseCompletedAt(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate().toIso8601String();
      return val.toString();
    }

    return FollowUpItem(
      id: docId ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      context: map['context']?.toString() ?? '',
      commitmentType: CommitmentType.values.firstWhere(
        (e) => e.name == map['commitmentType'],
        orElse: () => CommitmentType.followUp,
      ),
      status: FollowUpStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FollowUpStatus.dueToday,
      ),
      priority: FollowUpPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => FollowUpPriority.medium,
      ),
      dueDate: map['dueDate']?.toString() ?? '',
      createdDate: map['createdDate']?.toString() ?? '',
      personId: map['personId']?.toString(),
      personName: map['personName']?.toString(),
      personRole: map['personRole']?.toString(),
      companyId: map['companyId']?.toString(),
      companyName: map['companyName']?.toString(),
      sourceInteractionId: map['sourceInteractionId']?.toString(),
      sourceMemoryTitle: map['sourceMemoryTitle']?.toString(),
      sourceMemoryDate: map['sourceMemoryDate']?.toString(),
      location: map['location']?.toString(),
      isVerified: map['isVerified'] != false,
      targetRoute: map['targetRoute']?.toString() ?? '/follow-ups',
      isCompleted: map['isCompleted'] == true,
      completedAt: parseCompletedAt(map['completedAt']),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
      userId: map['userId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory FollowUpItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FollowUpItem.fromMap(data, doc.id);
  }

  FollowUpItem copyWith({
    String? id,
    String? title,
    String? context,
    CommitmentType? commitmentType,
    FollowUpStatus? status,
    FollowUpPriority? priority,
    String? dueDate,
    String? createdDate,
    String? personId,
    String? personName,
    String? personRole,
    String? companyId,
    String? companyName,
    String? sourceInteractionId,
    String? sourceMemoryTitle,
    String? sourceMemoryDate,
    String? location,
    bool? isVerified,
    String? targetRoute,
    bool? isCompleted,
    String? completedAt,
    bool clearCompletedAt = false,
    Map<String, dynamic>? metadata,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FollowUpItem(
      id: id ?? this.id,
      title: title ?? this.title,
      context: context ?? this.context,
      commitmentType: commitmentType ?? this.commitmentType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdDate: createdDate ?? this.createdDate,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personRole: personRole ?? this.personRole,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      sourceInteractionId: sourceInteractionId ?? this.sourceInteractionId,
      sourceMemoryTitle: sourceMemoryTitle ?? this.sourceMemoryTitle,
      sourceMemoryDate: sourceMemoryDate ?? this.sourceMemoryDate,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      targetRoute: targetRoute ?? this.targetRoute,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}