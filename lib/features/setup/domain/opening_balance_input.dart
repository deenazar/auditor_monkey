/// Turns what the user typed for an opening balance into paise.
///
/// Money is an integer number of paise at all times. There is no `double`
/// anywhere in this file.
library;

import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';

/// Result of reading an opening balance field.
class OpeningBalanceInput {
  const OpeningBalanceInput.valid(int this.paise) : error = null;

  const OpeningBalanceInput.invalid(String this.error) : paise = null;

  /// Signed paise (negative only for a card account with "I owe").
  final int? paise;

  /// Friendly message, or `null` when the input is fine.
  final String? error;

  bool get isValid => error == null;
}

final RegExp _separators = RegExp(r'[,₹\s]');
final RegExp _plainAmount = RegExp(r'^\d+(\.\d{1,2})?$');
final RegExp _typingShape = RegExp(r'^(\d+\.?\d{0,2}|\.\d{0,2})$');

/// Reads [text] as rupees ("1,23,456.50"). Empty means 0.
///
/// [owes] ("I owe") makes the amount negative, but only for [AccountType.card];
/// for any other type it is ignored. A minus sign in the text is never
/// accepted. The limit is [maxPaise].
OpeningBalanceInput parseOpeningBalance(
  String text, {
  required AccountType type,
  bool owes = false,
}) {
  if (text.trim().isEmpty) return const OpeningBalanceInput.valid(0);
  final int? paise = parseRupeesToPaise(text);
  if (paise == null) {
    final String plain = text.replaceAll(_separators, '');
    if (_plainAmount.hasMatch(plain) && parseRupeesToPaise(plain) == null) {
      return const OpeningBalanceInput.invalid(
        'This amount is too large. The limit is ₹10,00,00,00,00,000.',
      );
    }
    return const OpeningBalanceInput.invalid(
      'Enter an amount like 1,500 or 1,500.50.',
    );
  }
  final bool negative = owes && type == AccountType.card;
  return OpeningBalanceInput.valid(negative ? -paise : paise);
}

/// Adds Indian grouping to the whole-rupee part of an amount typed by the
/// user ("123456.5" -> "1,23,456.5"). Text that is not a valid amount is
/// returned as it is. Used when a field loses focus.
String groupRupeeText(String text) {
  final String plain = text.replaceAll(_separators, '');
  if (!plain.contains(RegExp(r'\d')) || !_typingShape.hasMatch(plain)) {
    return text;
  }
  final List<String> parts = plain.split('.');
  final String whole = parts[0].isEmpty ? '0' : parts[0];
  final String trimmed = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final String grouped = _group(trimmed);
  return parts.length == 2 ? '$grouped.${parts[1]}' : grouped;
}

/// Amount text to put in a field for [paise]: no sign (the "I owe" toggle
/// carries it), Indian grouping, paise only when not zero.
/// `12345650` -> `1,23,456.50`, `12345600` -> `1,23,456`, `0` -> ``.
String paiseToInputText(int paise) {
  if (paise == 0) return '';
  final String full = formatPaise(paise.abs()).substring(1); // drop "₹"
  return full.endsWith('.00') ? full.substring(0, full.length - 3) : full;
}

String _group(String digits) {
  if (digits.length <= 3) return digits;
  final String last3 = digits.substring(digits.length - 3);
  String rest = digits.substring(0, digits.length - 3);
  final List<String> parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}
