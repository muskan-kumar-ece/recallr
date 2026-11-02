import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static RecallrThemeColors get dark => RecallrThemeColors(
        obsidianBase: const Color(0xFF09090B),
        slateSurface: const Color(0xFF18181B),
        charcoalCard: const Color(0xFF202024),
        glassOverlay: const Color(0xB318181B),
        aiElectricViolet: RecallrColors.aiElectricViolet,
        aiCyanHighlight: RecallrColors.aiCyanHighlight,
        warmAmberGold: RecallrColors.warmAmberGold,
        emeraldVerified: RecallrColors.emeraldVerified,
        crimsonAlert: RecallrColors.crimsonAlert,
        textPrimary: const Color(0xFFF5F5F7),
        textSecondary: const Color(0xFFA1A1AA),
        textTertiary: const Color(0xFF71717A),
        borderSubtle: const Color(0xFF27272A),
        borderHighlight: const Color(0xFF3F3F46),
      );

  static RecallrThemeColors get light => RecallrThemeColors(
        obsidianBase: const Color(0xFFF7F7FA),
        slateSurface: Colors.white,
        charcoalCard: const Color(0xFFF0F0F4),
        glassOverlay: const Color(0xE6FFFFFF),
        aiElectricViolet: RecallrColors.aiElectricViolet,
        aiCyanHighlight: RecallrColors.aiCyanHighlight,
        warmAmberGold: RecallrColors.warmAmberGold,
        emeraldVerified: RecallrColors.emeraldVerified,
        crimsonAlert: const Color(0xFFDC2626),
        textPrimary: const Color(0xFF18181B),
        textSecondary: const Color(0xFF52525B),
        textTertiary: const Color(0xFF71717A),
        borderSubtle: const Color(0xFFE4E4E7),
        borderHighlight: const Color(0xFFA1A1AA),
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
      aiElectricViolet:
          Color.lerp(aiElectricViolet, other.aiElectricViolet, t)!,
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

/// Runtime theme preference shared by the app shell and Settings.
class RecallrThemeModeController {
  RecallrThemeModeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    mode.value = ThemeMode.values
        .firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value.name);
  }

  static String label(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

/// Central Recallr Flutter ThemeData configuration.
class RecallrTheme {
  RecallrTheme._();

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colors: RecallrThemeColors.dark,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colors: RecallrThemeColors.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required RecallrThemeColors colors,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.obsidianBase,
      canvasColor: colors.slateSurface,
      extensions: [colors],
      textTheme: RecallrTypography.textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: RecallrColors.aiElectricViolet,
        onPrimary: colors.textPrimary,
        secondary: RecallrColors.aiCyanHighlight,
        onSecondary: colors.obsidianBase,
        surface: colors.charcoalCard,
        onSurface: colors.textPrimary,
        error: colors.crimsonAlert,
        onError: colors.textPrimary,
        surfaceContainerHighest: colors.charcoalCard,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
            color: colors.textPrimary, size: RecallrIconography.lg),
        titleTextStyle: RecallrTypography.headlineMedium
            .copyWith(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.charcoalCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.charcoalCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RecallrSpacing.md,
          vertical: RecallrSpacing.md,
        ),
        hintStyle:
            RecallrTypography.bodyMedium.copyWith(color: colors.textTertiary),
        labelStyle: RecallrTypography.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: BorderSide(color: colors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: BorderSide(color: colors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: BorderSide(color: colors.borderHighlight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusMd,
          borderSide: BorderSide(color: colors.crimsonAlert, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RecallrColors.aiElectricViolet,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: RecallrSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusMd),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: colors.borderSubtle, width: 1),
          padding: RecallrSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusMd),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RecallrColors.aiCyanHighlight,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
              horizontal: RecallrSpacing.md, vertical: RecallrSpacing.sm),
          textStyle: RecallrTypography.titleMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.slateSurface,
        disabledColor: colors.charcoalCard,
        selectedColor: RecallrColors.aiElectricViolet,
        labelStyle: RecallrTypography.bodyMedium,
        padding: const EdgeInsets.symmetric(
            horizontal: RecallrSpacing.sm, vertical: RecallrSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusPill,
          side: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.slateSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: BorderSide(color: colors.borderHighlight, width: 1),
        ),
        titleTextStyle: RecallrTypography.headlineMedium,
        contentTextStyle: RecallrTypography.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.slateSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: RecallrRadii.radiusTopSheet),
        dragHandleColor: colors.textTertiary,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
