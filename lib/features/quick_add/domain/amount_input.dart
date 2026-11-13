import '../../../core/money/money.dart';

/// Why the number pad refused a key or a paste.
enum AmountRefusal {
  tooManyDecimals('Only 2 decimal places'),
  tooLarge('Maximum is ₹10,00,00,00,00,000.00'),
  invalidPaste("That isn't a valid amount");

  const AmountRefusal(this.message);

  /// Short text for the hint line under the amount.
  final String message;
}

/// Result of an edit: the new buffer and, when the edit was refused, why.
/// A refused edit returns the buffer unchanged.
class AmountEdit {
  const AmountEdit(this.input, [this.refusal]);

  final AmountInput input;
  final AmountRefusal? refusal;

  bool get refused => refusal != null;
}

/// The amount the number pad is building, as a small text buffer.
///
/// Paise come ONLY from [parseRupeesToPaise] (integer maths, no floating
/// point).
/// Nothing is ever rounded: input that would need rounding is refused.
class AmountInput {
  const AmountInput([this.text = '']);

  /// Plain buffer: digits and at most one dot, e.g. `1250.5`, `12.`, ``.
  final String text;

  static const int maxDecimals = 2;

  /// Buffer for [paise] (above zero): `12345650` -> `123456.5`.
  factory AmountInput.fromPaise(int paise) {
    if (paise <= 0) return const AmountInput();
    final String rupees = (paise ~/ 100).toString();
    final int fraction = paise % 100;
    if (fraction == 0) return AmountInput(rupees);
    final String decimals = fraction.toString().padLeft(2, '0');
    return AmountInput(
      '$rupees.${decimals.endsWith('0') ? decimals.substring(0, 1) : decimals}',
    );
  }

  bool get isEmpty => text.isEmpty;

  int get _dotIndex => text.indexOf('.');

  /// Digits typed after the dot (0 when there is no dot).
  int get _decimals => _dotIndex < 0 ? 0 : text.length - _dotIndex - 1;

  /// Paise, or `null` when the buffer is empty or zero (not savable).
  int? get paise {
    if (text.isEmpty) return null;
    final String plain = text.endsWith('.')
        ? text.substring(0, text.length - 1)
        : text;
    final int? value = parseRupeesToPaise(plain);
    return value == null || value <= 0 ? null : value;
  }

  bool get isSavable => paise != null;

  /// Indian grouping of what is typed; dot and decimals kept as typed
  /// (`1,250.5`, `12.`). Empty buffer gives an empty string (the screen
  /// shows `0` in a muted colour).
  String get display {
    if (text.isEmpty) return '';
    final int dot = _dotIndex;
    final String whole = dot < 0 ? text : text.substring(0, dot);
    final String tail = dot < 0 ? '' : text.substring(dot);
    return '${groupIndianDigits(whole)}$tail';
  }

  /// One digit key (`'0'`..`'9'`). Other characters are ignored.
  AmountEdit pressDigit(String digit) {
    if (digit.length != 1 ||
        digit.codeUnitAt(0) < 48 ||
        digit.codeUnitAt(0) > 57) {
      return AmountEdit(this);
    }
    if (_dotIndex >= 0 && _decimals >= maxDecimals) {
      return AmountEdit(this, AmountRefusal.tooManyDecimals);
    }
    // A lone leading zero is replaced ("0" then "5" -> "5").
    final String next = text == '0' ? digit : '$text$digit';
    if (_overLimit(next)) return AmountEdit(this, AmountRefusal.tooLarge);
    return AmountEdit(AmountInput(next));
  }

  /// The dot key. On an empty buffer it gives `0.`; a second dot is ignored.
  AmountEdit pressDot() {
    if (_dotIndex >= 0) return AmountEdit(this);
    return AmountEdit(AmountInput(text.isEmpty ? '0.' : '$text.'));
  }

  /// Removes the last character.
  AmountInput backspace() =>
      text.isEmpty ? this : AmountInput(text.substring(0, text.length - 1));

  AmountInput clear() => const AmountInput();

  /// Pasted text goes through [parseRupeesToPaise] (accepts `₹` and Indian
  /// or Western commas). Invalid text leaves the buffer unchanged.
  AmountEdit paste(String? clipboardText) {
    final int? value = parseRupeesToPaise(clipboardText);
    if (value == null) return AmountEdit(this, AmountRefusal.invalidPaste);
    return AmountEdit(
      value == 0 ? const AmountInput('0') : AmountInput.fromPaise(value),
    );
  }

  bool _overLimit(String next) {
    final String plain = next.endsWith('.')
        ? next.substring(0, next.length - 1)
        : next;
    return parseRupeesToPaise(plain) == null;
  }

  @override
  bool operator ==(Object other) => other is AmountInput && other.text == text;

  @override
  int get hashCode => text.hashCode;
}
