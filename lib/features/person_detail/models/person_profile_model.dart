import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../follow_ups/models/follow_up_models.dart';
import '../../people/models/person_item.dart';

/// Interaction type for chronological timeline.
enum TimelineType {
  meeting,
  voiceNote,
  cardScan,
  conversation,
  fileNote,
}

extension TimelineTypeExt on TimelineType {
  IconData get icon {
    switch (this) {
      case TimelineType.meeting:
        return Icons.forum_outlined;
      case TimelineType.voiceNote:
        return Icons.mic_none_rounded;
      case TimelineType.cardScan:
        return Icons.contact_page_outlined;
      case TimelineType.conversation:
        return Icons.chat_bubble_outline_rounded;
      case TimelineType.fileNote:
        return Icons.note_outlined;
    }
  }

  String get label {
    switch (this) {
      case TimelineType.meeting:
        return 'Meeting';
      case TimelineType.voiceNote:
        return 'Voice Memo';
      case TimelineType.cardScan:
        return 'Card Scanned';
      case TimelineType.conversation:
        return 'Conversation';
      case TimelineType.fileNote:
        return 'Note';
    }
  }
}

/// Chronological encounter / interaction model.
class TimelineItem {
  final String id;
  final TimelineType type;
  final String title;
  final String subtitle;
  final String date;
  final String? locationOrEvent;
  final String summary;
  final List<String> keyBullets;
  final String? targetRoute;

  const TimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.locationOrEvent,
    required this.summary,
    this.keyBullets = const [],
    this.targetRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'locationOrEvent': locationOrEvent,
      'summary': summary,
      'keyBullets': keyBullets,
      'targetRoute': targetRoute,
    };
  }

  factory TimelineItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return TimelineItem(
      id: docId ?? map['id']?.toString() ?? '',
      type: TimelineType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TimelineType.meeting,
      ),
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      locationOrEvent: map['locationOrEvent']?.toString(),
      summary: map['summary']?.toString() ?? '',
      keyBullets: (map['keyBullets'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      targetRoute: map['targetRoute']?.toString(),
    );
  }
}

/// Atomic Memory Claim / Provenance Item.
class MemoryItem {
  final String id;
  final String category;
  final String text;
  final bool isVerified;
  final String source;
  final String? timestamp;

  const MemoryItem({
    required this.id,
    required this.category,
    required this.text,
    this.isVerified = true,
    required this.source,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'isVerified': isVerified,
      'source': source,
      'timestamp': timestamp,
    };
  }

  factory MemoryItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MemoryItem(
      id: docId ?? map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isVerified: map['isVerified'] == true,
      source: map['source']?.toString() ?? '',
      timestamp: map['timestamp']?.toString(),
    );
  }
}

/// Connected entity type.
enum EntityType {
  company,
  event,
  file,
  person,
}

extension EntityTypeExt on EntityType {
  IconData get icon {
    switch (this) {
      case EntityType.company:
        return Icons.business_outlined;
      case EntityType.event:
        return Icons.event_outlined;
      case EntityType.file:
        return Icons.attach_file_rounded;
      case EntityType.person:
        return Icons.person_outline_rounded;
    }
  }
}

/// Connected entity (Company, Event, File, Mutual contact).
class ConnectedEntity {
  final String id;
  final EntityType type;
  final String title;
  final String subtitle;
  final String targetRoute;

  const ConnectedEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.targetRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'targetRoute': targetRoute,
    };
  }

  factory ConnectedEntity.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ConnectedEntity(
      id: docId ?? map['id']?.toString() ?? '',
      type: EntityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EntityType.company,
      ),
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      targetRoute: map['targetRoute']?.toString() ?? '',
    );
  }
}

