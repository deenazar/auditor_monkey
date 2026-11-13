import 'package:drift/drift.dart';

import '../../utils/validation_failure.dart';
import '../app_database.dart';
import '../row_ops.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

/// Total per category (paise), raw from SQL.
class CategorySumRow {
  const CategorySumRow({required this.categoryId, required this.total});

  final String categoryId;
  final int total;
}

/// SQL of one page of the list (newest first). With a cursor, only rows
/// after (older than) the cursor row are returned.
String transactionPageSql({required bool hasCursor}) =>
    'SELECT * FROM transactions WHERE deleted_at IS NULL'
    '${hasCursor ? ' AND (date, created_at, id) < (?, ?, ?)' : ''} '
    'ORDER BY date DESC, created_at DESC, id DESC LIMIT ?';

/// Total of one type between two dates. Loan-linked rows are left out.
///
/// `+loan_id` (unary plus) stops SQLite from choosing `ix_tx_loan` for the
/// `IS NULL` test, which would match almost every row. The date index is the
/// right one for these queries.
const String transactionTotalSql =
    'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
    'WHERE type = ? AND +loan_id IS NULL AND deleted_at IS NULL '
    'AND date >= ? AND date <= ?';

/// Expense total per category between two dates, biggest first.
const String expenseByCategorySql =
    'SELECT category_id, SUM(amount) AS total FROM transactions '
    "WHERE type = 'expense' AND +loan_id IS NULL AND deleted_at IS NULL "
    'AND date >= ? AND date <= ? '
    'GROUP BY category_id ORDER BY total DESC, category_id';

/// One statement row as read from SQL.
class StatementRowData {
  const StatementRowData({
    required this.row,
    required this.effect,
    required this.balanceAfter,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColourGroup,
    required this.counterpartName,
  });

  final TransactionRow row;
  final int effect;
  final int balanceAfter;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColourGroup;
  final String? counterpartName;
}

/// Income or expense of one account in one month, raw from SQL.
class AccountMonthSumRow {
  const AccountMonthSumRow({
    required this.month,
    required this.type,
    required this.total,
  });

  final String month;
  final String type;
  final int total;
}

/// Statement of one account (`?1` = account id), newest first, with the
/// running balance computed by a window sum over ALL live rows of the
/// account (oldest to newest) BEFORE the page is cut. Money rules:
/// expense and transfer out are negative, income and transfer in are
/// positive, deleted rows are left out.
///
/// Two index-friendly branches (`ix_tx_account`, `ix_tx_to_account`) are
/// joined with UNION ALL; a transfer can never be on both sides because the
/// table forbids `to_account_id = account_id`.
///
/// `typeof(balance_after)` is returned too: an overflowing `+` turns into a
/// float in SQLite, and Dart turns that into [OverflowFailure].
String statementPageSql({required bool hasCursor}) =>
    '''
WITH rel AS (
  SELECT t.*, CASE t.type WHEN 'income' THEN t.amount ELSE -t.amount END
         AS effect
    FROM transactions t
   WHERE t.account_id = ?1 AND t.deleted_at IS NULL
  UNION ALL
  SELECT t.*, t.amount AS effect
    FROM transactions t
   WHERE t.to_account_id = ?1 AND t.deleted_at IS NULL
), run AS (
  SELECT rel.*,
    (SELECT opening_balance FROM accounts WHERE id = ?1)
    + SUM(rel.effect) OVER (
        ORDER BY rel.date, rel.created_at, rel.id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance_after
    FROM rel
)
SELECT p.*, typeof(p.balance_after) AS balance_type,
       c.name AS category_name, c.icon AS category_icon,
       c.colour_group AS category_colour_group,
       a.name AS counterpart_name
  FROM (
    SELECT * FROM run
    ${hasCursor ? 'WHERE (date, created_at, id) < (?2, ?3, ?4)' : ''}
    ORDER BY date DESC, created_at DESC, id DESC LIMIT ?${hasCursor ? 5 : 2}
  ) p
  LEFT JOIN categories c ON c.id = p.category_id
  LEFT JOIN accounts a
    ON a.id = CASE WHEN p.account_id = ?1 THEN p.to_account_id
                   ELSE p.account_id END
 ORDER BY p.date DESC, p.created_at DESC, p.id DESC
''';

/// Income and expense of one account per month (`?1` = account id, `?2` /
/// `?3` = first and last date). Transfers (not income or expense) and
/// loan-linked rows are left out, like every other income / spending sum.
/// `+loan_id` keeps SQLite off the weak `ix_tx_loan` index.
const String accountMonthlySumsSql =
    'SELECT substr(date, 1, 7) AS month, type, SUM(amount) AS total '
    'FROM transactions '
    "WHERE account_id = ?1 AND type IN ('income', 'expense') "
    'AND +loan_id IS NULL AND deleted_at IS NULL '
    'AND date >= ?2 AND date <= ?3 '
    'GROUP BY month, type';

