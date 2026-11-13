import 'package:flutter/animation.dart';

import '../../../shared/scene/keyframes.dart';
import '../../../shared/theme/app_depth.dart';

/// mimi-world.css keyframes for the figure, ported 1:1. Translations are
/// fractions of the figure height (CSS `%` on `.mw-figure`), angles are
/// degrees.
class FigureMotion {
  const FigureMotion({
    required this.seconds,
    this.dy,
    this.scaleX,
    this.scaleY,
    this.rotate,
    this.movesPaw = false,
    this.repeat = 1,
  });

  final double seconds;
  final Keyframes? dy;
  final Keyframes? scaleX;
  final Keyframes? scaleY;
  final Keyframes? rotate;

  /// Moves the right paw (mwWave) instead of the whole figure.
  final bool movesPaw;

  /// CSS `animation-iteration-count`.
  final int repeat;

  Duration get duration =>
      Duration(milliseconds: (seconds * repeat * 1000).round());

  /// mwJump .8s cubic-bezier(.2,1.3,.4,1).
  static final FigureMotion jump = FigureMotion(
    seconds: 0.8,
    dy: Keyframes(<Stop>[
      (0.30, -0.24),
      (0.58, 0),
      (0.78, -0.05),
    ], curve: AppDepth.bouncy),
    scaleX: Keyframes(
      <Stop>[(0.30, 0.95), (0.58, 1.08), (0.78, 1)],
      curve: AppDepth.bouncy,
      rest: 1,
    ),
    scaleY: Keyframes(
      <Stop>[(0.30, 1.07), (0.58, 0.92), (0.78, 1)],
      curve: AppDepth.bouncy,
      rest: 1,
    ),
  );

  /// mwHop .6s cubic-bezier(.2,1.3,.4,1).
  static final FigureMotion hop = FigureMotion(
    seconds: 0.6,
    dy: Keyframes(<Stop>[(0.40, -0.10), (0.70, 0)], curve: AppDepth.bouncy),
    scaleX: Keyframes(
      <Stop>[(0.40, 0.97), (0.70, 1.04)],
      curve: AppDepth.bouncy,
      rest: 1,
    ),
    scaleY: Keyframes(
      <Stop>[(0.40, 1.04), (0.70, 0.96)],
      curve: AppDepth.bouncy,
      rest: 1,
    ),
  );

  /// mwShake .5s ease-in-out.
  static final FigureMotion shake = FigureMotion(
    seconds: 0.5,
    rotate: Keyframes(<Stop>[
      (0.2, -7),
      (0.4, 6),
      (0.6, -4),
      (0.8, 2),
    ], curve: Curves.easeInOut),
  );

  /// mwNodOnce .6s ease-in-out.
  static final FigureMotion nod = FigureMotion(
    seconds: 0.6,
    rotate: Keyframes(<Stop>[(0.4, -3)], curve: Curves.easeInOut),
    dy: Keyframes(<Stop>[(0.4, 0.03)], curve: Curves.easeInOut),
  );

  /// mwDance 1s ease-in-out, twice.
  static final FigureMotion dance = FigureMotion(
    seconds: 1,
    repeat: 2,
    rotate: Keyframes(<Stop>[
      (0.25, -9),
      (0.5, 0),
      (0.75, 9),
    ], curve: Curves.easeInOut),
    dy: Keyframes(<Stop>[
      (0.25, -0.08),
      (0.5, 0),
      (0.75, -0.08),
    ], curve: Curves.easeInOut),
  );

  /// mwSpin .9s ease-in-out (a flip).
  static final FigureMotion spin = FigureMotion(
    seconds: 0.9,
    scaleX: Keyframes(<Stop>[(0.5, -1)], curve: Curves.easeInOut, rest: 1),
    dy: Keyframes(<Stop>[(0.5, -0.06)], curve: Curves.easeInOut),
  );

  /// mwWave 1.2s ease-in-out on the right paw. dy here is the lift (0..1),
  /// rotate the paw angle.
  static final FigureMotion wave = FigureMotion(
    seconds: 1.2,
    movesPaw: true,
    dy: Keyframes(<Stop>[
      (0.2, 1),
      (0.4, 1),
      (0.6, 1),
      (0.8, 1),
    ], curve: Curves.easeInOut),
    rotate: Keyframes(<Stop>[
      (0.2, -24),
      (0.4, -6),
      (0.6, -24),
      (0.8, -6),
    ], curve: Curves.easeInOut),
  );
}

/// The endless loops (mimi-world.css), as functions of time in seconds.
abstract final class AmbientMotion {
  /// mwTilt 7s: still until 70%, -5° at 78%, 3° at 88%.
  static final Keyframes tilt = Keyframes(<Stop>[
    (0.70, 0),
    (0.78, -5),
    (0.88, 3),
  ], curve: Curves.easeInOut);

  /// mwBlink 5.2s: shut briefly at 96%.
  static final Keyframes blink = Keyframes(
    <Stop>[(0.93, 1), (0.96, 0.08)],
    curve: Curves.linear,
    rest: 1,
  );

  /// Ear twitch .5s (mwTwL; mwTwR is mirrored).
  static final Keyframes earTwitch = Keyframes(<Stop>[
    (0.3, -22),
    (0.6, 8),
  ], curve: Curves.easeInOut);
}
