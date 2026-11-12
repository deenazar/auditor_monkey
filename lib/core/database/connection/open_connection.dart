import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const String databaseFileName = 'auditor_monkey.sqlite';

/// The ONLY place the database file is opened.
///
/// Session 8 (encryption) swaps this one function to open the file with
/// SQLCipher and a key from secure storage, and converts the existing file
/// in place. No other file may open the database.
///
/// The work runs in a background isolate so queries never block the UI.
QueryExecutor openAppConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String tempPath = (await getTemporaryDirectory()).path;
    final File file = File(p.join(dir.path, databaseFileName));
    return NativeDatabase.createInBackground(
      file,
      // Never log statements: they contain amounts and notes.
      logStatements: false,
      isolateSetup: () {
        // Android needs a writable folder for SQLite temporary files.
        sqlite3.tempDirectory = tempPath;
      },
    );
  });
}
