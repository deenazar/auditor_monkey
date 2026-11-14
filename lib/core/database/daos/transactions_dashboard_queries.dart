import 'package:drift/drift.dart';

import 'loan_filter.dart';
import 'transactions_dao.dart';

/// Spending per day between two dates (`?1`, `?2`), only days with spending.
/// Same rules as every spending sum (live, expense only, no loan money), and
/// `ix_tx_date` drives the range.
final String dashboardDaySpendSql =
    'SELECT date, SUM(amount) AS total FROM transactions '
    "WHERE type = 'expense' AND ${notLoanMoneySql()} AND deleted_at IS NULL "
    'AND date >= ?1 AND date <= ?2 GROUP BY date';

/// Sum of the live budgets of one month (`?1`).
const String dashboardBudgetTotalSql =
    'SELECT COALESCE(SUM(amount), 0) AS total FROM budgets '
    'WHERE month = ?1 AND deleted_at IS NULL';

/// One day with spending, raw from SQL.
class DaySpendRow {
  const DaySpendRow({required this.date, required this.total});

  final String date;
  final int total;
}

/// Dashboard-only queries (kept out of `transactions_dao.dart`: file size).
/// Month sums, top categories and the recent page reuse the DAO methods
/// `totalFor`, `expenseByCategory` and `page`.
extension DashboardQueries on TransactionsDao {
  /// Spending per day in the range; days without spending are not returned.
  Selectable<DaySpendRow> dashboardDaySpend(String from, String to) =>
      customSelect(
        dashboardDaySpendSql,
        variables: <Variable<Object>>[
          Variable<String>(from),
          Variable<String>(to),
        ],
        readsFrom: <TableInfo<Table, Object?>>{transactions},
      ).map(
        (QueryRow r) => DaySpendRow(
          date: r.read<String>('date'),
          total: r.read<int>('total'),
        ),
      );

  /// Sum of live budget amounts for [month] (`YYYY-MM`), paise.
  Selectable<int> dashboardBudgetTotal(String month) => customSelect(
    dashboardBudgetTotalSql,
    variables: <Variable<Object>>[Variable<String>(month)],
    readsFrom: <TableInfo<Table, Object?>>{attachedDatabase.budgets},
  ).map((QueryRow r) => r.read<int>('total'));

  /// Emits when transactions, accounts, categories or budgets change. The
  /// value is only a signal to reload.
  Stream<int> watchDashboardSignal() => customSelect(
    'SELECT 1 AS tick',
    readsFrom: <TableInfo<Table, Object?>>{
      transactions,
      attachedDatabase.accounts,
      attachedDatabase.categories,
      attachedDatabase.budgets,
    },
  ).watch().map((List<QueryRow> rows) => rows.length);
}
