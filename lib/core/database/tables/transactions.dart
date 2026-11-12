import 'package:drift/drift.dart';

// ignore: unused_import
import 'accounts.dart';
// ignore: unused_import
import 'categories.dart';
// ignore: unused_import
import 'loans.dart';
import 'sync_columns.dart';

/// Money moves. Amount is always positive paise; `type` sets the direction.
@DataClassName('TransactionRow')
@TableIndex.sql('CREATE INDEX ix_tx_account ON transactions (account_id)')
@TableIndex.sql('CREATE INDEX ix_tx_to_account ON transactions (to_account_id)')
@TableIndex.sql(
  'CREATE INDEX ix_tx_date ON transactions (date DESC, created_at DESC)',
)
@TableIndex.sql(
  'CREATE INDEX ix_tx_category_date ON transactions (category_id, date)',
)
@TableIndex.sql('CREATE INDEX ix_tx_loan ON transactions (loan_id)')
@TableIndex.sql(
  'CREATE INDEX ix_transactions_pending ON transactions (sync_status) '
  "WHERE sync_status = 'pending'",
)
class Transactions extends Table with SyncColumns {
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get date => text()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get loanId => text().nullable()();
  TextColumn get importSource => text().nullable()();

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (type IN ('expense', 'income', 'transfer'))",
    "CHECK (typeof(amount) = 'integer' AND amount > 0 "
        'AND amount <= 100000000000000)',
    'CHECK (length(date) = 10 AND date(date) IS date)',
    'CHECK (note IS NULL OR length(note) <= 200)',
    'CHECK (import_source IS NULL OR length(import_source) <= 120)',
    "CHECK ((type = 'transfer' AND to_account_id IS NOT NULL "
        'AND to_account_id <> account_id AND category_id IS NULL '
        'AND loan_id IS NULL) '
        "OR (type IN ('expense', 'income') AND to_account_id IS NULL "
        'AND category_id IS NOT NULL))',
    'FOREIGN KEY (account_id) REFERENCES accounts (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
    'FOREIGN KEY (to_account_id) REFERENCES accounts (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
    'FOREIGN KEY (category_id) REFERENCES categories (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
    'FOREIGN KEY (loan_id) REFERENCES loans (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
  ];
}
