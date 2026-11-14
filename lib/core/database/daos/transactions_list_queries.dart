import 'package:drift/drift.dart';

import '../../money/money.dart';
import '../app_database.dart';
import 'loan_filter.dart';
import 'transactions_dao.dart';

/// Queries of the Transactions list: filtered pages with names, day totals,
/// month summary and one entry with names.
///
/// Rules (same as every other sum in the app):
/// - only live rows;
/// - sums count expense and income only (a transfer is never either);
/// - sums leave out loan money (`notLoanMoneySql`: loan-linked rows and the
///   4 loan categories; the unary plus keeps SQLite off the weak
///   `ix_tx_loan` index);
/// - every user value is a bound variable, never part of the SQL text.
///
/// No schema change: the date index (`ix_tx_date`) drives every query. The
/// joins are LEFT joins so SQLite keeps `transactions` as the outer table.

/// A filter as plain values for SQL (the domain filter is checked by the
/// repository before it gets here).
class ListFilterSpec {
  const ListFilterSpec({
    this.query = '',
    this.from,
    this.to,
    this.types = const <String>[],
    this.accountIds = const <String>[],
    this.categoryIds = const <String>[],
  });

  final String query;
  final String? from;
  final String? to;
  final List<String> types;
  final List<String> accountIds;
  final List<String> categoryIds;
}

/// WHERE parts (joined with AND) and their variables, in order.
class ListWhere {
  const ListWhere(this.sql, this.variables, {required this.usesCategory});

  /// Empty or starts with ` AND `.
  final String sql;
  final List<Variable<Object>> variables;

  /// The query reads `c.name`, so the sum queries must join categories.
  final bool usesCategory;
}

final RegExp _likeSpecials = RegExp(r'[\\%_]');

/// Escapes `\`, `%` and `_` so the text is matched literally by `LIKE ... ESCAPE '\'`.
String escapeLike(String text) =>
    text.replaceAllMapped(_likeSpecials, (Match m) => '\\${m[0]}');

/// Paise when the whole search text reads as rupees (`250`, `₹1,250.50`).
/// Commas must be valid Indian or Western grouping, and there are no spaces
/// inside the number ("1 2" and "1,2,3" are plain text, not amounts).
int? queryAsPaise(String query) => parseRupeesToPaise(query.trim());

/// The WHERE conditions of [f] on table alias `t` (and `c` for categories).
ListWhere listWhere(ListFilterSpec f) {
  final StringBuffer sql = StringBuffer();
  final List<Variable<Object>> vars = <Variable<Object>>[];
  bool usesCategory = false;

  final String q = f.query.trim();
  if (q.isNotEmpty) {
    usesCategory = true;
    final String pattern = '%${escapeLike(q)}%';
    final int? paise = queryAsPaise(q);
    sql.write(
      " AND (t.note LIKE ? ESCAPE '\\' OR c.name LIKE ? ESCAPE '\\'"
      '${paise == null ? '' : ' OR t.amount = ?'})',
    );
    vars
      ..add(Variable<String>(pattern))
      ..add(Variable<String>(pattern));
    if (paise != null) vars.add(Variable<int>(paise));
  }
  if (f.from != null) {
    sql.write(' AND t.date >= ?');
    vars.add(Variable<String>(f.from!));
  }
  if (f.to != null) {
    sql.write(' AND t.date <= ?');
    vars.add(Variable<String>(f.to!));
  }
  if (f.types.isNotEmpty) {
    sql.write(' AND t.type IN (${_marks(f.types.length)})');
    vars.addAll(f.types.map(Variable<String>.new));
  }
  if (f.accountIds.isNotEmpty) {
    final String marks = _marks(f.accountIds.length);
    sql.write(' AND (t.account_id IN ($marks) OR t.to_account_id IN ($marks))');
    vars
      ..addAll(f.accountIds.map(Variable<String>.new))
      ..addAll(f.accountIds.map(Variable<String>.new));
  }
  if (f.categoryIds.isNotEmpty) {
    sql.write(' AND t.category_id IN (${_marks(f.categoryIds.length)})');
    vars.addAll(f.categoryIds.map(Variable<String>.new));
  }
  return ListWhere(sql.toString(), vars, usesCategory: usesCategory);
}

String _marks(int n) => List<String>.filled(n, '?').join(', ');

const String _listSelect =
    'SELECT t.*, a.name AS account_name, a.colour AS account_colour, '
    'ta.name AS to_account_name, ta.colour AS to_account_colour, '
    'c.name AS category_name, c.icon AS category_icon, '
    'c.colour_group AS category_colour_group '
    'FROM transactions t '
    'LEFT JOIN accounts a ON a.id = t.account_id '
    'LEFT JOIN accounts ta ON ta.id = t.to_account_id '
    'LEFT JOIN categories c ON c.id = t.category_id ';

/// SQL of one page of the list (newest first). [where] comes from
/// [listWhere]; the cursor variables (`date, created_at, id`) and the limit
/// follow the filter variables.
String listPageSql(ListWhere where, {required bool hasCursor}) =>
    '$_listSelect'
    'WHERE t.deleted_at IS NULL${where.sql}'
    '${hasCursor ? ' AND (t.date, t.created_at, t.id) < (?, ?, ?)' : ''} '
    'ORDER BY t.date DESC, t.created_at DESC, t.id DESC LIMIT ?';

