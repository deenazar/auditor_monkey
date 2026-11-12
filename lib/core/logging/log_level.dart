/// Log levels, lowest to highest.
enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.severity);

  /// Matches the numeric levels used by `dart:developer` `log`.
  final int severity;
}
