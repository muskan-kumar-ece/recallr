import 'package:flutter/material.dart';

/// Represents a single conversation turn in an Ask session.
class ConversationTurn {
  final String id;
  final String question;
  final GroundedAnswer? answer;
  final DateTime timestamp;

  const ConversationTurn({
    required this.id,
    required this.question,
    this.answer,
    required this.timestamp,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer != null ? {
        'queryId': answer!.queryId,
        'queryText': answer!.queryText,
        'answerText': answer!.answerText,
      } : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// A person mentioned/cited in an answer with context of why they are relevant.
class PersonReference {
  final String id;
  final String name;
  final String role;
  final String company;
  final String initials;
  final String relationshipContext;
  final String targetRoute;

  const PersonReference({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.initials,
    required this.relationshipContext,
    required this.targetRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'company': company,
      'initials': initials,
      'relationshipContext': relationshipContext,
      'targetRoute': targetRoute,
    };
  }

  factory PersonReference.fromMap(Map<String, dynamic> map) {
    return PersonReference(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      initials: map['initials']?.toString() ?? '',
      relationshipContext: map['relationshipContext']?.toString() ?? '',
      targetRoute: map['targetRoute']?.toString() ?? '/people',
    );
  }
}

/// A source/provenance unit backing an answer.
class MemorySource {
  final String id;
  final String sourceType;
  final IconData icon;
  final String personName;
  final String personRole;
  final String company;
  final String? eventOrLocation;
  final String date;
  final String excerpt;
  final bool isVerified;
  final String? targetRoute;

  const MemorySource({
    required this.id,
    required this.sourceType,
    required this.icon,
    required this.personName,
    required this.personRole,
    required this.company,
    this.eventOrLocation,
    required this.date,
    required this.excerpt,
    this.isVerified = true,
    this.targetRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType,
      'personName': personName,
      'personRole': personRole,
      'company': company,
      'eventOrLocation': eventOrLocation,
      'date': date,
      'excerpt': excerpt,
      'isVerified': isVerified,
      'targetRoute': targetRoute,
    };
  }
}

/// Metadata about the grounding evidence.
class GroundingMetadata {
  final int memoryCount;
  final int personCount;
  final String groundingSummary;

  const GroundingMetadata({
    required this.memoryCount,
    required this.personCount,
    required this.groundingSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'memoryCount': memoryCount,
      'personCount': personCount,
      'groundingSummary': groundingSummary,
    };
  }

  factory GroundingMetadata.fromMap(Map<String, dynamic> map) {
    return GroundingMetadata(
      memoryCount: (map['memoryCount'] as num?)?.toInt() ?? 0,
      personCount: (map['personCount'] as num?)?.toInt() ?? 0,
      groundingSummary: map['groundingSummary']?.toString() ?? '',
    );
  }
}

/// Complete Grounded Answer produced by the Memory Engine.
class GroundedAnswer {
  final String queryId;
  final String queryText;
  final String answerText;
  final GroundingMetadata metadata;
  final List<PersonReference> relatedPeople;
  final List<MemorySource> sources;
  final List<String> followUpSuggestions;

  const GroundedAnswer({
    required this.queryId,
    required this.queryText,
    required this.answerText,
    required this.metadata,
    this.relatedPeople = const [],
    this.sources = const [],
    this.followUpSuggestions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'queryId': queryId,
      'queryText': queryText,
      'answerText': answerText,
      'metadata': metadata.toMap(),
      'relatedPeople': relatedPeople.map((e) => e.toMap()).toList(),
      'sources': sources.map((e) => e.toMap()).toList(),
      'followUpSuggestions': followUpSuggestions,
    };
  }
}