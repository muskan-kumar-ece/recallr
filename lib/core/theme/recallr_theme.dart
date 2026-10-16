import 'package:flutter/material.dart';
import 'recallr_colors.dart';
import 'recallr_spacing.dart';
import 'recallr_radii.dart';
import 'recallr_typography.dart';

/// Custom ThemeExtension providing type-safe access to all Recallr design tokens.
class RecallrThemeColors extends ThemeExtension<RecallrThemeColors> {
  final Color obsidianBase;
  final Color slateSurface;
  final Color charcoalCard;
  final Color glassOverlay;
  final Color aiElectricViolet;
  final Color aiCyanHighlight;
  final Color warmAmberGold;
  final Color emeraldVerified;
  final Color crimsonAlert;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderSubtle;
  final Color borderHighlight;

  const RecallrThemeColors({
    required this.obsidianBase,
    required this.slateSurface,
    required this.charcoalCard,
    required this.glassOverlay,
    required this.aiElectricViolet,
    required this.aiCyanHighlight,
    required this.warmAmberGold,
    required this.emeraldVerified,
    required this.crimsonAlert,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderSubtle,
    required this.borderHighlight,
  });

  static const dark = RecallrThemeColors(
    obsidianBase: RecallrColors.obsidianBase,
    slateSurface: RecallrColors.slateSurface,
    charcoalCard: RecallrColors.charcoalCard,
    glassOverlay: RecallrColors.glassOverlay,
    aiElectricViolet: RecallrColors.aiElectricViolet,
    aiCyanHighlight: RecallrColors.aiCyanHighlight,
    warmAmberGold: RecallrColors.warmAmberGold,
    emeraldVerified: RecallrColors.emeraldVerified,
    crimsonAlert: RecallrColors.crimsonAlert,
    textPrimary: RecallrColors.textPrimary,
    textSecondary: RecallrColors.textSecondary,
    textTertiary: RecallrColors.textTertiary,
    borderSubtle: RecallrColors.borderSubtle,
    borderHighlight: RecallrColors.borderHighlight,
  );

  @override
  ThemeExtension<RecallrThemeColors> copyWith({
    Color? obsidianBase,
    Color? slateSurface,
    Color? charcoalCard,
    Color? glassOverlay,
    Color? aiElectricViolet,
    Color? aiCyanHighlight,
    Color? warmAmberGold,
    Color? emeraldVerified,
    Color? crimsonAlert,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? borderSubtle,
    Color? borderHighlight,
  }) {
    return RecallrThemeColors(
      obsidianBase: obsidianBase ?? this.obsidianBase,
      slateSurface: slateSurface ?? this.slateSurface,
      charcoalCard: charcoalCard ?? this.charcoalCard,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      aiElectricViolet: aiElectricViolet ?? this.aiElectricViolet,
      aiCyanHighlight: aiCyanHighlight ?? this.aiCyanHighlight,
      warmAmberGold: warmAmberGold ?? this.warmAmberGold,
      emeraldVerified: emeraldVerified ?? this.emeraldVerified,
      crimsonAlert: crimsonAlert ?? this.crimsonAlert,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderHighlight: borderHighlight ?? this.borderHighlight,
    );
  }

  @override
  ThemeExtension<RecallrThemeColors> lerp(
    covariant ThemeExtension<RecallrThemeColors>? other,
    double t,
  ) {
    if (other is! RecallrThemeColors) return this;
    return RecallrThemeColors(
      obsidianBase: Color.lerp(obsidianBase, other.obsidianBase, t)!,
      slateSurface: Color.lerp(slateSurface, other.slateSurface, t)!,
      charcoalCard: Color.lerp(charcoalCard, other.charcoalCard, t)!,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      aiElectricViolet: Color.lerp(aiElectricViolet, other.aiElectricViolet, t)!,
      aiCyanHighlight: Color.lerp(aiCyanHighlight, other.aiCyanHighlight, t)!,
      warmAmberGold: Color.lerp(warmAmberGold, other.warmAmberGold, t)!,
      emeraldVerified: Color.lerp(emeraldVerified, other.emeraldVerified, t)!,
      crimsonAlert: Color.lerp(crimsonAlert, other.crimsonAlert, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
    );
  }
}

/// Convenience context extension for accessing Recallr theme tokens.
extension RecallrThemeExtension on BuildContext {
  RecallrThemeColors get colors =>
      Theme.of(this).extension<RecallrThemeColors>() ?? RecallrThemeColors.dark;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Central Recallr Flutter ThemeData configuration.
class RecallrTheme {
  RecallrTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RecallrColors.obsidianBase,
      canvasColor: RecallrColors.slateSurface,
      extensions: const [RecallrThemeColors.dark],
      textTheme: RecallrTypography.textTheme,
      colorScheme: const ColorScheme.dark(
        primary: RecallrColors.aiElectricViolet,
        onPrimary: RecallrColors.textPrimary,
        secondary: RecallrColors.aiCyanHighlight,
        onSecondary: RecallrColors.obsidianBase,
        surface: RecallrColors.charcoalCard,
        onSurface: RecallrColors.textPrimary,
        error: RecallrColors.crimsonAlert,
        onError: RecallrColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RecallrColors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: RecallrColors.textPrimary, size: RecallrIconography.lg),
        titleTextStyle: RecallrTypography.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: RecallrColors.charcoalCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: const BorderSide(color: RecallrColors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RecallrColors.charcoalCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RecallrSpacing.md,
          vertical: RecallrSpacing.md,
        ),
        hintStyle: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textTertiary),
        labelStyle: RecallrTypography.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: const BorderSide(color: RecallrColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: const BorderSide(color: RecallrColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: const BorderSide(color: RecallrColors.borderHighlight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: const BorderSide(color: RecallrColors.crimsonAlert, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RecallrColors.aiElectricViolet,
          foregroundColor: RecallrColors.textPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: RecallrSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusMd),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RecallrColors.textPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: RecallrColors.borderSubtle, width: 1),
          padding: RecallrSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusMd),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RecallrColors.aiCyanHighlight,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md, vertical: RecallrSpacing.sm),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RecallrColors.slateSurface,
        disabledColor: RecallrColors.charcoalCard,
        selectedColor: RecallrColors.aiElectricViolet,
        labelStyle: RecallrTypography.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.sm, vertical: RecallrSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusPill,
          side: const BorderSide(color: RecallrColors.borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RecallrColors.slateSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: const BorderSide(color: RecallrColors.borderHighlight, width: 1),
        ),
        titleTextStyle: RecallrTypography.headlineMedium,
        contentTextStyle: RecallrTypography.bodyLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RecallrColors.slateSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusTopSheet),
        dragHandleColor: RecallrColors.textTertiary,
        showDragHandle: true,
      ),
      dividerTheme: const DividerThemeData(
        color: RecallrColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}