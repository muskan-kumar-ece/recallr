import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Directional type of network-level measurable change.
enum NetworkTrendType {
  growing,
  strengthening,
  cooling,
  declining,
  stable,
  insufficientData;

  String get displayName {
    switch (this) {
      case NetworkTrendType.growing:
        return 'Growing';
      case NetworkTrendType.strengthening:
        return 'Strengthening';
      case NetworkTrendType.cooling:
        return 'Cooling';
      case NetworkTrendType.declining:
        return 'Declining';
      case NetworkTrendType.stable:
        return 'Stable';
      case NetworkTrendType.insufficientData:
        return 'Insufficient History';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkTrendType.growing:
        return Icons.trending_up_rounded;
      case NetworkTrendType.strengthening:
        return Icons.auto_awesome_rounded;
      case NetworkTrendType.cooling:
        return Icons.ac_unit_rounded;
      case NetworkTrendType.declining:
        return Icons.trending_down_rounded;
      case NetworkTrendType.stable:
        return Icons.trending_flat_rounded;
      case NetworkTrendType.insufficientData:
        return Icons.history_rounded;
    }
  }

  Color get colorToken {
    switch (this) {
      case NetworkTrendType.growing:
      case NetworkTrendType.strengthening:
        return RecallrColors.emeraldVerified;
      case NetworkTrendType.cooling:
        return RecallrColors.warmAmberGold;
      case NetworkTrendType.declining:
        return RecallrColors.crimsonAlert;
      case NetworkTrendType.stable:
        return RecallrColors.aiCyanHighlight;
      case NetworkTrendType.insufficientData:
        return RecallrColors.textTertiary;
    }
  }
}

/// Represents a measurable, temporal change in the user's professional network.
@immutable
class NetworkTrend {
  final NetworkTrendType type;
  final double currentValue;
  final double previousValue;
  final double delta;
  final double? percentageChange;
  final String periodLabel;
  final String description;
  final bool hasSufficientData;

  const NetworkTrend({
    required this.type,
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    this.percentageChange,
    required this.periodLabel,
    required this.description,
    this.hasSufficientData = true,
  });

  /// Factory for when insufficient historical data exists to claim a trend.
  factory NetworkTrend.insufficientData({
    required String periodLabel,
    String description = 'Not enough historical interaction data to compute trends yet.',
  }) {
    return NetworkTrend(
      type: NetworkTrendType.insufficientData,
      currentValue: 0.0,
      previousValue: 0.0,
      delta: 0.0,
      percentageChange: null,
      periodLabel: periodLabel,
      description: description,
      hasSufficientData: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'currentValue': currentValue,
      'previousValue': previousValue,
      'delta': delta,
      'percentageChange': percentageChange,
      'periodLabel': periodLabel,
      'description': description,
      'hasSufficientData': hasSufficientData,
    };
  }

  factory NetworkTrend.fromMap(Map<String, dynamic> map) {
    return NetworkTrend(
      type: NetworkTrendType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NetworkTrendType.stable,
      ),
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      previousValue: (map['previousValue'] as num?)?.toDouble() ?? 0.0,
      delta: (map['delta'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (map['percentageChange'] as num?)?.toDouble(),
      periodLabel: map['periodLabel'] as String? ?? 'vs previous period',
      description: map['description'] as String? ?? '',
      hasSufficientData: map['hasSufficientData'] as bool? ?? true,
    );
  }
}
