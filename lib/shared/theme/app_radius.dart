import 'package:flutter/painting.dart';

/// Design tokens: corner radius (mini_checklist values).
abstract final class AppRadius {
  /// Panel and sheet top corners (26).
  static const double radiusHero = 26;

  /// Cards, tiles, rows (18).
  static const double radiusCard = 18;

  /// Inputs, small buttons, day chips (12).
  static const double radiusField = 12;
  static const double radiusPill = 999;

  /// `radiusCircle` (50%) is done with [BoxShape.circle] or a large radius.
  static const double radiusCircle = 999;

  /// Week-bar glass panel (20).
  static const double radiusGlassPanel = 20;

  static const BorderRadius card = BorderRadius.all(
    Radius.circular(radiusCard),
  );
  static const BorderRadius field = BorderRadius.all(
    Radius.circular(radiusField),
  );
  static const BorderRadius pill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  /// Bottom corners of a hero header.
  static const BorderRadius hero = BorderRadius.vertical(
    bottom: Radius.circular(radiusHero),
  );

  /// Top corners of sheets and the sliding panel.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(radiusHero),
  );
}
