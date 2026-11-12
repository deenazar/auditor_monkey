// Schema tests built on the dumped schema in drift_schemas/app/.
//
// `drift_dev make-migrations` only writes tests once there are two schema
// versions, so this file was written by hand in session 2. When schema v2 is
// added, follow docs/DATABASE.md; `make-migrations` will then generate its own
// version of this test.
import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('app schema v1 matches the dumped v1 schema', () async {
    final InitializedSchema schema = await verifier.schemaAt(1);
    final AppDatabase db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('a freshly created database matches the dumped v1 schema', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    await db.validateDatabaseSchema();
    await db.close();
  });
}
