import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/transactions_dao.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../categories/domain/category.dart';
import '../domain/statement_line.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_validator.dart';

const String _tag = 'transactions';

/// Biggest page the list may ask for.
const int maxPageSize = 500;

/// Longest month range the account chart may ask for.
const int maxChartMonths = 36;

/// Statement lines the live reload re-reads at most (10 pages of 500).
const int maxStatementReload = 5000;

extension TransactionRowMapper on TransactionRow {
  TransactionEntry toDomain() => TransactionEntry(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    type: TransactionType.values.byName(type),
    amount: amount,
    date: date,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    note: note,
    loanId: loanId,
    importSource: importSource,
  );
}

/// All transaction reads and writes, plus the spending sums.
///
/// Sums leave out transfers (only one type is summed) and loan-linked rows.
class TransactionsRepository {
  const TransactionsRepository(this._ctx);

  final RepositoryContext _ctx;

  TransactionsDao get _dao => _ctx.db.transactionsDao;

  Future<TransactionEntry> create(TransactionDraft draft) =>
      _ctx.run(_tag, 'create', () async {
        final TransactionDraft d = validateTransactionDraft(draft);
        final int now = _ctx.clock.nowMs();
        final String id = _ctx.ids.newId();
        await _ctx.db.transaction(() async {
          await _checkReferences(d);
          await _dao.insertRow(
            TransactionsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              type: d.type.name,
              amount: d.amount,
              date: d.date,
              accountId: d.accountId,
              toAccountId: Value<String?>(d.toAccountId),
              categoryId: Value<String?>(d.categoryId),
              note: Value<String?>(d.note),
              loanId: Value<String?>(d.loanId),
              importSource: Value<String?>(d.importSource),
            ),
          );
        });
        return (await _dao.findById(id))!.toDomain();
      }, idOf: (TransactionEntry t) => t.id);

  Future<TransactionEntry> update(String id, TransactionDraft draft) =>
      _ctx.run(_tag, 'update', () async {
        final TransactionDraft d = validateTransactionDraft(draft);
        await _ctx.db.transaction(() async {
          final TransactionRow? existing = await _dao.findById(id);
          if (existing == null) throw const NotFoundFailure();
          // Keeping the same (closed) loan is fine; a new link is not.
          await _checkReferences(d, keepLoanId: existing.loanId);
          await _dao.updateRow(
            id,
            TransactionsCompanion(
              type: Value<String>(d.type.name),
              amount: Value<int>(d.amount),
              date: Value<String>(d.date),
              accountId: Value<String>(d.accountId),
              toAccountId: Value<String?>(d.toAccountId),
              categoryId: Value<String?>(d.categoryId),
              note: Value<String?>(d.note),
              loanId: Value<String?>(d.loanId),
              importSource: Value<String?>(d.importSource),
              updatedAt: Value<int>(
                updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
              ),
              syncStatus: const Value<String>('pending'),
            ),
          );
        });
        return (await _dao.findById(id))!.toDomain();
      }, idOf: (_) => id);

  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    await _ctx.db.transaction(() async {
      if (await _dao.findById(id) == null) throw const NotFoundFailure();
      await _dao.softDelete(id, _ctx.clock.nowMs());
    });
  }, idOf: (_) => id);

  /// Restores a deleted entry, if everything it points to is still live.
  Future<TransactionEntry> restore(String id) =>
      _ctx.run(_tag, 'restore', () async {
        await _ctx.db.transaction(() async {
          final TransactionRow? existing = await _dao.findById(
            id,
            includeDeleted: true,
          );
          if (existing == null) throw const NotFoundFailure();
          final TransactionEntry t = existing.toDomain();
          await _checkReferences(
            TransactionDraft(
              type: t.type,
              amount: t.amount,
              date: t.date,
              accountId: t.accountId,
              toAccountId: t.toAccountId,
              categoryId: t.categoryId,
              loanId: t.loanId,
            ),
          );
          await _dao.restore(id, _ctx.clock.nowMs());
        });
        return (await _dao.findById(id))!.toDomain();
      }, idOf: (_) => id);

  Future<TransactionEntry?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final TransactionRow? row = await _dao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// One page of live entries, newest first. Pass [after] (built from the
  /// last entry of the previous page) to get the next page.
  Future<List<TransactionEntry>> page({
    int limit = 50,
    TransactionCursor? after,
  }) => _ctx.run(_tag, 'page', () async {
    ensure(
      limit >= 1 && limit <= maxPageSize,
      'limit',
      FailureCode.outOfRange,
      'Page size is not allowed.',
    );
    final List<TransactionRow> rows = await _dao
        .page(
          limit: limit,
          afterDate: after?.date,
          afterCreatedAt: after?.createdAt,
          afterId: after?.id,
        )
        .get();
    return rows.map((TransactionRow r) => r.toDomain()).toList(growable: false);
  });

  /// One page of an account statement, newest first, with the running
  /// balance after every line. Transfers count on both accounts; deleted
  /// entries are left out. Pass [after] (the cursor of the previous page's
  /// last line) for the next page. A malformed or unknown id gives
  /// [NotFoundFailure]; a balance too large gives [OverflowFailure].
  Future<StatementPage> statementPage(
    String accountId, {
    int limit = 50,
    TransactionCursor? after,
  }) => _ctx.run(_tag, 'statementPage', () async {
    ensure(
      limit >= 1 && limit <= maxPageSize,
      'limit',
      FailureCode.outOfRange,
      'Page size is not allowed.',
    );
    return _statementPage(accountId, limit, after);
  });

  /// The first [count] statement lines (at most [maxStatementReload]),
  /// read in pages. Used to refresh what the screen already loaded.
  Future<StatementPage> statementThrough(String accountId, {int count = 50}) =>
      _ctx.run(_tag, 'statementThrough', () async {
        final int wanted = count.clamp(1, maxStatementReload);
        return _ctx.db.transaction(() async {
          final List<StatementLine> lines = <StatementLine>[];
          TransactionCursor? cursor;
          bool more = true;
          while (more && lines.length < wanted) {
            final int size = (wanted - lines.length).clamp(1, maxPageSize);
            final StatementPage page = await _statementPage(
              accountId,
              size,
              cursor,
            );
            lines.addAll(page.lines);
            more = page.hasMore;
            cursor = page.nextCursor;
          }
          return StatementPage(
            lines: List<StatementLine>.unmodifiable(lines),
            hasMore: more,
          );
        });
      });

  Future<StatementPage> _statementPage(
    String accountId,
    int limit,
    TransactionCursor? after,
  ) async {
    if (!isUuidShape(accountId) ||
        await _ctx.db.accountsDao.findById(accountId) == null) {
      throw const NotFoundFailure('This account is not available.');
    }
    final List<StatementRowData> rows = await _dao
        .statementPage(
          accountId,
          limit: limit + 1,
          afterDate: after?.date,
          afterCreatedAt: after?.createdAt,
          afterId: after?.id,
        )
        .get();
    final bool hasMore = rows.length > limit;
    return StatementPage(
      lines: List<StatementLine>.unmodifiable(rows.take(limit).map(_toLine)),
      hasMore: hasMore,
    );
  }

  StatementLine _toLine(StatementRowData r) => StatementLine(
    entry: r.row.toDomain(),
    effect: r.effect,
    balanceAfter: r.balanceAfter,
    categoryName: r.categoryName,
    categoryIcon: r.categoryIcon,
    categoryColourGroup: _knownGroup(r.categoryColourGroup),
    counterpartName: r.counterpartName,
  );

  /// Known colour group name, or `other` for anything else. Null stays null.
  static String? _knownGroup(String? stored) {
    if (stored == null) return null;
    final bool known = CategoryColourGroup.values.any(
      (CategoryColourGroup g) => g.name == stored,
    );
    return known ? stored : CategoryColourGroup.other.name;
  }

  /// Emits (value is meaningless) every time transactions, accounts or
  /// categories change. Screens use it to reload what they show.
  Stream<void> watchStatementSignal() =>
      _ctx.guardStream(_tag, 'watchStatementSignal', _dao.watchChangeSignal());

  /// Income and expense of one account for each month from [fromMonth] to
  /// [toMonth] (`YYYY-MM`, both included, oldest first), kept up to date.
  /// Months without entries are 0. Transfers and loan-linked entries are
  /// left out. At most [maxChartMonths] months.
  Stream<List<MonthlyTotal>> watchMonthlyTotalsForAccount(
    String accountId, {
    required String fromMonth,
    required String toMonth,
  }) {
    final List<String> months = _checkMonths(accountId, fromMonth, toMonth);
    return _ctx.guardStream(
      _tag,
      'watchMonthlyTotals',
      _dao
          .accountMonthlySums(
            accountId,
            monthRange(fromMonth).start,
            monthRange(toMonth).end,
          )
          .watch()
          .map((List<AccountMonthSumRow> rows) => _fill(months, rows)),
    );
  }

  Future<List<MonthlyTotal>> monthlyTotalsForAccount(
    String accountId, {
    required String fromMonth,
    required String toMonth,
  }) => _ctx.run(_tag, 'monthlyTotals', () async {
    final List<String> months = _checkMonths(accountId, fromMonth, toMonth);
    final List<AccountMonthSumRow> rows = await _dao
        .accountMonthlySums(
          accountId,
          monthRange(fromMonth).start,
          monthRange(toMonth).end,
        )
        .get();
    return _fill(months, rows);
  });

  List<String> _checkMonths(String accountId, String from, String to) {
    ensure(
      isUuidShape(accountId),
      'accountId',
      FailureCode.invalidFormat,
      'That account is not available.',
    );
    validateMonth('fromMonth', from);
    validateMonth('toMonth', to);
    final List<String> months = monthsBetween(from, to);
    ensure(
      months.isNotEmpty && months.length <= maxChartMonths,
      'toMonth',
      FailureCode.outOfRange,
      'Pick between 1 and $maxChartMonths months.',
    );
    return months;
  }

  List<MonthlyTotal> _fill(List<String> months, List<AccountMonthSumRow> rows) {
    final Map<String, int> income = <String, int>{};
    final Map<String, int> expense = <String, int>{};
    for (final AccountMonthSumRow r in rows) {
      (r.type == 'income' ? income : expense)[r.month] = r.total;
    }
    return List<MonthlyTotal>.unmodifiable(
      months.map(
        (String m) => MonthlyTotal(
          month: m,
          income: income[m] ?? 0,
          expense: expense[m] ?? 0,
        ),
      ),
    );
  }

  // Sums. `from` and `to` are inclusive `YYYY-MM-DD` dates.

  Future<int> expenseTotal({required String from, required String to}) =>
      _total('expenseTotal', TransactionType.expense, from, to);

  Future<int> incomeTotal({required String from, required String to}) =>
      _total('incomeTotal', TransactionType.income, from, to);

  Stream<int> watchExpenseTotal({required String from, required String to}) {
    _checkRange(from, to);
    return _ctx.guardStream(
      _tag,
      'watchExpenseTotal',
      _dao.totalFor('expense', from, to).watchSingle(),
    );
  }

  Stream<int> watchIncomeTotal({required String from, required String to}) {
    _checkRange(from, to);
    return _ctx.guardStream(
      _tag,
      'watchIncomeTotal',
      _dao.totalFor('income', from, to).watchSingle(),
    );
  }

  /// Spending per category, biggest first (for budgets and top categories).
  Future<List<CategoryTotal>> expenseByCategory({
    required String from,
    required String to,
    int? limit,
  }) => _ctx.run(_tag, 'expenseByCategory', () async {
    _checkRange(from, to);
    final List<CategorySumRow> rows = await _dao
        .expenseByCategory(from, to, limit: limit)
        .get();
    return _toTotals(rows);
  });

  Stream<List<CategoryTotal>> watchExpenseByCategory({
    required String from,
    required String to,
    int? limit,
  }) {
    _checkRange(from, to);
    return _ctx.guardStream(
      _tag,
      'watchExpenseByCategory',
      _dao.expenseByCategory(from, to, limit: limit).watch().map(_toTotals),
    );
  }

  List<CategoryTotal> _toTotals(List<CategorySumRow> rows) => rows
      .map(
        (CategorySumRow r) =>
            CategoryTotal(categoryId: r.categoryId, total: r.total),
      )
      .toList(growable: false);

  Future<int> _total(String op, TransactionType type, String from, String to) =>
      _ctx.run(_tag, op, () async {
        _checkRange(from, to);
        return _dao.totalFor(type.name, from, to).getSingle();
      });

  void _checkRange(String from, String to) {
    validateDate('from', from);
    validateDate('to', to);
    ensure(
      from.compareTo(to) <= 0,
      'to',
      FailureCode.rule,
      'End date cannot be before the start date.',
    );
  }

  /// Everything the entry points to must exist and be live, and the
  /// category kind must match the type.
  ///
  /// A loan link needs an open loan, unless it is the loan the entry
  /// already had ([keepLoanId]).
  Future<void> _checkReferences(
    TransactionDraft d, {
    String? keepLoanId,
  }) async {
    await _requireAccount('accountId', d.accountId);
    if (d.toAccountId != null) {
      await _requireAccount('toAccountId', d.toAccountId!);
    }
    final String? categoryId = d.categoryId;
    if (categoryId != null) {
      final CategoryRow? category = await _ctx.db.categoriesDao.findById(
        categoryId,
      );
      if (category == null) {
        throw const ValidationFailure(
          'categoryId',
          FailureCode.referenceMissing,
          'That category is not available.',
        );
      }
      if (category.kind != d.type.name) {
        throw const ValidationFailure(
          'categoryId',
          FailureCode.kindMismatch,
          'The category does not match the entry type.',
        );
      }
    }
    final String? loanId = d.loanId;
    if (loanId != null) {
      final LoanRow? loan = await _ctx.db.loansDao.findById(loanId);
      if (loan == null) {
        throw const ValidationFailure(
          'loanId',
          FailureCode.referenceMissing,
          'That loan is not available.',
        );
      }
      if (loan.closed && loanId != keepLoanId) {
        throw const ValidationFailure(
          'loanId',
          FailureCode.rule,
          'That loan is closed. Reopen it to add entries.',
        );
      }
    }
  }

  Future<void> _requireAccount(String field, String id) async {
    if (await _ctx.db.accountsDao.findById(id) == null) {
      throw ValidationFailure(
        field,
        FailureCode.referenceMissing,
        'That account is not available.',
      );
    }
  }
}
