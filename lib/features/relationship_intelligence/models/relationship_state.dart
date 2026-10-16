import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Deterministic relationship classification states for Recallr.
enum RelationshipState {
  /// Recently added contact with minimal historical interactions.
  newRelationship,

  /// Ongoing active relationship with regular recent interactions.
  active,

  /// High-strength relationship with frequent interactions, rich context, and high recency.
  strong,

  /// Previously active relationship where interaction recency is cooling off (31–60 days).
  cooling,

  /// Meaningful historical connection with no recent interactions (>60 days) or overdue commitments.
  neglected,

  /// Long-standing connection with no interaction in over 180 days.
  dormant;

  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case RelationshipState.newRelationship:
        return 'New';
      case RelationshipState.active:
        return 'Active';
      case RelationshipState.strong:
        return 'Strong';
      case RelationshipState.cooling:
        return 'Cooling';
      case RelationshipState.neglected:
        return 'Neglected';
      case RelationshipState.dormant:
        return 'Dormant';
    }
  }

  /// Uppercase badge label for UI tags.
  String get badgeLabel {
    switch (this) {
      case RelationshipState.newRelationship:
        return 'NEW';
      case RelationshipState.active:
        return 'ACTIVE';
      case RelationshipState.strong:
        return 'STRONG';
      case RelationshipState.cooling:
        return 'COOLING';
      case RelationshipState.neglected:
        return 'NEGLECTED';
      case RelationshipState.dormant:
        return 'DORMANT';
    }
  }

  /// Short explanation of what this state represents.
  String get description {
    switch (this) {
      case RelationshipState.newRelationship:
        return 'Recently added contact with limited relationship history.';
      case RelationshipState.active:
        return 'Recent meaningful interactions and ongoing regular activity.';
      case RelationshipState.strong:
        return 'High relationship strength with deep interaction history and high recency.';
      case RelationshipState.cooling:
        return 'Previously active relationship with declining recent engagement.';
      case RelationshipState.neglected:
        return 'Meaningful connection with no recent contact or overdue commitments.';
      case RelationshipState.dormant:
        return 'Long-standing relationship with no recorded interactions for over 6 months.';
    }
  }

  /// Visual theme color for badge rendering.
  Color get colorToken {
    switch (this) {
      case RelationshipState.strong:
        return RecallrColors.emeraldVerified;
      case RelationshipState.active:
        return RecallrColors.aiCyanHighlight;
      case RelationshipState.cooling:
        return RecallrColors.warmAmberGold;
      case RelationshipState.neglected:
        return RecallrColors.crimsonAlert;
      case RelationshipState.dormant:
        return RecallrColors.textTertiary;
      case RelationshipState.newRelationship:
        return RecallrColors.aiElectricViolet;
    }
  }

  /// Alias for colorToken.
  Color get badgeColor => colorToken;

  /// Alias for displayName.
  String get label => displayName;

  /// Precedence ranking (higher value = evaluated earlier in classification).
  int get precedenceRank {
    switch (this) {
      case RelationshipState.dormant:
        return 6;
      case RelationshipState.neglected:
        return 5;
      case RelationshipState.cooling:
        return 4;
      case RelationshipState.strong:
        return 3;
      case RelationshipState.active:
        return 2;
      case RelationshipState.newRelationship:
        return 1;
    }
  }

  /// Serializes to a standard string identifier.
  String toValue() => name;

  /// Deserializes from string with safe fallback to `newRelationship`.
  static RelationshipState fromValue(String? value) {
    if (value == null || value.isEmpty) return RelationshipState.newRelationship;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'new' || normalized == 'newrelationship') {
      return RelationshipState.newRelationship;
    }
    for (final state in RelationshipState.values) {
      if (state.name.toLowerCase() == normalized) {
        return state;
      }
    }
    return RelationshipState.newRelationship;
  }
}
