import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Relationship context tag for a person in the network.
enum RelationshipContextType {
  collaborator,
  founder,
  investor,
  advisor,
  colleague,
  mentor,
  client,
}

/// Rich relationship-aware person model for Recallr People directory.
class PersonItem {
  final String id;
  final String name;
  final String role;
  final String company;
  final String? email;
  final String? phone;
  final String? locationOrEvent;
  final String? contextSnippet;
  final String? lastInteraction;
  final DateTime? lastInteractionDate;
  final String initials;
  final List<String> capabilities;
  final String? pendingFollowUp;
  final bool hasPendingFollowUp;
  final int interactionCount;
  final RelationshipContextType? relationshipType;
  final String? avatarUrl;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PersonItem({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    this.email,
    this.phone,
    this.locationOrEvent,
    this.contextSnippet,
    this.lastInteraction,
    this.lastInteractionDate,
    required this.initials,
    this.capabilities = const [],
    this.pendingFollowUp,
    this.hasPendingFollowUp = false,
    this.interactionCount = 1,
    this.relationshipType,
    this.avatarUrl,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  String get targetRoute => '/person/$id';

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
      'email': email,
      'phone': phone,
      'locationOrEvent': locationOrEvent,
      'contextSnippet': contextSnippet,
      'lastInteraction': lastInteraction,
      'lastInteractionDate': lastInteractionDate != null ? Timestamp.fromDate(lastInteractionDate!) : null,
      'initials': initials.isNotEmpty ? initials : computeInitials(name),
      'capabilities': capabilities,
      'pendingFollowUp': pendingFollowUp,
      'hasPendingFollowUp': hasPendingFollowUp,
      'interactionCount': interactionCount,
      'relationshipType': relationshipType?.name,
      'avatarUrl': avatarUrl,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PersonItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final nameStr = map['name']?.toString() ?? '';
    final rawInitials = map['initials']?.toString() ?? '';

    return PersonItem(
      id: docId ?? map['id']?.toString() ?? '',
      name: nameStr,
      role: map['role']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      locationOrEvent: map['locationOrEvent']?.toString() ?? map['location']?.toString(),
      contextSnippet: map['contextSnippet']?.toString(),
      lastInteraction: map['lastInteraction']?.toString(),
      lastInteractionDate: parseDate(map['lastInteractionDate']),
      initials: rawInitials.isNotEmpty ? rawInitials : computeInitials(nameStr),
      capabilities: (map['capabilities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      pendingFollowUp: map['pendingFollowUp']?.toString(),
      hasPendingFollowUp: map['hasPendingFollowUp'] == true,
      interactionCount: (map['interactionCount'] as num?)?.toInt() ?? 1,
      relationshipType: map['relationshipType'] != null
          ? RelationshipContextType.values.firstWhere(
              (e) => e.name == map['relationshipType'],
              orElse: () => RelationshipContextType.collaborator,
            )
          : null,
      avatarUrl: map['avatarUrl']?.toString(),
      userId: map['userId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory PersonItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PersonItem.fromMap(data, doc.id);
  }

  PersonItem copyWith({
    String? id,
    String? name,
    String? role,
    String? company,
    String? email,
    String? phone,
    String? locationOrEvent,
    String? contextSnippet,
    String? lastInteraction,
    DateTime? lastInteractionDate,
    String? initials,
    List<String>? capabilities,
    String? pendingFollowUp,
    bool? hasPendingFollowUp,
    int? interactionCount,
    RelationshipContextType? relationshipType,
    String? avatarUrl,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonItem(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      locationOrEvent: locationOrEvent ?? this.locationOrEvent,
      contextSnippet: contextSnippet ?? this.contextSnippet,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      lastInteractionDate: lastInteractionDate ?? this.lastInteractionDate,
      initials: initials ?? this.initials,
      capabilities: capabilities ?? this.capabilities,
      pendingFollowUp: pendingFollowUp ?? this.pendingFollowUp,
      hasPendingFollowUp: hasPendingFollowUp ?? this.hasPendingFollowUp,
      interactionCount: interactionCount ?? this.interactionCount,
      relationshipType: relationshipType ?? this.relationshipType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Filter options for People Directory.
enum PeopleFilterOption {
  all,
  recentlyInteracted,
  followUpDue,
  aiMl,
  founders,
  deepTech,
}

extension PeopleFilterOptionExt on PeopleFilterOption {
  bool matches(PersonItem person) {
    switch (this) {
      case PeopleFilterOption.all:
        return true;
      case PeopleFilterOption.recentlyInteracted:
        if (person.lastInteractionDate == null) return false;
        return DateTime.now().difference(person.lastInteractionDate!).inDays <= 7;
      case PeopleFilterOption.followUpDue:
        return person.hasPendingFollowUp;
      case PeopleFilterOption.aiMl:
        return person.capabilities.any((c) =>
            c.toLowerCase().contains('ai') ||
            c.toLowerCase().contains('slm') ||
            c.toLowerCase().contains('llm') ||
            c.toLowerCase().contains('speech'));
      case PeopleFilterOption.founders:
        return person.relationshipType == RelationshipContextType.founder ||
            person.role.toLowerCase().contains('founder') ||
            person.role.toLowerCase().contains('ceo');
      case PeopleFilterOption.deepTech:
        return person.capabilities.any((c) =>
            c.toLowerCase().contains('quantum') ||
            c.toLowerCase().contains('hardware') ||
            c.toLowerCase().contains('cmos') ||
            c.toLowerCase().contains('silicon') ||
            c.toLowerCase().contains('risc-v'));
    }
  }
  String get label {
    switch (this) {
      case PeopleFilterOption.all:
        return 'All People';
      case PeopleFilterOption.recentlyInteracted:
        return 'Recent';
      case PeopleFilterOption.followUpDue:
        return 'Follow-up Due';
      case PeopleFilterOption.aiMl:
        return 'AI & SLMs';
      case PeopleFilterOption.founders:
        return 'Founders';
      case PeopleFilterOption.deepTech:
        return 'DeepTech & Hardware';
    }
  }

  IconData? get icon {
    switch (this) {
      case PeopleFilterOption.all:
        return null;
      case PeopleFilterOption.recentlyInteracted:
        return Icons.history_rounded;
      case PeopleFilterOption.followUpDue:
        return Icons.bolt_rounded;
      case PeopleFilterOption.aiMl:
        return Icons.auto_awesome_rounded;
      case PeopleFilterOption.founders:
        return Icons.business_center_outlined;
      case PeopleFilterOption.deepTech:
        return Icons.memory_rounded;
    }
  }
}