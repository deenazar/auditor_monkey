import 'dart:ui' show Color, lerpDouble;

import '../scene/sky_phase.dart';

/// Colours of one sky phase (mimi-world.css `.stage.sky-*`). With
/// app_colors.dart, the only other file allowed to hold hex values.
class SkyColors {
  const SkyColors({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.orb,
    required this.orbGlow,
    required this.hillBack,
    required this.hillFront,
    required this.cloudOpacity,
    required this.starOpacity,
    required this.glassPanel,
  });

  /// Gradient stops at 0%, 55% and 100%.
  final Color top;
  final Color middle;
  final Color bottom;

  /// Sun (or moon) and its glow.
  final Color orb;
  final Color orbGlow;

  /// `--hill1` (left, back) and `--hill2` (right, front).
  final Color hillBack;
  final Color hillFront;

  /// `--cloud`.
  final double cloudOpacity;

  /// 1 at night, else 0.
  final double starOpacity;

  /// Week-bar glass fill (white 26%, or 12% at night).
  final Color glassPanel;

  static const SkyColors dawn = SkyColors(
    top: Color(0xFF6E7CF0),
    middle: Color(0xFFE9A3B8),
    bottom: Color(0xFFFFD2AE),
    orb: Color(0xFFFFD27A),
    orbGlow: Color(0x99FFBE78),
    hillBack: Color(0xFFA8C99A),
    hillFront: Color(0xFF86B282),
    cloudOpacity: 0.8,
    starOpacity: 0,
    glassPanel: Color(0x42FFFFFF),
  );

  static const SkyColors day = SkyColors(
    top: Color(0xFF5AA9F5),
    middle: Color(0xFF9ED1FF),
    bottom: Color(0xFFDDF1FF),
    orb: Color(0xFFFFE07A),
    orbGlow: Color(0xA6FFD666),
    hillBack: Color(0xFF9BDDA8),
    hillFront: Color(0xFF74C98F),
    cloudOpacity: 0.92,
    starOpacity: 0,
    glassPanel: Color(0x42FFFFFF),
  );

  static const SkyColors dusk = SkyColors(
    top: Color(0xFF3F4AA6),
    middle: Color(0xFFB46BAE),
    bottom: Color(0xFFFF9C78),
    orb: Color(0xFFFFB27A),
    orbGlow: Color(0x8CFF966E),
    hillBack: Color(0xFF7E8FB8),
    hillFront: Color(0xFF62739E),
    cloudOpacity: 0.55,
    starOpacity: 0,
    glassPanel: Color(0x42FFFFFF),
  );

  static const SkyColors night = SkyColors(
    top: Color(0xFF0F1534),
    middle: Color(0xFF222D63),
    bottom: Color(0xFF36437F),
    orb: Color(0xFFF3F0E2),
    orbGlow: Color(0x59DCE6FF),
    hillBack: Color(0xFF2C3A6B),
    hillFront: Color(0xFF22305B),
    cloudOpacity: 0.18,
    starOpacity: 1,
    glassPanel: Color(0x1FFFFFFF),
  );

  /// The moon's shaded crescent (night only).
  static const Color moonShade = Color(0xFFD9D3BD);

  /// Clouds, stars and bar fills.
  static const Color white = Color(0xFFFFFFFF);

  /// Shadow under the monkey: rgba(10,20,40,.2).
  static const Color groundShadow = Color(0x330A1428);

  static SkyColors of(SkyPhase phase) => switch (phase) {
    SkyPhase.dawn => dawn,
    SkyPhase.day => day,
    SkyPhase.dusk => dusk,
    SkyPhase.night => night,
  };

  /// Blends two skies (the 1.2 s phase change).
  static SkyColors lerp(SkyColors a, SkyColors b, double t) => SkyColors(
    top: Color.lerp(a.top, b.top, t)!,
    middle: Color.lerp(a.middle, b.middle, t)!,
    bottom: Color.lerp(a.bottom, b.bottom, t)!,
    orb: Color.lerp(a.orb, b.orb, t)!,
    orbGlow: Color.lerp(a.orbGlow, b.orbGlow, t)!,
    hillBack: Color.lerp(a.hillBack, b.hillBack, t)!,
    hillFront: Color.lerp(a.hillFront, b.hillFront, t)!,
    cloudOpacity: lerpDouble(a.cloudOpacity, b.cloudOpacity, t)!,
    starOpacity: lerpDouble(a.starOpacity, b.starOpacity, t)!,
    glassPanel: Color.lerp(a.glassPanel, b.glassPanel, t)!,
  );
}
