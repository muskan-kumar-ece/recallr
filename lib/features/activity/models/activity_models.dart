import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Supported domain activity types in Recallr's chronological memory layer.
enum ActivityType {
  encounter,      // Person encounter / introduction
  meeting,        // Meeting
  call,           // Phone or virtual call
  note,           // Freeform note / observation
  capture,        // Business card scan / OCR capture
  file,           // File attached / document
  followUp,       // Follow-up commitment
  companyUpdate,  // Company intelligence / organizational change
}

extension ActivityTypeExt on ActivityType {
  IconData get icon {
    switch (this) {
      case ActivityType.encounter:
        return Icons.person_search_rounded;
      case ActivityType.meeting:
        return Icons.groups_outlined;
      case ActivityType.call:
        return Icons.phone_outlined;
      case ActivityType.note:
        return Icons.description_outlined;
      case ActivityType.capture:
        return Icons.badge_outlined;
      case ActivityType.file:
        return Icons.attach_file_rounded;
      case ActivityType.followUp:
        return Icons.task_alt_rounded;
      case ActivityType.companyUpdate:
        return Icons.business_outlined;
    }
  }

  String get label {
    switch (this) {
      case ActivityType.encounter:
        return 'Encounter';
      case ActivityType.meeting:
        return 'Meeting';
      case ActivityType.call:
        return 'Call';
      case ActivityType.note:
        return 'Note';
      case ActivityType.capture:
        return 'Card Capture';
      case ActivityType.file:
        return 'File';
      case ActivityType.followUp:
        return 'Follow-up';
      case ActivityType.companyUpdate:
        return 'Company Update';
    }
  }

  String get badgeText {
    switch (this) {
      case ActivityType.encounter:
        return 'ENCOUNTER';
      case ActivityType.meeting:
        return 'MEETING';
      case ActivityType.call:
        return 'CALL';
      case ActivityType.note:
        return 'NOTE';
      case ActivityType.capture:
        return 'CARD OCR';
      case ActivityType.file:
        return 'FILE';
      case ActivityType.followUp:
        return 'FOLLOW-UP';
      case ActivityType.companyUpdate:
        return 'COMPANY';
    }
  }
}

/// Filter categories for the Activity screen.
enum ActivityFilter {
  all,
  people,
  meetings,
  calls,
  notes,
  captures,
  files,
  followUps,
}

extension ActivityFilterExt on ActivityFilter {
  String get label {
    switch (this) {
      case ActivityFilter.all:
        return 'All';
      case ActivityFilter.people:
        return 'People';
      case ActivityFilter.meetings:
        return 'Meetings';
      case ActivityFilter.calls:
        return 'Calls';
      case ActivityFilter.notes:
        return 'Notes';
      case ActivityFilter.captures:
        return 'Captures';
      case ActivityFilter.files:
        return 'Files';
      case ActivityFilter.followUps:
        return 'Follow-ups';
    }
  }

  bool matches(ActivityType type) {
    switch (this) {
      case ActivityFilter.all:
        return true;
      case ActivityFilter.people:
        return type == ActivityType.encounter;
      case ActivityFilter.meetings:
        return type == ActivityType.meeting;
      case ActivityFilter.calls:
        return type == ActivityType.call;
      case ActivityFilter.notes:
        return type == ActivityType.note;
      case ActivityFilter.captures:
        return type == ActivityType.capture;
      case ActivityFilter.files:
        return type == ActivityType.file;
      case ActivityFilter.followUps:
        return type == ActivityType.followUp;
    }
  }
}

/// Chronological timeline grouping periods.
enum TimelinePeriod {
  today,
  yesterday,
  thisWeek,
  earlier,
}

extension TimelinePeriodExt on TimelinePeriod {
  String get label {
    switch (this) {
      case TimelinePeriod.today:
        return 'Today';
      case TimelinePeriod.yesterday:
        return 'Yesterday';
      case TimelinePeriod.thisWeek:
        return 'This Week';
      case TimelinePeriod.earlier:
        return 'Earlier';
    }
  }

  String get uppercaseLabel {
    switch (this) {
      case TimelinePeriod.today:
        return 'TODAY';
      case TimelinePeriod.yesterday:
        return 'YESTERDAY';
      case TimelinePeriod.thisWeek:
        return 'THIS WEEK';
      case TimelinePeriod.earlier:
        return 'EARLIER';
    }
  }
}

/// A single professional-memory timeline item.
class ActivityItem {
  final String id;
  final ActivityType type;
  final TimelinePeriod period;
  final String timestamp;
  final String title;
  final String summary;
  final String? personId;
  final String? personName;
  final String? personRole;
  final String? companyId;
  final String? companyName;
  final String? location;
  final String? relationshipIndicator;
  final String? followUpStatus;
  final String targetRoute;
  final String actionLabel;
  final bool isVerified;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.period,
    required this.timestamp,
    required this.title,
    required this.summary,
    this.personId,
    this.personName,
    this.personRole,
    this.companyId,
    this.companyName,
    this.location,
    this.relationshipIndicator,
    this.followUpStatus,
    required this.targetRoute,
    required this.actionLabel,
    this.isVerified = true,
    this.metadata,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'period': period.name,
      'timestamp': timestamp,
      'title': title,
      'summary': summary,
      'personId': personId,
      'personName': personName,
      'personRole': personRole,
      'companyId': companyId,
      'companyName': companyName,
      'location': location,
      'relationshipIndicator': relationshipIndicator,
      'followUpStatus': followUpStatus,
      'targetRoute': targetRoute,
      'actionLabel': actionLabel,
      'isVerified': isVerified,
      'metadata': metadata,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ActivityItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ActivityItem(
      id: docId ?? map['id']?.toString() ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.encounter,
      ),
      period: TimelinePeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => TimelinePeriod.today,
      ),
      timestamp: map['timestamp']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      personId: map['personId']?.toString(),
      personName: map['personName']?.toString(),
      personRole: map['personRole']?.toString(),
      companyId: map['companyId']?.toString(),
      companyName: map['companyName']?.toString(),
      location: map['location']?.toString(),
      relationshipIndicator: map['relationshipIndicator']?.toString(),
      followUpStatus: map['followUpStatus']?.toString(),
      targetRoute: map['targetRoute']?.toString() ?? '/activity',
      actionLabel: map['actionLabel']?.toString() ?? 'View',
      isVerified: map['isVerified'] != false,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
      userId: map['userId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityItem.fromMap(data, doc.id);
  }

  ActivityItem copyWith({
    String? id,
    ActivityType? type,
    TimelinePeriod? period,
    String? timestamp,
    String? title,
    String? summary,
    String? personId,
    String? personName,
    String? personRole,
    String? companyId,
    String? companyName,
    String? location,
    String? relationshipIndicator,
    String? followUpStatus,
    String? targetRoute,
    String? actionLabel,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      type: type ?? this.type,
      period: period ?? this.period,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personRole: personRole ?? this.personRole,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      relationshipIndicator: relationshipIndicator ?? this.relationshipIndicator,
      followUpStatus: followUpStatus ?? this.followUpStatus,
      targetRoute: targetRoute ?? this.targetRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}