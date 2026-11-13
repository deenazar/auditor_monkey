import 'package:flutter/services.dart';

/// One place for haptics, so every key tap feels the same.
abstract final class AppHaptics {
  /// Keys, chips, tabs, small taps.
  static void tap() => HapticFeedback.selectionClick();

  /// Buttons and cards pressed.
  static void press() => HapticFeedback.lightImpact();

  /// Saved, goal reached, long-press preview opened.
  static void success() => HapticFeedback.mediumImpact();

  /// Swipe-to-delete threshold, refused input.
  static void warning() => HapticFeedback.heavyImpact();
}
