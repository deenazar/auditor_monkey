import '../../transactions/domain/transaction_entry.dart';

/// What the newest live entry of one type used (account, To account for a
/// transfer, category for expense and income).
class LastUsedPick {
  const LastUsedPick({
    required this.accountId,
    this.toAccountId,
    this.categoryId,
  });

  final String accountId;
  final String? toAccountId;
  final String? categoryId;
}

/// How often and when one category was used in the recent window.
class CategoryUsage {
  const CategoryUsage({
    required this.categoryId,
    required this.uses,
    required this.lastUsed,
  });

  final String categoryId;
  final int uses;

  /// Entry time (epoch ms) of the newest entry in this category.
  final int lastUsed;
}

/// Everything Quick Add learns from past entries, in one snapshot.
class QuickAddHints {
  const QuickAddHints({
    this.lastUsed = const <TransactionType, LastUsedPick>{},
    this.usage = const <TransactionType, List<CategoryUsage>>{},
    this.recent = const <TransactionEntry>[],
  });

  static const QuickAddHints empty = QuickAddHints();

  /// Per type (expense, income, transfer). A type with no recent entry is
  /// missing.
  final Map<TransactionType, LastUsedPick> lastUsed;

  /// Per type (expense, income): category usage in the recent window.
  final Map<TransactionType, List<CategoryUsage>> usage;

  /// Newest entries of all types, newest first (not yet de-duplicated).
  final List<TransactionEntry> recent;
}
