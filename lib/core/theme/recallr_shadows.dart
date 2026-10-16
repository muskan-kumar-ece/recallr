import 'package:flutter/material.dart';

/// Elevation, depth, and shadow tokens for Recallr.
class RecallrShadows {
  RecallrShadows._();

  // Tonal subtle elevations
  static const BoxShadow elevation0 = BoxShadow(
    color: Colors.transparent,
  );

  static const BoxShadow elevation1 = BoxShadow(
    color: Colors.black38,
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  static const BoxShadow elevation2 = BoxShadow(
    color: Colors.black54,
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  // Glowing AI Shadow for FAB and AI Highlights
  static const BoxShadow glowAi = BoxShadow(
    color: Color(0x558B5CF6),
    offset: Offset(0, 0),
    blurRadius: 16,
    spreadRadius: 2,
  );
}