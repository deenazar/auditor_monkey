import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../logging/app_logger.dart';
import '../utils/clock.dart';
import '../utils/id_generator.dart';
import '../utils/validation_failure.dart';
import 'app_database.dart';

/// First 8 characters of an id, for logs. (A full UUID would be masked by the
/// log cleaner, and a short id is enough to follow one row.)
String shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

const int _sqliteConstraintUnique = 2067;
const int _sqliteConstraintPrimaryKey = 1555;

/// Turns any database error into a [DataFailure]. Never include the error
/// text in a message: it can contain the statement and values.
DataFailure mapDatabaseError(Object error, {String? duplicateMessage}) {
  if (error is DataFailure) return error;
  if (error is DriftWrappedException) {
    return mapDatabaseError(
      error.cause ?? const StorageFailure(),
      duplicateMessage: duplicateMessage,
    );
  }
  if (error is DriftRemoteException) {
    return mapDatabaseError(
      error.remoteCause,
      duplicateMessage: duplicateMessage,
    );
  }
  if (error is SqliteException) {
    if (error.message.contains('integer overflow')) {
      return const OverflowFailure();
    }
    final int code = error.extendedResultCode;
    if (code == _sqliteConstraintUnique ||
        code == _sqliteConstraintPrimaryKey) {
      return DuplicateFailure(duplicateMessage ?? 'This item already exists.');
    }
  }
  return const StorageFailure();
}

/// Safe text for logs: the error type and, for SQLite, its numeric code.
String describeErrorForLog(Object error) {
  if (error is DriftWrappedException) {
    return describeErrorForLog(error.cause ?? error);
  }
  if (error is DriftRemoteException) {
    return describeErrorForLog(error.remoteCause);
  }
  if (error is SqliteException) {
    return 'SqliteException(code ${error.extendedResultCode})';
  }
  return error.runtimeType.toString();
}

/// Everything a repository needs, plus the shared "run safely" wrapper.
class RepositoryContext {
  const RepositoryContext({
    required this.db,
    required this.clock,
    required this.ids,
    required this.logger,
  });

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AppLogger logger;

  /// Runs [body]. Logs the operation (name, short id and optional safe
  /// [detailOf] text only, never values),
  /// and turns every error into a [DataFailure].
  Future<T> run<T>(
    String tag,
    String op,
    Future<T> Function() body, {
    String? Function(T result)? idOf,
    String? Function(T result)? detailOf,
    String? duplicateMessage,
  }) async {
    try {
      final T result = await body();
      final String? id = idOf?.call(result);
      // [detailOf] returns safe key=value text (counts, timings), never
      // amounts or names.
      final String? detail = detailOf?.call(result);
      logger.info(
        tag,
        '$op ok${id == null ? '' : ' id=${shortId(id)}'}'
        '${detail == null ? '' : ' $detail'}',
      );
      return result;
    } on DataFailure catch (failure) {
      logger.warning(tag, '$op rejected: ${failure.code.name}');
      rethrow;
    } on Object catch (error, stackTrace) {
      final DataFailure failure = mapDatabaseError(
        error,
        duplicateMessage: duplicateMessage,
      );
      if (failure is DuplicateFailure) {
        logger.warning(tag, '$op rejected: duplicate');
      } else {
        logger.error(
          tag,
          '$op failed: ${failure.code.name}',
          error: describeErrorForLog(error),
          stackTrace: stackTrace,
        );
      }
      throw failure;
    }
  }

  /// Same error mapping for a watched query.
  Stream<T> guardStream<T>(String tag, String op, Stream<T> source) {
    return source.handleError((Object error, StackTrace stackTrace) {
      final DataFailure failure = mapDatabaseError(error);
      logger.error(
        tag,
        '$op failed: ${failure.code.name}',
        error: describeErrorForLog(error),
        stackTrace: stackTrace,
      );
      throw failure;
    });
  }
}
