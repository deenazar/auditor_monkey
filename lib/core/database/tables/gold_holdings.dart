import 'package:drift/drift.dart';

// ignore: unused_import
import 'accounts.dart';
import 'sync_columns.dart';

@DataClassName('GoldHoldingRow')
@TableIndex.sql(
  'CREATE INDEX ix_gold_holdings_pending ON gold_holdings (sync_status) '
  "WHERE sync_status = 'pending'",
)
class GoldHoldings extends Table with SyncColumns {
  TextColumn get description => text()();
  IntColumn get weightMg => integer()();
  TextColumn get purity => text()();
  TextColumn get purchaseDate => text()();
  IntColumn get purchasePrice => integer()();
  TextColumn get accountId => text().nullable()();

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (length(trim(description)) BETWEEN 1 AND 80)',
    "CHECK (typeof(weight_mg) = 'integer' AND weight_mg > 0 "
        'AND weight_mg <= 100000000)',
    "CHECK (purity IN ('24k', '22k', '18k'))",
    'CHECK (length(purchase_date) = 10 '
        'AND date(purchase_date) IS purchase_date)',
    "CHECK (typeof(purchase_price) = 'integer' AND purchase_price >= 0 "
        'AND purchase_price <= 100000000000000)',
    'FOREIGN KEY (account_id) REFERENCES accounts (id) '
        'ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
  ];
}