/// SQL of one entry with names (`?1` = id), live only.
const String listDetailSql =
    '${_listSelect}WHERE t.id = ?1 AND t.deleted_at IS NULL';

String _sumJoin(ListWhere w) =>
    w.usesCategory ? ' LEFT JOIN categories c ON c.id = t.category_id' : '';

final String _sumBase =
    "WHERE t.deleted_at IS NULL AND t.type IN ('expense', 'income') "
    'AND ${notLoanMoneySql('t.')}';

const String _sums =
    "COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount END), 0) "
    'AS expense, '
    "COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount END), 0) "
    'AS income';

/// Expense and income per day between two dates (the last two variables).
String dayTotalsSql(ListWhere w) =>
    'SELECT t.date AS date, $_sums FROM transactions t${_sumJoin(w)} '
    '$_sumBase${w.sql} AND t.date >= ? AND t.date <= ? GROUP BY t.date';

/// Expense and income of one month (the last two variables are its first
/// and last date).
String monthSummarySql(ListWhere w) =>
    'SELECT $_sums FROM transactions t${_sumJoin(w)} '
    '$_sumBase${w.sql} AND t.date >= ? AND t.date <= ?';

/// One list row as read from SQL.
class ListRowData {
  const ListRowData({
    required this.row,
    required this.accountName,
    required this.accountColour,
    required this.toAccountName,
    required this.toAccountColour,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColourGroup,
  });

  final TransactionRow row;
  final String? accountName;
  final String? accountColour;
  final String? toAccountName;
  final String? toAccountColour;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColourGroup;
}

/// Sums of one day, raw from SQL.
class DayTotalRow {
  const DayTotalRow({
    required this.date,
    required this.expense,
    required this.income,
  });

  final String date;
  final int expense;
  final int income;
}

/// Spent and income of a month, raw from SQL.
class MonthSumRow {
  const MonthSumRow({required this.expense, required this.income});

  final int expense;
  final int income;
}

/// Transactions list queries, kept out of `transactions_dao.dart` (size).
extension TransactionsListQueries on TransactionsDao {
  Set<TableInfo<Table, Object?>> get _listTables => <TableInfo<Table, Object?>>{
    transactions,
    attachedDatabase.accounts,
    attachedDatabase.categories,
  };

  ListRowData _toListRow(QueryRow r) => ListRowData(
    row: transactions.map(r.data),
    accountName: r.readNullable<String>('account_name'),
    accountColour: r.readNullable<String>('account_colour'),
    toAccountName: r.readNullable<String>('to_account_name'),
    toAccountColour: r.readNullable<String>('to_account_colour'),
    categoryName: r.readNullable<String>('category_name'),
    categoryIcon: r.readNullable<String>('category_icon'),
    categoryColourGroup: r.readNullable<String>('category_colour_group'),
  );

  /// Page of live rows for [filter], newest first (date, created time, id).
  /// Pass the last row of the previous page as the cursor.
  Selectable<ListRowData> listPage(
    ListFilterSpec filter, {
    required int limit,
    String? afterDate,
    int? afterCreatedAt,
    String? afterId,
  }) {
    final bool hasCursor =
        afterDate != null && afterCreatedAt != null && afterId != null;
    final ListWhere w = listWhere(filter);
    return customSelect(
      listPageSql(w, hasCursor: hasCursor),
      variables: <Variable<Object>>[
        ...w.variables,
        if (hasCursor) ...<Variable<Object>>[
          Variable<String>(afterDate),
          Variable<int>(afterCreatedAt),
          Variable<String>(afterId),
        ],
        Variable<int>(limit),
      ],
      readsFrom: _listTables,
    ).map(_toListRow);
  }

  /// One live entry with names; no row when missing or deleted.
  Selectable<ListRowData> listDetail(String id) => customSelect(
    listDetailSql,
    variables: <Variable<Object>>[Variable<String>(id)],
    readsFrom: _listTables,
  ).map(_toListRow);

  /// Expense and income per day for [filter] between two dates (inclusive).
  /// Days without income or expense are not returned.
  Selectable<DayTotalRow> listDayTotals(
    ListFilterSpec filter,
    String fromDate,
    String toDate,
  ) {
    final ListWhere w = listWhere(filter);
    return customSelect(
      dayTotalsSql(w),
      variables: <Variable<Object>>[
        ...w.variables,
        Variable<String>(fromDate),
        Variable<String>(toDate),
      ],
      readsFrom: <TableInfo<Table, Object?>>{
        transactions,
        attachedDatabase.categories,
      },
    ).map(
      (QueryRow r) => DayTotalRow(
        date: r.read<String>('date'),
        expense: r.read<int>('expense'),
        income: r.read<int>('income'),
      ),
    );
  }

  /// Expense and income of [filter] between two dates (inclusive), one row.
  Selectable<MonthSumRow> listMonthSummary(
    ListFilterSpec filter,
    String fromDate,
    String toDate,
  ) {
    final ListWhere w = listWhere(filter);
    return customSelect(
      monthSummarySql(w),
      variables: <Variable<Object>>[
        ...w.variables,
        Variable<String>(fromDate),
        Variable<String>(toDate),
      ],
      readsFrom: <TableInfo<Table, Object?>>{
        transactions,
        attachedDatabase.categories,
      },
    ).map(
      (QueryRow r) => MonthSumRow(
        expense: r.read<int>('expense'),
        income: r.read<int>('income'),
      ),
    );
  }
}
