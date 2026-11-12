import 'package:auditor_monkey/core/logging/app_logger.dart';
import 'package:auditor_monkey/core/logging/log_level.dart';
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/core/logging/log_redactor.dart';
import 'package:auditor_monkey/core/logging/log_sink.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySink implements LogSink {
  final List<LogRecord> records = <LogRecord>[];

  @override
  void write(LogRecord record) => records.add(record);
}

class _BrokenSink implements LogSink {
  @override
  void write(LogRecord record) => throw StateError('sink failed');
}

void main() {
  group('AppLogger', () {
    test('sends all four levels to the sink in debug builds', () {
      final _MemorySink sink = _MemorySink();
      AppLogger(sinks: <LogSink>[sink], isRelease: false)
        ..debug('t', 'd')
        ..info('t', 'i')
        ..warning('t', 'w')
        ..error('t', 'e');
      expect(sink.records.map((LogRecord r) => r.level), <LogLevel>[
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
      expect(sink.records.first.tag, 't');
      expect(sink.records.first.message, 'd');
    });

    test('drops debug logs in release builds, keeps the rest', () {
      final _MemorySink sink = _MemorySink();
      AppLogger(sinks: <LogSink>[sink], isRelease: true)
        ..debug('t', 'd')
        ..info('t', 'i')
        ..warning('t', 'w')
        ..error('t', 'e');
      expect(sink.records.map((LogRecord r) => r.level), <LogLevel>[
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
    });

    test('redacts amounts, emails and long numbers in messages', () {
      final _MemorySink sink = _MemorySink();
      AppLogger(
        sinks: <LogSink>[sink],
        isRelease: false,
      ).info('t', 'paid ₹1,23,456.00 by a@b.com card 4111 1111 1111 1111');
      final String message = sink.records.single.message;
      expect(message, isNot(contains('1,23,456')));
      expect(message, isNot(contains('a@b.com')));
      expect(message, isNot(contains('4111')));
      expect(message, contains('[amount]'));
    });

    test('redacts error text and keeps the stack trace', () {
      final _MemorySink sink = _MemorySink();
      final StackTrace stack = StackTrace.current;
      AppLogger(sinks: <LogSink>[sink], isRelease: false).error(
        't',
        'failed',
        error: Exception('user me@x.com owes Rs. 500'),
        stackTrace: stack,
      );
      final LogRecord r = sink.records.single;
      expect(r.error, isNot(contains('me@x.com')));
      expect(r.error, isNot(contains('500')));
      expect(r.stackTrace, stack);
    });

    test('a failing sink does not stop other sinks or throw', () {
      final _MemorySink sink = _MemorySink();
      final AppLogger logger = AppLogger(
        sinks: <LogSink>[_BrokenSink(), sink],
        isRelease: false,
      );
      expect(() => logger.info('t', 'hello'), returnsNormally);
      expect(sink.records, hasLength(1));
    });

    test('sinks can be added and removed (crash reporting hook)', () {
      final _MemorySink sink = _MemorySink();
      final AppLogger logger = AppLogger(sinks: <LogSink>[], isRelease: false)
        ..addSink(sink)
        ..info('t', 'one');
      expect(logger.removeSink(sink), isTrue);
      logger.info('t', 'two');
      expect(sink.records.map((LogRecord r) => r.message), <String>['one']);
    });

    test('default sink works without throwing', () {
      expect(
        () => AppLogger(isRelease: false).info('t', 'default sink'),
        returnsNormally,
      );
    });
  });

  group('LogRedactor', () {
    test('leaves normal text alone', () {
      expect(LogRedactor.clean('tab changed to home'), 'tab changed to home');
    });

    test('masks rupee forms', () {
      expect(LogRedactor.clean('₹500'), '[amount]');
      expect(LogRedactor.clean('INR 1,000.50'), '[amount]');
      expect(LogRedactor.clean('Rs 20'), '[amount]');
    });

    test('masks phone-like numbers', () {
      expect(LogRedactor.clean('call 9876543210'), 'call [number]');
    });
  });
}