/// Complete 360-degree Person Memory Profile.
class PersonProfile {
  final String id;
  final String name;
  final String role;
  final String company;
  final String? companyId;
  final String? email;
  final String? phone;
  final String location;
  final String initials;
  final RelationshipContextType relationshipType;
  final String relationshipStrength;
  final String firstMet;
  final String lastInteraction;
  final int totalInteractions;
  final int sharedEventsCount;
  final String aiSummary;
  final List<String> keyTakeaways;
  final List<String> capabilities;
  final List<TimelineItem> timeline;
  final List<MemoryItem> memories;
  final List<FollowUpItem> followUps;
  final List<ConnectedEntity> connectedEntities;
  final List<String> promptSuggestions;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PersonProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    this.companyId,
    this.email,
    this.phone,
    required this.location,
    required this.initials,
    required this.relationshipType,
    required this.relationshipStrength,
    required this.firstMet,
    required this.lastInteraction,
    required this.totalInteractions,
    required this.sharedEventsCount,
    required this.aiSummary,
    this.keyTakeaways = const [],
    this.capabilities = const [],
    this.timeline = const [],
    this.memories = const [],
    this.followUps = const [],
    this.connectedEntities = const [],
    this.promptSuggestions = const [],
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  static String computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '??';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'company': company,
      'companyId': companyId,
      'email': email,
      'phone': phone,
      'location': location,
      'initials': initials.isNotEmpty ? initials : computeInitials(name),
      'relationshipType': relationshipType.name,
      'relationshipStrength': relationshipStrength,
      'firstMet': firstMet,
      'lastInteraction': lastInteraction,
      'totalInteractions': totalInteractions,
      'sharedEventsCount': sharedEventsCount,
      'aiSummary': aiSummary,
      'keyTakeaways': keyTakeaways,
      'capabilities': capabilities,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'memories': memories.map((e) => e.toMap()).toList(),
      'followUps': followUps.map((e) => e.toMap()).toList(),
      'connectedEntities': connectedEntities.map((e) => e.toMap()).toList(),
      'promptSuggestions': promptSuggestions,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PersonProfile.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final nameStr = map['name']?.toString() ?? '';
    final rawInitials = map['initials']?.toString() ?? '';

    return PersonProfile(
      id: docId ?? map['id']?.toString() ?? '',
      name: nameStr,
      role: map['role']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      companyId: map['companyId']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      location: map['location']?.toString() ?? map['locationOrEvent']?.toString() ?? '',
      initials: rawInitials.isNotEmpty ? rawInitials : computeInitials(nameStr),
      relationshipType: RelationshipContextType.values.firstWhere(
        (e) => e.name == map['relationshipType'],
        orElse: () => RelationshipContextType.collaborator,
      ),
      relationshipStrength: map['relationshipStrength']?.toString() ?? 'Active',
      firstMet: map['firstMet']?.toString() ?? '',
      lastInteraction: map['lastInteraction']?.toString() ?? '',
      totalInteractions: (map['totalInteractions'] as num?)?.toInt() ?? 0,
      sharedEventsCount: (map['sharedEventsCount'] as num?)?.toInt() ?? 0,
      aiSummary: map['aiSummary']?.toString() ?? '',
      keyTakeaways: (map['keyTakeaways'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      capabilities: (map['capabilities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      timeline: (map['timeline'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? TimelineItem.fromMap(e) : null)
              .whereType<TimelineItem>()
              .toList() ??
          const [],
      memories: (map['memories'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? MemoryItem.fromMap(e) : null)
              .whereType<MemoryItem>()
              .toList() ??
          const [],
      followUps: (map['followUps'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? FollowUpItem.fromMap(e) : null)
              .whereType<FollowUpItem>()
              .toList() ??
          const [],
      connectedEntities: (map['connectedEntities'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? ConnectedEntity.fromMap(e) : null)
              .whereType<ConnectedEntity>()
              .toList() ??
          const [],
      promptSuggestions:
          (map['promptSuggestions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      userId: map['userId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory PersonProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PersonProfile.fromMap(data, doc.id);
  }

  PersonProfile copyWith({
    String? id,
    String? name,
    String? role,
    String? company,
    String? companyId,
    String? email,
    String? phone,
    String? location,
    String? initials,
    RelationshipContextType? relationshipType,
    String? relationshipStrength,
    String? firstMet,
    String? lastInteraction,
    int? totalInteractions,
    int? sharedEventsCount,
    String? aiSummary,
    List<String>? keyTakeaways,
    List<String>? capabilities,
    List<TimelineItem>? timeline,
    List<MemoryItem>? memories,
    List<FollowUpItem>? followUps,
    List<ConnectedEntity>? connectedEntities,
    List<String>? promptSuggestions,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      company: company ?? this.company,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      initials: initials ?? this.initials,
      relationshipType: relationshipType ?? this.relationshipType,
      relationshipStrength: relationshipStrength ?? this.relationshipStrength,
      firstMet: firstMet ?? this.firstMet,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      sharedEventsCount: sharedEventsCount ?? this.sharedEventsCount,
      aiSummary: aiSummary ?? this.aiSummary,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      capabilities: capabilities ?? this.capabilities,
      timeline: timeline ?? this.timeline,
      memories: memories ?? this.memories,
      followUps: followUps ?? this.followUps,
      connectedEntities: connectedEntities ?? this.connectedEntities,
      promptSuggestions: promptSuggestions ?? this.promptSuggestions,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}