import '../../../core/sync/synced_entity.dart';

enum TransactionType { expense, income, transfer }

/// One money entry. Named `TransactionEntry` to avoid a clash with Drift's
/// own `Transaction` type.
final class TransactionEntry extends SyncedEntity {
  const TransactionEntry({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.toAccountId,
    required this.categoryId,
    required this.note,
    required this.loanId,
    required this.importSource,
  });

  final TransactionType type;

  /// Paise, always above zero. The [type] sets the direction.
  final int amount;

  /// Local calendar date, `YYYY-MM-DD`.
  final String date;
  final String accountId;

  /// Transfers only: the account that receives the money.
  final String? toAccountId;

  /// Expense and income only.
  final String? categoryId;
  final String? note;
  final String? loanId;
  final String? importSource;
}

/// Values the user can set on a transaction.
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.loanId,
    this.importSource,
  });

  final TransactionType type;
  final int amount;
  final String date;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;
  final String? loanId;
  final String? importSource;
}

/// Where the next page of the list starts (keyset paging).
class TransactionCursor {
  const TransactionCursor({
    required this.date,
    required this.createdAt,
    required this.id,
  });

  factory TransactionCursor.after(TransactionEntry last) => TransactionCursor(
    date: last.date,
    createdAt: last.createdAt,
    id: last.id,
  );

  final String date;
  final int createdAt;
  final String id;
}
