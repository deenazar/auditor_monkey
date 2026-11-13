/// The sky's time of day (mimi-world.js `paintSky`).
enum SkyPhase {
  dawn,
  day,
  dusk,
  night;

  /// Phase for a local [hour] (0..24, fractions allowed): night before 5
  /// and from 20, dawn until 7:30, day until 17, then dusk.
  static SkyPhase forHour(double hour) {
    if (hour < 5 || hour >= 20) return SkyPhase.night;
    if (hour < 7.5) return SkyPhase.dawn;
    if (hour < 17) return SkyPhase.day;
    return SkyPhase.dusk;
  }

  /// Phase for a local [time].
  static SkyPhase at(DateTime time) => forHour(time.hour + time.minute / 60);
}

/// True in the sleepy hours (23:00 to 5:00), when an idle monkey sleeps.
bool isSleepyHour(DateTime time) => time.hour >= 23 || time.hour < 5;
