import 'package:drift/drift.dart';

import '../app_database.dart';
import '../row_ops.dart';
import '../tables/gold_holdings.dart';
import '../tables/gold_rates.dart';

part 'gold_dao.g.dart';

/// A holding row with its current value (paise); `null` without a rate.
class GoldValueRow {
  const GoldValueRow({required this.row, required this.currentValue});

  final GoldHoldingRow row;
  final int? currentValue;
}

/// Current value = (weight_mg * latest live rate per gram + 500) / 1000.
/// Whole-number maths; `+ 500` before the integer divide rounds half up.
/// Biggest possible product is 1e8 * 1e9 = 1e17, far below the 64-bit limit.
const String goldValueSql = '''
SELECT x.*,
  CASE WHEN x.latest_rate IS NULL THEN NULL
       ELSE (x.weight_mg * x.latest_rate + 500) / 1000 END AS current_value
FROM (
  SELECT h.*,
    (SELECT r.rate_per_gram FROM gold_rates r
      WHERE r.purity = h.purity AND r.deleted_at IS NULL
      ORDER BY r.date DESC LIMIT 1) AS latest_rate
  FROM gold_holdings h
  WHERE h.deleted_at IS NULL) x
ORDER BY x.purchase_date DESC, x.id
''';

@DriftAccessor(tables: <Type>[GoldHoldings, GoldRates])
class GoldDao extends DatabaseAccessor<AppDatabase> with _$GoldDaoMixin {
  GoldDao(super.attachedDatabase);

  // Holdings.

  Future<void> insertHolding(GoldHoldingsCompanion row) =>
      into(goldHoldings).insert(row);

  Future<int> updateHolding(String id, GoldHoldingsCompanion changes) =>
      (update(goldHoldings)
            ..where((GoldHoldings t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<GoldHoldingRow?> findHolding(
    String id, {
    bool includeDeleted = false,
  }) {
    final SimpleSelectStatement<$GoldHoldingsTable, GoldHoldingRow> query =
        select(goldHoldings)..where((GoldHoldings t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((GoldHoldings t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> softDeleteHolding(String id, int now) =>
      softDeleteRow(attachedDatabase, goldHoldings, id, now);

  Future<int> restoreHolding(String id, int now) =>
      restoreRow(attachedDatabase, goldHoldings, id, now);

  Selectable<GoldValueRow> holdingValues() =>
      customSelect(
        goldValueSql,
        readsFrom: <TableInfo<Table, Object?>>{goldHoldings, goldRates},
      ).map(
        (QueryRow r) => GoldValueRow(
          row: goldHoldings.map(r.data),
          currentValue: r.readNullable<int>('current_value'),
        ),
      );

  // Rates.

  Future<void> insertRate(GoldRatesCompanion row) =>
      into(goldRates).insert(row);

  Future<int> updateRate(String id, GoldRatesCompanion changes) =>
      (update(goldRates)
            ..where((GoldRates t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<GoldRateRow?> findRate(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$GoldRatesTable, GoldRateRow> query = select(
      goldRates,
    )..where((GoldRates t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((GoldRates t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> softDeleteRate(String id, int now) =>
      softDeleteRow(attachedDatabase, goldRates, id, now);

  Future<int> restoreRate(String id, int now) =>
      restoreRow(attachedDatabase, goldRates, id, now);

  Stream<List<GoldRateRow>> watchRates() =>
      (select(goldRates)
            ..where((GoldRates t) => t.deletedAt.isNull())
            ..orderBy(<OrderClauseGenerator<$GoldRatesTable>>[
              (GoldRates t) => OrderingTerm.desc(t.date),
              (GoldRates t) => OrderingTerm.asc(t.purity),
            ]))
          .watch();
}
