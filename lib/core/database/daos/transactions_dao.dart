import 'package:drift/drift.dart';

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
}
