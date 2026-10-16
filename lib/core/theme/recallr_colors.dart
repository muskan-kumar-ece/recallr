import 'package:flutter/material.dart';

/// Centralized color tokens for the Recallr Design System (Dark-First Pro Theme).
class RecallrColors {
  RecallrColors._();

  // Base Backgrounds & Surfaces
  static const Color obsidianBase = Color(0xFF0A0A0C);
  static const Color slateSurface = Color(0xFF131316);
  static const Color charcoalCard = Color(0xFF1C1C20);
  
  // Glass Overlay (70% opacity applied to slate)
  static const Color glassOverlay = Color(0xB3131316);

  // Accents & AI Tokens
  static const Color aiElectricViolet = Color(0xFF8B5CF6);
  static const Color aiCyanHighlight = Color(0xFF06B6D4);
  
  // Semantic Tokens
  static const Color warmAmberGold = Color(0xFFF59E0B);
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color crimsonAlert = Color(0xFFEF4444);

  // High-Contrast Accessible Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);

  // 1px Restrained Borders
  static const Color borderSubtle = Color(0xFF27272A);
  static const Color borderHighlight = Color(0xFF3F3F46);

  // AI Gradient Definition
  static const LinearGradient aiGradient = LinearGradient(
    colors: [aiElectricViolet, aiCyanHighlight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}