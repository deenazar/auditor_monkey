/// First and last possible date text of a `YYYY-MM` month.
///
/// Dates are `YYYY-MM-DD` text, so plain text comparison orders them
/// correctly. `-31` is safe as an upper bound for any month.
({String start, String end}) monthRange(String month) =>
    (start: '$month-01', end: '$month-31');

/// `YYYY-MM-DD` text of a calendar date (the parts of [date] as given; no
/// time zone change).
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `YYYY-MM` text of the month of [date].
String monthKeyOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}';

/// The month [delta] months after (or before, when negative) a `YYYY-MM`
/// month. Pure integer maths, no time zones.
String addMonths(String month, int delta) {
  final int year = int.parse(month.substring(0, 4));
  final int zeroBased = int.parse(month.substring(5, 7)) - 1;
  final int total = year * 12 + zeroBased + delta;
  final int newYear = total ~/ 12;
  final int newMonth = total % 12 + 1;
  return '${newYear.toString().padLeft(4, '0')}-'
      '${newMonth.toString().padLeft(2, '0')}';
}

/// Every month from [from] to [to] (both included, `YYYY-MM`), oldest first.
List<String> monthsBetween(String from, String to) {
  final List<String> months = <String>[];
  String current = from;
  while (current.compareTo(to) <= 0) {
    months.add(current);
    current = addMonths(current, 1);
  }
  return months;
}

const List<String> _shortMonthNames = <String>[
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

/// Short English name of a `YYYY-MM` month, e.g. `2026-11` -> `Nov`.
String shortMonthName(String month) =>
    _shortMonthNames[int.parse(month.substring(5, 7)) - 1];

/// The date [days] after (or before, when negative) a `YYYY-MM-DD` date.
/// Pure calendar maths in UTC, so daylight saving never shifts the result.
String addDays(String date, int days) {
  final DateTime base = DateTime.utc(
    int.parse(date.substring(0, 4)),
    int.parse(date.substring(5, 7)),
    int.parse(date.substring(8, 10)),
  );
  return dateKey(base.add(Duration(days: days)));
}
