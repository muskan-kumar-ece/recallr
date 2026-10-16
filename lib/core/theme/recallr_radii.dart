import 'package:flutter/material.dart';

/// Border radius tokens for Recallr design system.
class RecallrRadii {
  RecallrRadii._();

  // Radius Constants
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double pill = 999.0;

  // BorderRadius Constants
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));

  // Top Sheet Radius
  static const BorderRadius radiusTopSheet = BorderRadius.vertical(top: Radius.circular(lg));
}