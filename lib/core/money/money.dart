/// Money helpers: integer paise <-> Indian rupee text.
///
/// Money is always an `int` number of paise. Never use `double` for money.
/// All maths here is integer maths.
library;

/// Largest amount accepted from input: ₹10,00,00,00,00,000.00 (₹10 trillion).
const int maxPaise = 100000000000000;

const int _maxInputLength = 40;

final RegExp _plainAmount = RegExp(r'^(\d+(\.\d{1,2})?|\.\d{1,2})$');
final RegExp _groupedInteger = RegExp(
  r'^(\d{1,3}(,\d{2})*,\d{3}|\d{1,3}(,\d{3})+)(\.\d*)?$',
);

/// Formats [paise] as Indian rupees, e.g. `12345600` -> `₹1,23,456.00`.
///
/// Negative values give `-₹1,23,456.00`. Works for any `int`.
String formatPaise(int paise) {
  final String raw = paise.toString();
  final bool negative = raw.startsWith('-');
  final String digits = (negative ? raw.substring(1) : raw).padLeft(3, '0');
  final String rupees = digits.substring(0, digits.length - 2);
  final String fraction = digits.substring(digits.length - 2);
  return '${negative ? '-' : ''}₹${_groupIndian(rupees)}.$fraction';
}

/// Groups digits the Indian way: last 3, then pairs (`1,23,45,678`).
String _groupIndian(String digits) {
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

/// Parses rupee text to paise. Returns `null` when the input is invalid.
///
/// Accepts: `1,23,456.00`, `₹1,23,456`, `123456.5`, `.5`, `0`.
/// Commas must follow Indian (`1,23,456`) or Western (`123,456`) grouping.
/// Rejects: empty, letters, negative sign, more than 2 decimals, more than
/// one dot, bad comma placement, spaces inside the number, and anything
/// above [maxPaise]. Zero is valid here; the caller decides whether an
/// amount must be above zero.
int? parseRupeesToPaise(String? input) {
  if (input == null) return null;
  String text = input.trim();
  if (text.isEmpty || text.length > _maxInputLength) return null;
  if (text.startsWith('₹')) text = text.substring(1).trimLeft();
  if (text.isEmpty) return null;

  if (text.contains(',')) {
    // A leading zero in the first group ('0,123') is never valid.
    if (text.startsWith('0')) return null;
    if (!_groupedInteger.hasMatch(text)) return null;
    text = text.replaceAll(',', '');
  }
  if (!_plainAmount.hasMatch(text)) return null;

  final List<String> parts = text.split('.');
  final String rupeeText = parts[0].isEmpty ? '0' : parts[0];
  final String fractionText = parts.length == 2 ? parts[1] : '';

  // Integer digits above 15 can never fit under the limit; skip parsing.
  final String trimmed = rupeeText.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (trimmed.length > 15) return null;

  final int rupees = int.parse(trimmed);
  final int fraction = int.parse(fractionText.padRight(2, '0'));
  final int paise = rupees * 100 + fraction;
  return paise > maxPaise ? null : paise;
}
