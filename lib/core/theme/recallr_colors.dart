import 'package:flutter/material.dart';

/// Centralized color tokens for the Recallr Design System (Dark-First Pro Theme).
class RecallrColors {
  RecallrColors._();

  // Base Backgrounds & Surfaces
  static const Color obsidianBase = Color(0xFF09090B);
  static const Color slateSurface = Color(0xFF18181B);
  static const Color charcoalCard = Color(0xFF202024);
  
  // Glass Overlay (70% opacity applied to slate)
  static const Color glassOverlay = Color(0xB318181B);

  // Accents & AI Tokens
  static const Color aiElectricViolet = Color(0xFF8B5CF6);
  static const Color aiElectricVioletPressed = Color(0xFF7C3AED);
  static const Color aiCyanHighlight = Color(0xFF06B6D4);
  
  // Semantic Tokens
  static const Color warmAmberGold = Color(0xFFF59E0B);
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color crimsonAlert = Color(0xFFF87171);

  // High-Contrast Accessible Typography
  static const Color textPrimary = Color(0xFFF5F5F7);
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