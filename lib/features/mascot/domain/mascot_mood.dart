/// The monkey's base mood, set by the screen that shows it.
enum MascotMood {
  /// Calm: open eyes, small smile.
  idle,

  /// Under budget: big grin, rosy cheeks.
  happy,

  /// Over budget: raised brows, wobbly mouth, a sweat drop.
  worried,

  /// A one-off celebration: dances once, happy eyes.
  celebrating,

  /// Night and nothing happening: eyes shut, nodding, "zzz".
  sleeping,
}

/// One-shot reactions (mimi-world.js `react(kind)`).
enum MascotReaction {
  /// An entry was added: hop, happy.
  add,

  /// An entry was deleted: head shake.
  del,

  /// A goal reached: two dances and a star burst.
  win,

  /// Something went wrong / over budget: nod, worried.
  sad,

  /// Hello: waves a paw.
  hello,

  /// A spin.
  spin,

  /// A happy jump.
  check,
}
