import 'transaction_entry.dart';

/// One row of the Transactions list or the detail screen, with names
/// already resolved (so the UI never looks ids up).
class TransactionListItem {
  const TransactionListItem({
    required this.entry,
    required this.accountName,
    required this.accountColour,
    this.toAccountName,
    this.toAccountColour,
    this.categoryName,
    this.categoryIcon,
    this.categoryColourGroup,
  });

  final TransactionEntry entry;

  /// Name and colour token (e.g. `accountSbi`) of the (From) account.
  final String accountName;
  final String accountColour;

  /// Transfers only.
  final String? toAccountName;
  final String? toAccountColour;

  /// Expense and income only. The colour group is always a known name
  /// (unknown stored values become `other`).
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColourGroup;

  bool get isTransfer => entry.type == TransactionType.transfer;

  /// Row title: the category name, or "SBI → Axis" for a transfer.
  String get title => isTransfer
      ? '$accountName → ${toAccountName ?? ''}'
      : (categoryName ?? 'Entry');
}

/// Spending and income of one day (paise) for the current filter.
///
/// Like every other sum in the app: transfers are never income or spending,
/// and loan-linked entries are left out.
class DayTotal {
  const DayTotal({required this.date, this.expense = 0, this.income = 0});

  /// `YYYY-MM-DD`.
  final String date;
  final int expense;
  final int income;

  int get net => income - expense;

  @override
  bool operator ==(Object other) =>
      other is DayTotal &&
      other.date == date &&
      other.expense == expense &&
      other.income == income;

  @override
  int get hashCode => Object.hash(date, expense, income);
}

/// Spent, income and net of one month (paise) for the current filter. Same
/// rules as [DayTotal].
class MonthSummary {
  const MonthSummary({required this.month, this.spent = 0, this.income = 0});

  /// `YYYY-MM`.
  final String month;
  final int spent;
  final int income;

  int get net => income - spent;

  @override
  bool operator ==(Object other) =>
      other is MonthSummary &&
      other.month == month &&
      other.spent == spent &&
      other.income == income;

  @override
  int get hashCode => Object.hash(month, spent, income);
}

/// One day of the list: its header total and its rows (newest first).
class DayGroup {
  const DayGroup({required this.total, required this.items});

  final DayTotal total;
  final List<TransactionListItem> items;

  String get date => total.date;
}

/// Groups [items] (already newest first) by day, in order. A day with no
/// entry in [totals] gets a zero total. Pure, so it is unit tested.
List<DayGroup> groupByDay(
  List<TransactionListItem> items,
  Map<String, DayTotal> totals,
) {
  final List<DayGroup> groups = <DayGroup>[];
  List<TransactionListItem>? current;
  String? date;
  for (final TransactionListItem item in items) {
    if (item.entry.date != date) {
      date = item.entry.date;
      current = <TransactionListItem>[];
      groups.add(
        DayGroup(
          total: totals[date] ?? DayTotal(date: date),
          items: current,
        ),
      );
    }
    current!.add(item);
  }
  return groups;
}
