import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_text_styles.dart';
import 'package:auditor_monkey/shared/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/widget_harness.dart';

/// The RichText that draws the amount (it contains the ₹ glyph).
Finder _amountRichText() => find.descendant(
  of: find.byType(AmountText),
  matching: find.byWidgetPredicate(
    (Widget w) => w is RichText && w.text.toPlainText().contains('₹'),
  ),
);

RichText _richText(WidgetTester tester) =>
    tester.widget<RichText>(_amountRichText());

String _plain(WidgetTester tester) => _richText(tester).text.toPlainText();

/// Every TextSpan in the tree, depth first.
Iterable<TextSpan> _allSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
      yield* _allSpans(child);
    }
  }
}

void main() {
  testWidgets('formats paise in Indian grouping with the ₹ glyph', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const AmountText(paise: 12345600));
    expect(_plain(tester), '₹1,23,456.00');
  });

  testWidgets('expense shows a minus sign in ink', (WidgetTester tester) async {
    await pumpThemed(
      tester,
      const AmountText(paise: 50000, kind: AmountKind.expense),
    );
    expect(_plain(tester), '−₹500.00');
    expect(_richText(tester).text.style?.color, AppColors.ink);
    expect(find.bySemanticsLabel('Expense ₹500.00'), findsOneWidget);
  });

  testWidgets('income shows a plus sign in success green', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(paise: 150000, kind: AmountKind.income),
    );
    expect(_plain(tester), '+₹1,500.00');
    expect(_richText(tester).text.style?.color, AppColors.success);
    expect(find.bySemanticsLabel('Income ₹1,500.00'), findsOneWidget);
  });

  testWidgets('transfer has no sign, a ⇄ icon and inkMuted colour', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(paise: 99900, kind: AmountKind.transfer),
    );
    expect(_plain(tester), '₹999.00');
    expect(_richText(tester).text.style?.color, AppColors.inkMuted);
    expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);
    expect(find.bySemanticsLabel('Transfer ₹999.00'), findsOneWidget);
  });

  testWidgets('expense and income have no transfer icon', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(paise: 100, kind: AmountKind.expense),
    );
    expect(find.byIcon(LucideIcons.arrowLeftRight), findsNothing);
  });

  testWidgets('plain negative shows a minus sign (U+2212) before the ₹', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const AmountText(paise: -100000));
    expect(_plain(tester), '−₹1,000.00');
    expect(find.bySemanticsLabel('minus ₹1,000.00'), findsOneWidget);
  });

  testWidgets('explicit colour overrides the kind colour', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(
        paise: 100,
        kind: AmountKind.income,
        color: AppColors.onDark,
      ),
    );
    expect(_richText(tester).text.style?.color, AppColors.onDark);
  });

  testWidgets('digits use tabular figures and the ₹ is 75% and Regular', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(paise: 100, style: AppTextStyles.displayAmount),
    );
    final TextSpan root = _richText(tester).text as TextSpan;
    expect(root.style?.fontFeatures, isNotNull);
    expect(
      root.style!.fontFeatures!.any((FontFeature f) => f.feature == 'tnum'),
      isTrue,
    );

    final TextSpan rupee = _allSpans(root)
        .firstWhere((TextSpan s) => s.text == '₹');
    expect(
      rupee.style!.fontSize,
      closeTo(AppTextStyles.displayAmount.fontSize! * 0.75, 0.001),
    );
    expect(rupee.style!.fontWeight, FontWeight.w400);
  });

  testWidgets('shrinks to fit a narrow width instead of cutting off', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 120,
          child: AmountText(
            paise: 987654321_00,
            style: AppTextStyles.displayAmount,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final Size fitted = tester.getSize(
      find.descendant(
        of: find.byType(AmountText),
        matching: find.byType(FittedBox),
      ),
    );
    expect(fitted.width, lessThanOrEqualTo(120));
  });

  testWidgets('large text (2.0) does not overflow or cut the amount', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AmountText(
        paise: 12345600,
        kind: AmountKind.expense,
        style: AppTextStyles.displayAmount,
      ),
      textScale: 2,
      width: 200,
    );
    expect(tester.takeException(), isNull);
    expect(_plain(tester), '−₹1,23,456.00');
  });
}
