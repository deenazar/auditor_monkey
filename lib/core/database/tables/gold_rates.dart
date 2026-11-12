import 'package:drift/drift.dart';

import 'sync_columns.dart';

@DataClassName('GoldRateRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX ux_gold_rates_date_purity ON gold_rates '
  '(date, purity) WHERE deleted_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX ix_gold_rates_pending ON gold_rates (sync_status) '
  "WHERE sync_status = 'pending'",
)
class GoldRates extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get purity => text()();
  IntColumn get ratePerGram => integer()();

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (length(date) = 10 AND date(date) IS date)',
    "CHECK (purity IN ('24k', '22k', '18k'))",
    "CHECK (typeof(rate_per_gram) = 'integer' AND rate_per_gram > 0 "
        'AND rate_per_gram <= 1000000000)',
  ];
}
