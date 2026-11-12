import 'package:flutter/foundation.dart';

import 'log_level.dart';
import 'log_record.dart';
import 'log_redactor.dart';
import 'log_sink.dart';

/// The single logging API for the app.
///
/// - Levels: debug, info, warning, error.
/// - Debug logs are dropped in release builds.
/// - Messages are cleaned by [LogRedactor]. Never pass amounts, names,
///   emails, phone numbers or tokens; log ids and counts instead.
/// - A failing sink never crashes the app.
class AppLogger {
  AppLogger({List<LogSink>? sinks, bool? isRelease})
    : _sinks = List<LogSink>.of(sinks ?? const <LogSink>[DeveloperLogSink()]),
      _isRelease = isRelease ?? kReleaseMode;

  final List<LogSink> _sinks;
  final bool _isRelease;

  /// Shared instance used by the app. Tests create their own.
  static final AppLogger instance = AppLogger();

  void addSink(LogSink sink) => _sinks.add(sink);

  bool removeSink(LogSink sink) => _sinks.remove(sink);

  void debug(String tag, String message) => _log(LogLevel.debug, tag, message);

  void info(String tag, String message) => _log(LogLevel.info, tag, message);

  void warning(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.warning,
    tag,
    message,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_isRelease && level == LogLevel.debug) return;
    final LogRecord record = LogRecord(
      level: level,
      tag: tag,
      message: LogRedactor.clean(message),
      time: DateTime.now(),
      error: error == null ? null : LogRedactor.clean(error.toString()),
      stackTrace: stackTrace,
    );
    for (final LogSink sink in List<LogSink>.of(_sinks)) {
      try {
        sink.write(record);
      } on Object {
        // Logging must never break the app.
      }
    }
  }
}
