import 'package:flutter/material.dart';

/// Spacing and layout tokens following a strict 4px/8px base grid.
class RecallrSpacing {
  RecallrSpacing._();

  // Base Grid Values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Standard EdgeInsets Insets
  static const EdgeInsets insetXs = EdgeInsets.all(xs);
  static const EdgeInsets insetSm = EdgeInsets.all(sm);
  static const EdgeInsets insetMd = EdgeInsets.all(md);
  static const EdgeInsets insetLg = EdgeInsets.all(lg);
  static const EdgeInsets insetXl = EdgeInsets.all(xl);

  // Symmetric Padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md, vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // Spacing Gaps (SizedBox)
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
}