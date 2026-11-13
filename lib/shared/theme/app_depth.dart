import 'package:flutter/animation.dart';

/// Design tokens for the Motion & 3D layer (DESIGN.md "Motion & 3D").
/// The base design tokens are unchanged; these sit on top.
abstract final class AppDepth {
  /// Perspective for 3D transforms (Matrix4 entry 3,2).
  static const double perspective = 0.0012;

  /// Card tilt under the finger, degrees.
  static const double tiltMax = 8;

  /// Card scale while pressed.
  static const double pressScale = 0.97;

  /// Spring back after a tilt or press: cubic-bezier(.2,1.6,.4,1).
  static const Curve springy = Cubic(0.2, 1.6, 0.4, 1);

  /// Softer bounce for reactions and pop-ins: cubic-bezier(.2,1.3,.4,1).
  static const Curve bouncy = Cubic(0.2, 1.3, 0.4, 1);

  /// Charts and lines drawing in: cubic-bezier(.2,1.2,.3,1) clamps fine.
  static const Curve draw = Curves.easeOutCubic;

  static const Duration tiltSettle = Duration(milliseconds: 450);
  static const Duration press = Duration(milliseconds: 200);

  /// Parallax: background layers move this share of the scroll.
  static const double parallaxBack = 0.35;
  static const double parallaxMid = 0.18;

  /// 3D flip between wizard steps: max Y rotation in degrees and time.
  static const double flipDegrees = 70;
  static const Duration flip = Duration(milliseconds: 420);

  /// Wizard steps turn this far in 3D (around their centre) as they move.
  static const double stepTurnDegrees = 28;

  /// Header blobs: one loop and how long they drift after a touch.
  static const Duration blobLoop = Duration(seconds: 14);
  static const Duration sceneRestAfter = Duration(seconds: 15);

  /// Shimmer sweep and how long it runs before resting (battery).
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration shimmerMax = Duration(seconds: 10);

  /// Confetti fall time and pieces.
  static const Duration confetti = Duration(milliseconds: 1800);
  static const int confettiPieces = 60;

  /// Long-press preview: scale in from and time.
  static const double previewFrom = 0.86;
  static const Duration preview = Duration(milliseconds: 320);

  /// Area chart line draw-in.
  static const Duration chartDraw = Duration(milliseconds: 900);
}
