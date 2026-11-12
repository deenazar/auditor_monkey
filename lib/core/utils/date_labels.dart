import 'date_keys.dart';

/// Short label for a stored `YYYY-MM-DD` date, as shown in statement rows:
/// `12 Nov`. The year is added only when it is not [todayKey]'s year, so
/// `12 Nov 2025` shows for an older entry.
///
/// Pure text work (no time zones). A malformed date is returned as it is.
String shortDateLabel(String dateText, {required String todayKey}) {
  final RegExpMatch? match = _dateShape.firstMatch(dateText);
  if (match == null) return dateText;
  final String year = match.group(1)!;
  final String month = '${match.group(1)}-${match.group(2)}';
  final int day = int.parse(match.group(3)!);
  final String label = '$day ${shortMonthName(month)}';
  return year == todayKey.substring(0, 4) ? label : '$label $year';
}

final RegExp _dateShape = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
