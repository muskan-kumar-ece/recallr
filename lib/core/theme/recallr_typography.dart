import 'package:flutter/material.dart';
import 'recallr_colors.dart';

/// Editorial sans-serif typography hierarchy for Recallr.
class RecallrTypography {
  RecallrTypography._();

  /// Display Large: 30px / w600 / -1.0% letter spacing
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 30.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
    color: RecallrColors.textPrimary,
  );

  /// Headline Medium: 22px / w600 / -0.5% letter spacing
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.11,
    height: 1.25,
    color: RecallrColors.textPrimary,
  );

  /// Title Medium: 16px / w500 / 0% letter spacing
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    height: 1.35,
    color: RecallrColors.textPrimary,
  );

  /// Body Large: 15px / w400 / 1.5 height
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.5,
    color: RecallrColors.textPrimary,
  );

  /// Body Medium: 13px / w400 / 1.4 height
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.4,
    color: RecallrColors.textSecondary,
  );

  /// Label Small: 11px / w600 / +1.5% letter spacing / uppercase
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.165,
    height: 1.2,
    color: RecallrColors.textSecondary,
  );

  /// Mono Metadata: 12px / w400 (JetBrains Mono / system monospace)
  static const TextStyle monoMetadata = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.4,
    color: RecallrColors.textTertiary,
  );

  /// Material TextTheme mapping
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    headlineMedium: headlineMedium,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    labelSmall: labelSmall,
  );
}

/// Iconography dimensions
class RecallrIconography {
  RecallrIconography._();
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}