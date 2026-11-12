import 'package:drift/drift.dart';

// ignore: unused_import
import 'categories.dart';
import 'sync_columns.dart';

@DataClassName('BudgetRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX ux_budgets_category_month ON budgets '
  '(category_id, month) WHERE deleted_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX ix_budgets_pending ON budgets (sync_status) '
  "WHERE sync_status = 'pending'",
)
class Budgets extends Table with SyncColumns {
  TextColumn get categoryId => text()();
  TextColumn get month => text()();
  IntColumn get amount => integer()();

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (length(month) = 7 AND date(month || '-01') IS month || '-01')",
    "CHECK (typeof(amount) = 'integer' AND amount > 0 "
        'AND amount <= 100000000000000)',
    'FOREIGN KEY (category_id) REFERENCES categories (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
  ];
}
