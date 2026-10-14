import 'package:flutter/material.dart';

/// Skala radius kurvatur FitLife.id (dibatasi tepat 3 nilai radius)
class AppRadius {
  AppRadius._();

  /// Radius kecil (8.0): untuk chips, tag status, dan micro-components
  static const double sm = 8.0;

  /// Radius sedang (14.0): untuk buttons, input textfield, dan thumbnail
  static const double md = 14.0;

  /// Radius besar (20.0): untuk cards, modal bottom sheet, dan container modul
  static const double lg = 20.0;

  // BorderRadius helpers
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
}
