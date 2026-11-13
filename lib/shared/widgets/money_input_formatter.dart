import 'package:flutter/services.dart';

/// Most digits before the dot (₹10,00,00,00,00,000 has 13).
const int maxMoneyIntegerDigits = 13;

/// Most digits after the dot (paise).
const int maxMoneyDecimalDigits = 2;

/// Keeps a rupee amount field clean while typing or pasting.
///
/// Only digits and ONE dot are kept (commas, the ₹ sign, spaces, letters
/// and minus signs are dropped), at most [maxMoneyIntegerDigits] digits
/// before the dot and 2 after it. The cursor stays next to the character
/// it was next to. Indian grouping is added when the field loses focus
/// (see `groupRupeeText`), not while typing.
///
/// A minus sign is dropped on purpose: debt is entered with the
/// "I owe" toggle, never with a sign.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    final StringBuffer out = StringBuffer();
    // offsetAt[i] = length of the cleaned text before original index i.
    final List<int> offsetAt = List<int>.filled(text.length + 1, 0);
    bool seenDot = false;
    int integerDigits = 0;
    int decimalDigits = 0;
    for (int i = 0; i < text.length; i++) {
      offsetAt[i] = out.length;
      final int unit = text.codeUnitAt(i);
      final bool isDigit = unit >= 0x30 && unit <= 0x39;
      if (isDigit) {
        if (!seenDot && integerDigits < maxMoneyIntegerDigits) {
          out.writeCharCode(unit);
          integerDigits++;
        } else if (seenDot && decimalDigits < maxMoneyDecimalDigits) {
          out.writeCharCode(unit);
          decimalDigits++;
        }
      } else if (unit == 0x2E && !seenDot) {
        out.write('.');
        seenDot = true;
      }
    }
    offsetAt[text.length] = out.length;

    final String cleaned = out.toString();
    if (cleaned == text) return newValue;

    int map(int offset) =>
        offset < 0 ? offset : offsetAt[offset.clamp(0, text.length)];
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection(
        baseOffset: map(newValue.selection.baseOffset),
        extentOffset: map(newValue.selection.extentOffset),
      ),
    );
  }
}
