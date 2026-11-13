// Short labels for Home (display only; amounts stay exact elsewhere).
library;

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _weekdaysLong = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
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

DateTime _parse(String date) => DateTime.utc(
  int.parse(date.substring(0, 4)),
  int.parse(date.substring(5, 7)),
  int.parse(date.substring(8, 10)),
);

/// `Thu` for `2026-11-12`.
String weekdayShort(String date) => _weekdays[_parse(date).weekday - 1];

/// `Thursday` for `2026-11-12`.
String weekdayLong(String date) => _weekdaysLong[_parse(date).weekday - 1];

/// `November 2026` for `2026-11-12`.
String monthYear(String date) {
  final DateTime d = _parse(date);
  return '${_months[d.month - 1]} ${d.year}';
}

/// `12` for `2026-11-12`.
String dayNumber(String date) => int.parse(date.substring(8, 10)).toString();

/// `Thu 12 Nov` for `2026-11-12`.
String dayTitle(String date) {
  final DateTime d = _parse(date);
  return '${_weekdays[d.weekday - 1]} ${d.day} '
      '${_months[d.month - 1].substring(0, 3)}';
}

/// Rupees rounded for tight spaces: `₹0`, `₹840`, `₹1.2k`, `₹12k`,
/// `₹1.5L`, `₹2.3Cr` (Indian lakh / crore). Negative values get a `-`.
String compactRupees(int paise) {
  final bool negative = paise < 0;
  final int rupees = (paise.abs() + 50) ~/ 100;
  final String body;
  if (rupees < 1000) {
    body = '$rupees';
  } else if (rupees < 100000) {
    body = _short(rupees / 1000, 'k');
  } else if (rupees < 10000000) {
    body = _short(rupees / 100000, 'L');
  } else {
    body = _short(rupees / 10000000, 'Cr');
  }
  return '${negative ? '-' : ''}₹$body';
}

String _short(double value, String unit) {
  final String text = value >= 10
      ? value.round().toString()
      : ((value * 10).round() / 10).toString();
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}'
      '$unit';
}
