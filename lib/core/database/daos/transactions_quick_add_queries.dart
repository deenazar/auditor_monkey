import 'package:drift/drift.dart';

import '../app_database.dart';
import 'transactions_dao.dart';

/// Quick Add read queries. They only look at live rows dated on or after a
/// cutoff (`date >= ?`, future dates included), so `ix_tx_date` keeps them
/// fast on 20,000+ rows. Loan-linked rows are left out: Quick Add cannot
/// create a loan link, so repeating one would drop the link.
///
/// `+loan_id` (unary plus) keeps SQLite off the weak `ix_tx_loan` index.

/// Newest live row of one type (`?1`) by entry time, since `?2`.
const String quickAddLastUsedSql =
    'SELECT account_id, to_account_id, category_id FROM transactions '
    'WHERE type = ?1 AND deleted_at IS NULL AND +loan_id IS NULL '
    'AND date >= ?2 '
    'ORDER BY created_at DESC, id DESC LIMIT 1';

/// Uses and last use per category for one type (`?1`), since `?2`.
/// `GROUP BY +category_id` stops SQLite from walking the whole
/// `ix_tx_category_date` index; the date range is what keeps it fast.
const String quickAddUsageSql =
    'SELECT category_id, COUNT(*) AS uses, MAX(created_at) AS last_used '
    'FROM transactions '
    'WHERE type = ?1 AND deleted_at IS NULL AND +loan_id IS NULL '
    'AND date >= ?2 '
    'GROUP BY +category_id';

/// Newest live rows of all types by entry time, since `?1`.
const String quickAddRecentSql =
    'SELECT * FROM transactions '
    'WHERE deleted_at IS NULL AND +loan_id IS NULL AND date >= ?1 '
    'ORDER BY created_at DESC, id DESC LIMIT $quickAddRecentLimit';

/// Rows the recent query returns (de-duplicated and cut to 6 in Dart).
const int quickAddRecentLimit = 50;

/// What the newest entry of one type used.
class LastUsedRow {
  const LastUsedRow({
    required this.accountId,
    required this.toAccountId,
    required this.categoryId,
  });

  final String accountId;
  final String? toAccountId;
  final String? categoryId;
}

/// How often and when one category was used.
class CategoryUsageRow {
  const CategoryUsageRow({
    required this.categoryId,
    required this.uses,
    required this.lastUsed,
  });

  final String categoryId;
  final int uses;

  /// `created_at` (epoch ms) of the newest entry in the category.
  final int lastUsed;
}

/// Quick Add queries, kept out of `transactions_dao.dart` (file size).
extension QuickAddQueries on TransactionsDao {
  Selectable<LastUsedRow> quickAddLastUsed(String type, String since) =>
      customSelect(
        quickAddLastUsedSql,
        variables: <Variable<Object>>[
          Variable<String>(type),
          Variable<String>(since),
        ],
        readsFrom: <TableInfo<Table, Object?>>{transactions},
      ).map(
        (QueryRow r) => LastUsedRow(
          accountId: r.read<String>('account_id'),
          toAccountId: r.readNullable<String>('to_account_id'),
          categoryId: r.readNullable<String>('category_id'),
        ),
      );

  Selectable<CategoryUsageRow> quickAddUsage(String type, String since) =>
      customSelect(
        quickAddUsageSql,
        variables: <Variable<Object>>[
          Variable<String>(type),
          Variable<String>(since),
        ],
        readsFrom: <TableInfo<Table, Object?>>{transactions},
      ).map(
        (QueryRow r) => CategoryUsageRow(
          categoryId: r.read<String>('category_id'),
          uses: r.read<int>('uses'),
          lastUsed: r.read<int>('last_used'),
        ),
      );

  Selectable<TransactionRow> quickAddRecent(String since) => customSelect(
    quickAddRecentSql,
    variables: <Variable<Object>>[Variable<String>(since)],
    readsFrom: <TableInfo<Table, Object?>>{transactions},
  ).map((QueryRow r) => transactions.map(r.data));
}
