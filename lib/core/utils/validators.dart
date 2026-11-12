/// Shared input checks. Each one throws [ValidationFailure] on bad input.
///
/// These run in repositories (the data layer). The UI can reuse them for
/// instant messages. The database also has CHECK rules as a backup.
library;

import '../money/money.dart';
import 'validation_failure.dart';

// Control characters (except tab/newline handled per call) are never allowed.
final RegExp _controlChars = RegExp(
  r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
);
final RegExp _controlCharsNoNewline = RegExp(r'[\u0000-\u001F\u007F]');
final RegExp _dateShape = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _monthShape = RegExp(r'^\d{4}-\d{2}$');

const int _minYear = 1900;
const int _maxYear = 2100;

/// Required single-line text. Returns the trimmed value.
String validateName(String field, String? value, {required int max}) {
  final String text = (value ?? '').trim();
  if (text.isEmpty) {
    throw ValidationFailure(
      field,
      FailureCode.required,
      'Please enter $field.',
    );
  }
  if (text.length > max) {
    throw ValidationFailure(
      field,
      FailureCode.tooLong,
      'Use $max characters or fewer.',
    );
  }
  if (_controlCharsNoNewline.hasMatch(text)) {
    throw ValidationFailure(
      field,
      FailureCode.invalidCharacters,
      'Remove special characters.',
    );
  }
  return text;
}

/// Optional text (notes). Empty becomes `null`. Newlines are allowed.
String? validateOptionalText(String field, String? value, {required int max}) {
  final String text = (value ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length > max) {
    throw ValidationFailure(
      field,
      FailureCode.tooLong,
      'Use $max characters or fewer.',
    );
  }
  if (_controlChars.hasMatch(text)) {
    throw ValidationFailure(
      field,
      FailureCode.invalidCharacters,
      'Remove special characters.',
    );
  }
  return text;
}

/// Money in paise: whole number from [min] to [maxPaise].
void validatePaise(String field, int value, {int min = 1}) {
  if (value < min || value > maxPaise) {
    throw ValidationFailure(
      field,
      FailureCode.outOfRange,
      min > 0
          ? 'Amount must be above zero and within the limit.'
          : 'Amount is outside the allowed range.',
    );
  }
}

/// Whole number inside an inclusive range (weights, rates).
void validateIntRange(
  String field,
  int value, {
  required int min,
  required int max,
}) {
  if (value < min || value > max) {
    throw ValidationFailure(
      field,
      FailureCode.outOfRange,
      'Value is outside the allowed range.',
    );
  }
}

/// True when [value] is a real calendar date written `YYYY-MM-DD`.
bool isValidDate(String? value) {
  if (value == null || !_dateShape.hasMatch(value)) return false;
  final int year = int.parse(value.substring(0, 4));
  final int month = int.parse(value.substring(5, 7));
  final int day = int.parse(value.substring(8, 10));
  if (year < _minYear || year > _maxYear) return false;
  final DateTime date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

/// True when [value] is a real month written `YYYY-MM`.
bool isValidMonth(String? value) =>
    value != null && _monthShape.hasMatch(value) && isValidDate('$value-01');

void validateDate(String field, String? value) {
  if (!isValidDate(value)) {
    throw ValidationFailure(
      field,
      FailureCode.invalidDate,
      'Enter a valid date.',
    );
  }
}

void validateMonth(String field, String? value) {
  if (!isValidMonth(value)) {
    throw ValidationFailure(
      field,
      FailureCode.invalidDate,
      'Enter a valid month.',
    );
  }
}

/// Throws [ValidationFailure] when [ok] is false.
void ensure(bool ok, String field, FailureCode code, String message) {
  if (!ok) throw ValidationFailure(field, code, message);
}
