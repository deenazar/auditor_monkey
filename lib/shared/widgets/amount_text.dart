import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money/money.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// What an amount means. Sets the sign, the colour and the icon (DESIGN.md
/// Amounts table).
enum AmountKind {
  /// Balances and other plain numbers: no sign unless negative.
  plain,

  /// Money out: `ink`, with a `−` sign.
  expense,

  /// Money in: `success` green, with a `+` sign.
  income,

  /// Between accounts: `inkMuted`, no sign, with a ⇄ icon.
  transfer,
}

/// Screen reader text for a plain amount: "minus ₹500.00" when negative.
String spokenPaise(int paise) =>
    paise < 0 ? 'minus ${formatPaise(paise.abs())}' : formatPaise(paise);

/// A money amount from integer paise, e.g. `₹1,23,456.00`.
///
/// Digits use tabular figures. The ₹ sign is drawn smaller (see
/// [AppTextStyles.rupeeSign]). The text shrinks to fit its width instead of
/// being cut, so it stays whole at large text sizes. The amount is always
/// shown as a positive number, and [kind] adds the sign.
class AmountText extends StatelessWidget {
  const AmountText({
    required this.paise,
    this.kind = AmountKind.plain,
    this.style = AppTextStyles.body,
    this.color,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  /// Amount in paise. Negative values only make sense for [AmountKind.plain].
  final int paise;

  final AmountKind kind;

  /// Base text style. Its size sets the size of the amount.
  final TextStyle style;

  /// Overrides the colour from [kind]. Use it on coloured cards, where the
  /// text must be `ink` or `onDark`.
  final Color? color;

  /// Where the amount sits when it has room to spare.
  final AlignmentGeometry alignment;

  /// Colour for [kind] when no [color] is given.
  static Color colourFor(AmountKind kind, {Color? plainColour}) {
    return switch (kind) {
      AmountKind.plain => plainColour ?? AppColors.ink,
      AmountKind.expense => AppColors.ink,
      AmountKind.income => AppColors.success,
      AmountKind.transfer => AppColors.inkMuted,
    };
  }

  String get _sign {
    return switch (kind) {
      AmountKind.plain => paise < 0 ? '−' : '',
      AmountKind.expense => '−',
      AmountKind.income => '+',
      AmountKind.transfer => '',
    };
  }

  String get _spokenLabel {
    final String amount = formatPaise(paise.abs());
    return switch (kind) {
      AmountKind.plain => spokenPaise(paise),
      AmountKind.expense => 'Expense $amount',
      AmountKind.income => 'Income $amount',
      AmountKind.transfer => 'Transfer $amount',
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color textColour = color ?? colourFor(kind, plainColour: style.color);
    final TextStyle base = AppTextStyles.tabular(style)
        .copyWith(color: textColour);
    // The ₹ span is a child with its own style. Give it the font fallback
    // of the surrounding text, or a font without ₹ draws a box.
    final TextStyle rupee = AppTextStyles.rupeeSign(base).copyWith(
      fontFamilyFallback:
          base.fontFamilyFallback ??
          DefaultTextStyle.of(context).style.fontFamilyFallback,
    );

    // formatPaise gives "₹…" for a positive value; split off the ₹ glyph.
    final String formatted = formatPaise(paise.abs());
    final String rupeeGlyph = formatted.substring(0, 1);
    final String digits = formatted.substring(1);

    final Widget text = Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (_sign.isNotEmpty) TextSpan(text: _sign),
          TextSpan(text: rupeeGlyph, style: rupee),
          TextSpan(text: digits),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: base,
    );

    final Widget content = kind == AmountKind.transfer
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                LucideIcons.arrowLeftRight,
                size: AppSizes.iconInline,
                color: textColour,
              ),
              const SizedBox(width: AppSpacing.space2),
              text,
            ],
          )
        : text;

    return Semantics(
      label: _spokenLabel,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: content,
      ),
    );
  }
}