@DriftAccessor(tables: <Type>[Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  Future<void> insertRow(TransactionsCompanion row) =>
      into(transactions).insert(row);

  Future<int> updateRow(String id, TransactionsCompanion changes) =>
      (update(transactions)
            ..where((Transactions t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<TransactionRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$TransactionsTable, TransactionRow> query =
        select(transactions)..where((Transactions t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((Transactions t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, transactions, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, transactions, id, now);

  /// Page of live rows, newest first (date, then created time, then id).
  /// Uses `ix_tx_date`. Pass the last row of the previous page as the
  /// cursor for the next page (keyset paging: stays fast on any page).
  Selectable<TransactionRow> page({
    required int limit,
    String? afterDate,
    int? afterCreatedAt,
    String? afterId,
  }) {
    final bool hasCursor =
        afterDate != null && afterCreatedAt != null && afterId != null;
    return customSelect(
      transactionPageSql(hasCursor: hasCursor),
      variables: <Variable<Object>>[
        if (hasCursor) ...<Variable<Object>>[
          Variable<String>(afterDate),
          Variable<int>(afterCreatedAt),
          Variable<String>(afterId),
        ],
        Variable<int>(limit),
      ],
      readsFrom: <TableInfo<Table, Object?>>{transactions},
    ).map((QueryRow r) => transactions.map(r.data));
  }

  /// Total of [type] between two dates (inclusive), in paise.
  ///
  /// Loan-linked rows are left out (they are not spending or income).
  /// Transfers are never counted because only one [type] is summed.
  Selectable<int> totalFor(String type, String from, String to) => customSelect(
    transactionTotalSql,
    variables: <Variable<Object>>[
      Variable<String>(type),
      Variable<String>(from),
      Variable<String>(to),
    ],
    readsFrom: <TableInfo<Table, Object?>>{transactions},
  ).map((QueryRow r) => r.read<int>('total'));

  /// Expense total per category between two dates (inclusive), biggest
  /// first. Loan-linked rows and transfers are left out.
  Selectable<CategorySumRow> expenseByCategory(
    String from,
    String to, {
    int? limit,
  }) =>
      customSelect(
        '$expenseByCategorySql${limit == null ? '' : ' LIMIT ?'}',
        variables: <Variable<Object>>[
          Variable<String>(from),
          Variable<String>(to),
          if (limit != null) Variable<int>(limit),
        ],
        readsFrom: <TableInfo<Table, Object?>>{transactions},
      ).map(
        (QueryRow r) => CategorySumRow(
          categoryId: r.read<String>('category_id'),
          total: r.read<int>('total'),
        ),
      );

  Selectable<StatementRowData> statementPage(
    String accountId, {
    required int limit,
    String? afterDate,
    int? afterCreatedAt,
    String? afterId,
  }) {
    final bool hasCursor =
        afterDate != null && afterCreatedAt != null && afterId != null;
    return customSelect(
      statementPageSql(hasCursor: hasCursor),
      variables: <Variable<Object>>[
        Variable<String>(accountId),
        if (hasCursor) ...<Variable<Object>>[
          Variable<String>(afterDate),
          Variable<int>(afterCreatedAt),
          Variable<String>(afterId),
        ],
        Variable<int>(limit),
      ],
      readsFrom: <TableInfo<Table, Object?>>{
        transactions,
        attachedDatabase.accounts,
        attachedDatabase.categories,
      },
    ).map((QueryRow r) {
      if (r.read<String>('balance_type') != 'integer') {
        throw const OverflowFailure();
      }
      return StatementRowData(
        row: transactions.map(r.data),
        effect: r.read<int>('effect'),
        balanceAfter: r.read<int>('balance_after'),
        categoryName: r.readNullable<String>('category_name'),
        categoryIcon: r.readNullable<String>('category_icon'),
        categoryColourGroup: r.readNullable<String>('category_colour_group'),
        counterpartName: r.readNullable<String>('counterpart_name'),
      );
    });
  }

  /// Income and expense sums per month for one account between two dates
  /// (inclusive). Months without rows are not returned.
  Selectable<AccountMonthSumRow> accountMonthlySums(
    String accountId,
    String fromDate,
    String toDate,
  ) =>
      customSelect(
        accountMonthlySumsSql,
        variables: <Variable<Object>>[
          Variable<String>(accountId),
          Variable<String>(fromDate),
          Variable<String>(toDate),
        ],
        readsFrom: <TableInfo<Table, Object?>>{transactions},
      ).map(
        (QueryRow r) => AccountMonthSumRow(
          month: r.read<String>('month'),
          type: r.read<String>('type'),
          total: r.read<int>('total'),
        ),
      );

  /// Emits whenever transactions, accounts or categories change. The value
  /// carries no data: it is only a signal to reload.
  Stream<int> watchChangeSignal() => customSelect(
    'SELECT 1 AS tick',
    readsFrom: <TableInfo<Table, Object?>>{
      transactions,
      attachedDatabase.accounts,
      attachedDatabase.categories,
    },
  ).watch().map((List<QueryRow> rows) => rows.length);
}
