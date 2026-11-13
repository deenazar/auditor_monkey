import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'connection/open_connection.dart';

/// Where database files live. Tests override it with a temp folder.
final Provider<DatabaseDirectory?> databaseDirectoryProvider =
    Provider<DatabaseDirectory?>((Ref ref) => null);

/// Remembers open and closing databases, so a demo file is never deleted
/// while it is open.
class DatabaseCloseTracker {
  final List<({AppDatabase db, bool demo})> _open =
      <({AppDatabase db, bool demo})>[];
  final List<Future<void>> _closing = <Future<void>>[];

  /// A database was opened ([demo] = the demo file).
  void opened(AppDatabase db, {required bool demo}) =>
      _open.add((db: db, demo: demo));

  /// The provider dropped [db]: close it and remember the close.
  void dropped(AppDatabase db) {
    _open.removeWhere((e) => identical(e.db, db));
    _closing.add(db.close());
  }

  /// Closes every demo database that is still open and waits for all
  /// closes started so far.
  Future<void> closeDemoAndWait() async {
    for (final e in _open.where((e) => e.demo)) {
      _closing.add(e.db.close());
    }
    final List<Future<void>> all = List<Future<void>>.of(_closing);
    _closing.clear();
    await Future.wait(all);
  }
}

final Provider<DatabaseCloseTracker> databaseCloseTrackerProvider =
    Provider<DatabaseCloseTracker>((Ref ref) => DatabaseCloseTracker());
