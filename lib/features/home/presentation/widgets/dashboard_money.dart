import '../../../../core/money/money.dart';

/// A signed amount with the typographic minus (`−₹18,300.50`), as the
/// Dashboard shows negative numbers (DESIGN.md Amounts). Positive amounts
/// get no sign.
String minusMoney(int paise) =>
    paise < 0 ? '−${formatPaise(-paise)}' : formatPaise(paise);
