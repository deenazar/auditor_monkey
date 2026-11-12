// Guard: every schema version has a dump, and the code is not ahead of the
// newest dump. Fails when someone raises `schemaVersion` without running
// `dart run drift_dev make-migrations` (see docs/DATABASE.md).
import 'dart:io';

import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a schema dump exists for every version 1..schemaVersion', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final int version = db.schemaVersion;
    await db.close();

    final RegExp name = RegExp(r'^drift_schema_v(\d+)\.json$');
    final Set<int> dumps = <int>{
      for (final FileSystemEntity f in Directory(
        'drift_schemas/app',
      ).listSync().whereType<File>())
        if (name.firstMatch(f.uri.pathSegments.last) case final RegExpMatch m)
          int.parse(m.group(1)!),
    };

    expect(dumps, isNotEmpty);
    final int newest = dumps.reduce((int a, int b) => a > b ? a : b);
    expect(
      version,
      lessThanOrEqualTo(newest),
      reason: 'schemaVersion $version has no dump. Run make-migrations.',
    );
    for (int v = 1; v <= version; v++) {
      expect(dumps, contains(v), reason: 'missing drift_schema_v$v.json');
    }
    expect(newest, version, reason: 'a dump is newer than schemaVersion');
  });
}
