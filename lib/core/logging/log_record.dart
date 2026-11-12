import 'log_level.dart';

/// One log entry, already cleaned of personal data.
class LogRecord {
  const LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.time,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;

  /// Short area name, e.g. `app`, `nav`, `quick_add`.
  final String tag;
  final String message;
  final DateTime time;

  /// Cleaned text of the error, never the raw error object.
  final String? error;
  final StackTrace? stackTrace;
}
