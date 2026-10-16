import 'package:flutter/material.dart';

/// Memory Pulse Statistics for the compact header/grid.
class MemoryPulseStats {
  final int peopleCount;
  final int companiesCount;
  final int interactionsCount;
  final int followUpsCount;

  const MemoryPulseStats({
    required this.peopleCount,
    required this.companiesCount,
    required this.interactionsCount,
    required this.followUpsCount,
  });

  static const empty = MemoryPulseStats(
    peopleCount: 0,
    companiesCount: 0,
    interactionsCount: 0,
    followUpsCount: 0,
  );
}

/// Category of attention signal.
enum AttentionType {
  followUp,
  missingContext,
  staleRelationship,
  pendingCommitment,
}

/// Actionable memory signal card model.
class AttentionItem {
  final String id;
  final AttentionType type;
  final String title;
  final String description;
  final String targetRoute;
  final String badgeText;
  final String? dueText;
  final IconData icon;

  const AttentionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetRoute,
    required this.badgeText,
    this.dueText,
    required this.icon,
  });
}

/// Entity type for recently remembered item.
enum MemoryType {
  person,
  company,
  interaction,
  note,
}

/// Recently interacted person item model.
class RecentPersonItem {
  final String id;
  final String name;
  final String role;
  final String company;
  final String? lastInteracted;
  final String initials;
  final String? topCapability;
  final String targetRoute;

  const RecentPersonItem({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    this.lastInteracted,
    required this.initials,
    this.topCapability,
    required this.targetRoute,
  });
}

/// Context-rich memory item model.
class RecentMemoryItem {
  final String id;
  final MemoryType type;
  final String title;
  final String? subtitle;
  final String? eventOrLocation;
  final String contextSnippet;
  final String? timeAgo;
  final String initials;
  final String targetRoute;
  final List<String> tags;

  const RecentMemoryItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.eventOrLocation,
    required this.contextSnippet,
    this.timeAgo,
    required this.initials,
    required this.targetRoute,
    this.tags = const [],
  });
}