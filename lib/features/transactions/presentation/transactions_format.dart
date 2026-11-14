import '../../../core/money/money.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_list_item.dart';

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime _day(String date) => DateTime.utc(
  int.parse(date.substring(0, 4)),
  int.parse(date.substring(5, 7)),
  int.parse(date.substring(8, 10)),
);

/// `Today`, `Yesterday`, or `Thu 12 Nov` (with the year when it is not this
/// year). Pure text work; [today] is `YYYY-MM-DD`.
String dayHeaderLabel(String date, String today) {
  if (date == today) return 'Today';
  if (date == addDays(today, -1)) return 'Yesterday';
  final DateTime d = _day(date);
  final String base =
      '${_weekdays[d.weekday - 1]} ${d.day} ${_shortMonths[d.month - 1]}';
  return date.substring(0, 4) == today.substring(0, 4)
      ? base
      : '$base ${d.year}';
}

/// `November 2026` for `2026-11` (or any `YYYY-MM…` text).
String monthTitle(String month) {
  final int m = int.parse(month.substring(5, 7));
  return '${_months[m - 1]} ${month.substring(0, 4)}';
}

/// `Thursday 12 November 2026` for `2026-11-12`, read aloud in the detail.
String longDate(String date) {
  final DateTime d = _day(date);
  final String weekday = _weekdays[d.weekday - 1];
  return '$weekday ${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Sign shown in front of an amount: `-` expense, `+` income, none for
/// transfers.
String amountSign(TransactionType type) => switch (type) {
  TransactionType.expense => '-',
  TransactionType.income => '+',
  TransactionType.transfer => '',
};

/// The row amount, e.g. `-₹250.00`.
String signedAmount(TransactionEntry e) =>
    '${amountSign(e.type)}${formatPaise(e.amount)}';

/// Kind word for labels: Expense, Income or Transfer.
String kindLabel(TransactionType type) => switch (type) {
  TransactionType.expense => 'Expense',
  TransactionType.income => 'Income',
  TransactionType.transfer => 'Transfer',
};

/// Second line of a row: the account and note, or the note of a transfer.
/// Notes are shown as typed; they never go to the log.
List<String> rowMeta(TransactionListItem item) {
  final String note = (item.entry.note ?? '').trim();
  if (item.isTransfer) {
    return <String>[note.isEmpty ? 'Transfer' : note];
  }
  return <String>[item.accountName, if (note.isNotEmpty) note];
}

/// Screen reader label of a row, e.g. "Expense, Groceries, -₹250.00, SBI,
/// Milk".
String rowSemanticsLabel(TransactionListItem item) => <String>[
  kindLabel(item.entry.type),
  item.title,
  signedAmount(item.entry),
  ...rowMeta(item),
].join(', ');

/// Totals of one day as spoken text, for the day header.
String dayTotalSpoken(int expense, int income) {
  final List<String> parts = <String>[
    if (expense > 0) 'spent ${formatPaise(expense)}',
    if (income > 0) 'income ${formatPaise(income)}',
  ];
  return parts.join(', ');
}
