import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const String databaseFileName = 'auditor_monkey.sqlite';

/// Debug and profile builds only: the separate demo data file.
const String demoDatabaseFileName = 'auditor_monkey_demo.sqlite';

/// Where the database files live. Tests pass a temp folder.
typedef DatabaseDirectory = Future<Directory> Function();

/// The phone's documents folder.
Future<Directory> defaultDatabaseDirectory() =>
    getApplicationDocumentsDirectory();

/// The ONLY place the database file is opened.
///
/// Session 8 (encryption) swaps this one function to open the file with
/// SQLCipher and a key from secure storage, and converts the existing file
/// in place. No other file may open the database.
///
/// The work runs in a background isolate so queries never block the UI.
///
/// [fileName] is the real file, or [demoDatabaseFileName] in demo mode.
/// [directory] is only set by tests.
QueryExecutor openAppConnection({
  String fileName = databaseFileName,
  DatabaseDirectory? directory,
}) {
  return LazyDatabase(() async {
    final Directory dir = await (directory ?? defaultDatabaseDirectory)();
    final String tempPath = directory == null
        ? (await getTemporaryDirectory()).path
        : dir.path;
    final File file = File(p.join(dir.path, fileName));
    return NativeDatabase.createInBackground(
      file,
      // Never log statements: they contain amounts and notes.
      logStatements: false,
      isolateSetup: _isolateSetup(tempPath),
    );
  });
}

/// Built in its own function so the closure holds only [tempPath] (a string
/// can be sent to the background isolate; the caller's closures cannot).
void Function() _isolateSetup(String tempPath) {
  return () {
    // Android needs a writable folder for SQLite temporary files.
    sqlite3.tempDirectory = tempPath;
  };
}
