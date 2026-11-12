import 'package:drift/drift.dart';

import 'sync_columns.dart';

@DataClassName('AccountRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX ux_accounts_name ON accounts (name COLLATE NOCASE) '
  'WHERE deleted_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX ix_accounts_pending ON accounts (sync_status) '
  "WHERE sync_status = 'pending'",
)
class Accounts extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get colour => text()();
  IntColumn get openingBalance =>
      integer().withDefault(const Constant<int>(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant<int>(0))();
  BoolColumn get archived =>
      boolean().withDefault(const Constant<bool>(false))();

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (length(trim(name)) BETWEEN 1 AND 40)',
    "CHECK (type IN ('cash', 'bank', 'card', 'wallet', 'pf', 'other'))",
    'CHECK (length(colour) BETWEEN 1 AND 32)',
    "CHECK (typeof(opening_balance) = 'integer' AND opening_balance BETWEEN "
        '-100000000000000 AND 100000000000000)',
  ];
}
