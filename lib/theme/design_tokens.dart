import 'package:flutter/material.dart';

/// Centralised design tokens — the 8-point spacing grid, corner radii,
/// motion durations and easing curves used across the redesigned UI.
///
/// Using these instead of magic numbers keeps spacing rhythm consistent and
/// makes the whole app feel intentional rather than ad-hoc.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

abstract final class Radii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration entrance = Duration(milliseconds: 520);

  /// Standard "settle" curve for most state transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Slightly springy curve for press / pop interactions.
  static const Curve emphasized = Curves.easeOutBack;
}
