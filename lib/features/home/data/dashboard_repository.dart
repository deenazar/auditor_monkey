import '../../../core/database/app_database.dart';
import '../../../core/database/daos/transactions_dao.dart';
import '../../../core/database/daos/transactions_dashboard_queries.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../categories/domain/category.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../domain/dashboard_summary.dart';
import '../domain/home_summary.dart';
import '../domain/top_categories.dart';

const String _tag = 'dashboard';

/// Biggest list the Dashboard may ask for.
const int maxDashboardLimit = 500;

/// Reads the Dashboard numbers. Read-only; every number comes from the same
/// SQL rules as the Transactions tab (see `notLoanMoneySql`).
class DashboardRepository {
  const DashboardRepository(this._ctx);

  final RepositoryContext _ctx;

  TransactionsDao get _dao => _ctx.db.transactionsDao;

  /// Emits (value is meaningless) when transactions, accounts, categories or
  /// budgets change.
  Stream<void> watchSignal() =>
      _ctx.guardStream(_tag, 'watchSignal', _dao.watchDashboardSignal());

  /// Reads the whole Dashboard for [today] (`YYYY-MM-DD`) in ONE read
  /// transaction, so every number comes from the same snapshot: spent,
  /// income and top categories for the whole calendar month of [today]
  /// (future dates included), the month's budget total, the last
  /// [HomeSummary.stripDays] days and the newest [recentLimit] entries.
  ///
  /// [recentLimit] and [topLimit] must be 1 to [maxDashboardLimit].
  /// Logs `load ok ms=... rows=...` (counts only, never amounts or names).
  Future<DashboardSummary> load({
    required String today,
    int recentLimit = 5,
    int topLimit = topCategoryCount,
  }) {
    final Stopwatch watch = Stopwatch()..start();
    int rowsRead = 0;
    return _ctx.run(
      _tag,
      'load',
      () async {
        validateDate('today', today);
        _checkLimit('recentLimit', recentLimit);
        _checkLimit('topLimit', topLimit);
        final String month = today.substring(0, 7);
        final String monthStart = '$month-01';
        final String monthEnd = monthLastDay(month);
        final String stripFrom = addDays(today, -(HomeSummary.stripDays - 1));
        final DashboardSummary summary = await _ctx.db.transaction(() async {
          final int spent = await _dao
              .totalFor('expense', monthStart, monthEnd)
              .getSingle();
          final int income = await _dao
              .totalFor('income', monthStart, monthEnd)
              .getSingle();
          final int budgetTotal = await _dao
              .dashboardBudgetTotal(month)
              .getSingle();
          final List<CategorySumRow> top = await _dao
              .expenseByCategory(monthStart, monthEnd, limit: topLimit)
              .get();
          final List<TransactionRow> recent = await _dao
              .page(limit: recentLimit)
              .get();
          final List<DaySpendRow> dayRows = await _dao
              .dashboardDaySpend(stripFrom, today)
              .get();
          rowsRead = top.length + recent.length + dayRows.length;
          final Map<String, int> byDay = <String, int>{
            for (final DaySpendRow r in dayRows) r.date: r.total,
          };
          return DashboardSummary(
            today: today,
            month: month,
            days: List<DaySpend>.unmodifiable(<DaySpend>[
              for (int i = HomeSummary.stripDays - 1; i >= 0; i--)
                DaySpend(
                  date: addDays(today, -i),
                  spent: byDay[addDays(today, -i)] ?? 0,
                ),
            ]),
            spent: spent,
            income: income,
            budgetTotal: budgetTotal,
            topCategories: topCategoryShares(
              top
                  .map(
                    (CategorySumRow r) =>
                        CategoryTotal(categoryId: r.categoryId, total: r.total),
                  )
                  .toList(growable: false),
              spent,
              limit: topLimit,
            ),
            recent: List<TransactionEntry>.unmodifiable(
              recent.map((TransactionRow r) => r.toDomain()),
            ),
          );
        });
        return summary;
      },
      detailOf: (DashboardSummary _) =>
          'ms=${watch.elapsedMilliseconds} rows=$rowsRead',
    );
  }

  void _checkLimit(String field, int value) => ensure(
    value >= 1 && value <= maxDashboardLimit,
    field,
    FailureCode.outOfRange,
    'Limit is not allowed.',
  );
}
