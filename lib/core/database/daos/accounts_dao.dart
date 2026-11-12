import 'package:drift/drift.dart';

import '../../utils/validation_failure.dart';
import '../app_database.dart';
import '../row_ops.dart';
import '../tables/accounts.dart';
import '../tables/gold_holdings.dart';
import '../tables/transactions.dart';

part 'accounts_dao.g.dart';

/// One live account row with its calculated balance (paise).
class BalanceRow {
  const BalanceRow({required this.row, required this.balance});

  final AccountRow row;
  final int balance;
}

/// Balance rule, in one SQL query (live rows only):
/// opening + income - expense - transfers out + transfers in.
///
/// `SUM` (not `TOTAL`) is used on purpose: SQLite raises "integer overflow"
/// instead of silently switching to a float. The `+` between the parts can
/// still turn a result into a float on overflow, so `typeof` is returned
/// too and checked in Dart.
const String balancesSql = '''
SELECT a.*,
  a.opening_balance
  + (SELECT COALESCE(SUM(CASE t.type WHEN 'income' THEN t.amount
                                     ELSE -t.amount END), 0)
       FROM transactions t
      WHERE t.account_id = a.id AND t.deleted_at IS NULL)
  + (SELECT COALESCE(SUM(t.amount), 0)
       FROM transactions t
      WHERE t.to_account_id = a.id AND t.deleted_at IS NULL) AS balance,
  typeof(
    a.opening_balance
    + (SELECT COALESCE(SUM(CASE t.type WHEN 'income' THEN t.amount
                                       ELSE -t.amount END), 0)
         FROM transactions t
        WHERE t.account_id = a.id AND t.deleted_at IS NULL)
    + (SELECT COALESCE(SUM(t.amount), 0)
         FROM transactions t
        WHERE t.to_account_id = a.id AND t.deleted_at IS NULL)) AS balance_type
FROM accounts a
WHERE a.deleted_at IS NULL
ORDER BY a.sort_order, a.name COLLATE NOCASE, a.id
''';

@DriftAccessor(tables: <Type>[Accounts, Transactions, GoldHoldings])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.attachedDatabase);

  Future<void> insertRow(AccountsCompanion row) => into(accounts).insert(row);

  /// Updates a live row. Returns the number of rows changed.
  Future<int> updateRow(String id, AccountsCompanion changes) =>
      (update(accounts)
            ..where((Accounts t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<AccountRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$AccountsTable, AccountRow> query = select(
      accounts,
    )..where((Accounts t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((Accounts t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Stream<List<AccountRow>> watchLive() =>
      (select(accounts)
            ..where((Accounts t) => t.deletedAt.isNull())
            ..orderBy(<OrderClauseGenerator<$AccountsTable>>[
              (Accounts t) => OrderingTerm.asc(t.sortOrder),
              (Accounts t) =>
                  OrderingTerm(expression: t.name.collate(Collate.noCase)),
            ]))
          .watch();

  /// True when live transactions or live gold holdings use this account.
  Future<bool> isInUse(String id) async {
    final List<QueryRow> rows = await customSelect(
      'SELECT '
      '(EXISTS (SELECT 1 FROM transactions WHERE deleted_at IS NULL '
      'AND (account_id = ?1 OR to_account_id = ?1)) '
      'OR EXISTS (SELECT 1 FROM gold_holdings WHERE deleted_at IS NULL '
      'AND account_id = ?1)) AS used',
      variables: <Variable<Object>>[Variable<String>(id)],
      readsFrom: <TableInfo<Table, Object?>>{transactions, goldHoldings},
    ).get();
    return rows.single.read<bool>('used');
  }

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, accounts, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, accounts, id, now);

  Stream<List<BalanceRow>> watchBalances() => customSelect(
    balancesSql,
    readsFrom: <TableInfo<Table, Object?>>{accounts, transactions},
  ).watch().map(_toBalanceRows);

  /// Sum of all live account balances (paise). Throws [OverflowFailure]
  /// when it does not fit.
  Stream<int> watchNetWorth() =>
      customSelect(
        'SELECT COALESCE(SUM(balance), 0) AS total, '
        "COALESCE(SUM(balance_type <> 'integer'), 0) AS bad "
        'FROM ($balancesSql)',
        readsFrom: <TableInfo<Table, Object?>>{accounts, transactions},
      ).watch().map((List<QueryRow> rows) {
        final QueryRow r = rows.single;
        if (r.read<int>('bad') != 0) throw const OverflowFailure();
        return r.read<int>('total');
      });

  Future<List<BalanceRow>> getBalances() => customSelect(
    balancesSql,
    readsFrom: <TableInfo<Table, Object?>>{accounts, transactions},
  ).get().then(_toBalanceRows);

  /// Throws [OverflowFailure] when a balance is not a whole number.
  List<BalanceRow> _toBalanceRows(List<QueryRow> rows) => rows
      .map((QueryRow r) {
        if (r.read<String>('balance_type') != 'integer') {
          throw const OverflowFailure();
        }
        return BalanceRow(
          row: accounts.map(r.data),
          balance: r.read<int>('balance'),
        );
      })
      .toList(growable: false);
}
