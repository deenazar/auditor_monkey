import 'package:drift/drift.dart';

import '../../../core/database/daos/transactions_dao.dart';
import '../../../core/database/daos/transactions_list_queries.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../categories/domain/category.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_filter_validator.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_repository.dart' show TransactionRowMapper;

const String _tag = 'transactions_list';

/// Most rows a reload may re-read in one go (10 pages of 500).
const int maxListReload = 5000;

/// A page of the list with the totals of the days it touches.
class ListPage {
  const ListPage({
    required this.items,
    required this.hasMore,
    required this.dayTotals,
  });

  final List<TransactionListItem> items;
  final bool hasMore;

  /// Whole-day totals (also rows outside the page) of every day in [items].
  final Map<String, DayTotal> dayTotals;
}

/// Reads for the Transactions list. Writes (edit, delete, undo) stay in
/// `TransactionsRepository`.
class TransactionsListRepository {
  const TransactionsListRepository(this._ctx);

  final RepositoryContext _ctx;

  TransactionsDao get _dao => _ctx.db.transactionsDao;

  /// [limit] rows (newest first) after [after], with day totals for the
  /// days on the page, read in one transaction so they agree.
  Future<ListPage> page(
    TransactionFilter filter, {
    int limit = 50,
    TransactionCursor? after,
  }) => _ctx.run(_tag, 'page', () async {
    ensure(
      limit >= 1 && limit <= maxListReload,
      'limit',
      FailureCode.outOfRange,
      'Page size is not allowed.',
    );
    final TransactionFilter f = validateTransactionFilter(filter);
    return _ctx.db.transaction(() => _readPage(f, limit, after));
  });

  /// Day totals for [dates] (`YYYY-MM-DD`). Every date is in the result
  /// (zero when the day has no income or expense).
  Future<Map<String, DayTotal>> dayTotals(
    TransactionFilter filter,
    Iterable<String> dates,
  ) => _ctx.run(_tag, 'dayTotals', () async {
    final TransactionFilter f = validateTransactionFilter(filter);
    final Set<String> set = dates.toSet();
    for (final String d in set) {
      validateDate('date', d);
    }
    return _readDayTotals(f, set);
  });

  /// Spent and income of [month] (`YYYY-MM`) for [filter].
  Future<MonthSummary> monthSummary(TransactionFilter filter, String month) =>
      _ctx.run(_tag, 'monthSummary', () async {
        final TransactionFilter f = validateTransactionFilter(filter);
        validateMonth('month', month);
        final MonthSumRow row = await _monthQuery(f, month).getSingle();
        return _toSummary(month, row);
      });

  /// Same as [monthSummary], kept up to date.
  Stream<MonthSummary> watchMonthSummary(
    TransactionFilter filter,
    String month,
  ) {
    final TransactionFilter f = validateTransactionFilter(filter);
    validateMonth('month', month);
    return _ctx.guardStream(
      _tag,
      'watchMonthSummary',
      _monthQuery(
        f,
        month,
      ).watchSingle().map((MonthSumRow r) => _toSummary(month, r)),
    );
  }

  /// One live entry with names; `null` when deleted or unknown.
  Future<TransactionListItem?> detail(String id) =>
      _ctx.run(_tag, 'detail', () async {
        if (!isUuidShape(id)) return null;
        final List<ListRowData> rows = await _dao.listDetail(id).get();
        return rows.isEmpty ? null : _toItem(rows.first);
      });

  /// Same as [detail], kept up to date.
  Stream<TransactionListItem?> watchDetail(String id) {
    if (!isUuidShape(id)) return Stream<TransactionListItem?>.value(null);
    return _ctx.guardStream(
      _tag,
      'watchDetail',
      _dao
          .listDetail(id)
          .watch()
          .map(
            (List<ListRowData> rows) =>
                rows.isEmpty ? null : _toItem(rows.first),
          ),
    );
  }

  /// Emits (value is meaningless) when transactions, accounts or categories
  /// change.
  Stream<void> watchChangeSignal() =>
      _ctx.guardStream(_tag, 'watchChangeSignal', _dao.watchChangeSignal());

  Future<ListPage> _readPage(
    TransactionFilter f,
    int limit,
    TransactionCursor? after,
  ) async {
    final List<ListRowData> rows = await _dao
        .listPage(
          _spec(f),
          limit: limit + 1,
          afterDate: after?.date,
          afterCreatedAt: after?.createdAt,
          afterId: after?.id,
        )
        .get();
    final bool hasMore = rows.length > limit;
    final List<TransactionListItem> items = rows
        .take(limit)
        .map(_toItem)
        .toList(growable: false);
    final Map<String, DayTotal> totals = await _readDayTotals(f, <String>{
      for (final TransactionListItem i in items) i.entry.date,
    });
    return ListPage(items: items, hasMore: hasMore, dayTotals: totals);
  }

  Future<Map<String, DayTotal>> _readDayTotals(
    TransactionFilter f,
    Set<String> dates,
  ) async {
    if (dates.isEmpty) return const <String, DayTotal>{};
    final List<String> sorted = dates.toList()..sort();
    final List<DayTotalRow> rows = await _dao
        .listDayTotals(_spec(f), sorted.first, sorted.last)
        .get();
    final Map<String, DayTotalRow> byDate = <String, DayTotalRow>{
      for (final DayTotalRow r in rows) r.date: r,
    };
    return <String, DayTotal>{
      for (final String d in sorted)
        d: DayTotal(
          date: d,
          expense: byDate[d]?.expense ?? 0,
          income: byDate[d]?.income ?? 0,
        ),
    };
  }

  Selectable<MonthSumRow> _monthQuery(TransactionFilter f, String month) {
    return _dao.listMonthSummary(_spec(f), '$month-01', '$month-31');
  }

  MonthSummary _toSummary(String month, MonthSumRow r) =>
      MonthSummary(month: month, spent: r.expense, income: r.income);

  ListFilterSpec _spec(TransactionFilter f) => ListFilterSpec(
    query: f.query,
    from: f.from,
    to: f.to,
    types: (f.types.map((TransactionType t) => t.name).toList()..sort()),
    accountIds: f.accountIds.toList()..sort(),
    categoryIds: f.categoryIds.toList()..sort(),
  );

  TransactionListItem _toItem(ListRowData r) {
    final TransactionEntry entry = r.row.toDomain();
    return TransactionListItem(
      entry: entry,
      accountName: r.accountName ?? '',
      accountColour: r.accountColour ?? '',
      toAccountName: r.toAccountName,
      toAccountColour: r.toAccountColour,
      categoryName: r.categoryName,
      categoryIcon: r.categoryIcon,
      categoryColourGroup: _knownGroup(r.categoryColourGroup),
    );
  }

  /// Known colour group name, or `other` for anything else.
  static String? _knownGroup(String? stored) {
    if (stored == null) return null;
    final bool known = CategoryColourGroup.values.any(
      (CategoryColourGroup g) => g.name == stored,
    );
    return known ? stored : CategoryColourGroup.other.name;
  }
}
