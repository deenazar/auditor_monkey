import 'transaction_entry.dart';

/// One row of an account statement.
///
/// [effect] is the signed change this entry made to THIS account (paise):
/// expense negative, income positive, transfer out negative, transfer in
/// positive. [balanceAfter] is the account balance right after the entry
/// (opening balance plus every entry up to and including this one).
class StatementLine {
  const StatementLine({
    required this.entry,
    required this.effect,
    required this.balanceAfter,
    this.categoryName,
    this.categoryIcon,
    this.counterpartName,
  });

  final TransactionEntry entry;
  final int effect;
  final int balanceAfter;

  /// Expense and income only (also when the category was deleted later).
  final String? categoryName;

  /// Lucide icon name (kebab case) of the category.
  final String? categoryIcon;

  /// Transfers only: the other account's name. "To X" when [isOutgoing],
  /// otherwise "From X".
  final String? counterpartName;

  bool get isTransfer => entry.type == TransactionType.transfer;

  /// Money left this account.
  bool get isOutgoing => effect < 0;
}

/// A page of statement lines, newest first.
class StatementPage {
  const StatementPage({required this.lines, required this.hasMore});

  final List<StatementLine> lines;

  /// True when older lines exist after the last one in [lines].
  final bool hasMore;

  TransactionCursor? get nextCursor => hasMore && lines.isNotEmpty
      ? TransactionCursor.after(lines.last.entry)
      : null;
}

/// Income and expense of one account in one month (paise). Transfers and
/// loan-linked entries are never counted.
class MonthlyTotal {
  const MonthlyTotal({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// `YYYY-MM`.
  final String month;
  final int income;
  final int expense;

  @override
  bool operator ==(Object other) =>
      other is MonthlyTotal &&
      other.month == month &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(month, income, expense);
}
