import 'package:flutter/painting.dart';

/// Design tokens: corner radius.
abstract final class AppRadius {
  static const double radiusHero = 32;
  static const double radiusCard = 20;
  static const double radiusField = 12;
  static const double radiusPill = 999;

  /// `radiusCircle` (50%) is done with [BoxShape.circle] or a large radius.
  static const double radiusCircle = 999;

  static const BorderRadius card = BorderRadius.all(
    Radius.circular(radiusCard),
  );
  static const BorderRadius field = BorderRadius.all(
    Radius.circular(radiusField),
  );
  static const BorderRadius pill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  /// Bottom corners of the hero header.
  static const BorderRadius hero = BorderRadius.vertical(
    bottom: Radius.circular(radiusHero),
  );

  /// Top corners of sheets.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(radiusCard),
  );
}
