import 'dart:ui' show Offset;

/// Which eyes are drawn.
enum MonkeyEyes { open, happy, sleep }

/// Which mouth is drawn.
enum MonkeyMouth { smile, grin, sad }

/// Everything the painter needs for one frame. Mutable on purpose: the
/// widget fills one instance per frame, so 60 fps makes no garbage.
class MonkeyPose {
  // Whole figure (origin: bottom centre), in view-box units / radians.
  double figureDy = 0;
  double figureScaleX = 1;
  double figureScaleY = 1;
  double figureRotation = 0;

  /// mwBreath: body scale (1 = rest).
  double breathX = 1;
  double breathY = 1;

  /// mwTilt / mwNod: head rotation (radians) and drop.
  double headRotation = 0;
  double headDy = 0;

  /// mwSwish: tail rotation (radians).
  double tailRotation = 0;

  /// mwBlink: open-eye vertical scale (1 open, 0.08 shut).
  double blink = 1;

  /// mw-look: pupils offset (view-box units).
  Offset look = Offset.zero;

  /// Ear rotations (radians); left is negative to fold out.
  double earLeft = 0;
  double earRight = 0;

  /// mwWave: 0..1 lift of the right paw and its angle (radians).
  double waveLift = 0;
  double waveRotation = 0;

  /// mwPurr: tiny body rumble (view-box units).
  Offset purr = Offset.zero;

  MonkeyEyes eyes = MonkeyEyes.open;
  MonkeyMouth mouth = MonkeyMouth.smile;

  /// mwTalk: mouth open on top of the mood.
  bool talking = false;

  /// Worried brows and the sweat drop (0..1 fade).
  double worry = 0;

  /// Cheek blush strength (0.45 normal, up to 0.75 happy).
  double blush = 0.45;

  /// Sleep "zzz" (0..1 fade) and the time used to float them.
  double sleep = 0;
  double seconds = 0;

  /// Dizzy stars circling the head (0..1 fade).
  double dizzy = 0;

  /// Sun or moon behind the monkey and the ground shadow.
  bool halo = true;
}
