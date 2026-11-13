/// The mascot's mood; each maps to one animation clip in the model.
enum MascotMood {
  /// Calm loop.
  idle,

  /// Happy one-shot.
  happy,

  /// Worried loop.
  worried,

  /// Celebration one-shot.
  celebrating,

  /// Sleeping loop.
  sleeping;

  /// The clip name inside `monkey.glb` (lower-case).
  String get clipName => name;
}
