import 'package:drift/drift.dart';

import 'sync_columns.dart';

@DataClassName('CategoryRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX ux_categories_kind_name ON categories '
  '(kind, name COLLATE NOCASE) WHERE deleted_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX ix_categories_pending ON categories (sync_status) '
  "WHERE sync_status = 'pending'",
)
class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get colourGroup => text()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant<int>(0))();
  BoolColumn get archived =>
      boolean().withDefault(const Constant<bool>(false))();

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (length(trim(name)) BETWEEN 1 AND 40)',
    "CHECK (kind IN ('expense', 'income'))",
    'CHECK (colour_group IN ('
        "'essentials', 'food', 'transport', 'home', 'lifestyle', 'health', "
        "'family', 'finance', 'other', 'income'))",
    'CHECK (length(icon) BETWEEN 1 AND 40)',
  ];
}
