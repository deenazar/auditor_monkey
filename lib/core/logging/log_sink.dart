import 'dart:developer' as developer;

import 'log_record.dart';

/// Where log records go. Add a crash-reporting sink later by
/// implementing this and calling `AppLogger.addSink`.
abstract interface class LogSink {
  void write(LogRecord record);
}

/// Default sink: `dart:developer` log (shows in DevTools and the console).
class DeveloperLogSink implements LogSink {
  const DeveloperLogSink();

  @override
  void write(LogRecord record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.severity,
      name: record.tag,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
