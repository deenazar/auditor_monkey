import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_card.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/theme/app_text_styles.dart';
import 'package:auditor_monkey/shared/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

AccountCard _card({
  String name = 'SBI',
  AccountType type = AccountType.bank,
  String colour = 'accountSbi',
  int balance = 12345600,
  int opening = 10000000,
  bool archived = false,
  VoidCallback? onTap,
}) {
  return AccountCard(
    name: name,
    type: type,
    colourToken: colour,
    balancePaise: balance,
    openingPaise: opening,
    archived: archived,
    onTap: onTap,
  );
}

String _amountPlain(WidgetTester tester) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(
      of: find.byType(AmountText),
      matching: find.byWidgetPredicate(
        (Widget w) => w is RichText && w.text.toPlainText().contains('₹'),
      ),
    ),
  );
  return rich.text.toPlainText();
}

/// The card's own Material (the first one under the AccountCard).
Material _cardMaterial(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(AccountCard), matching: find.byType(Material))
      .first,
);

void main() {
  testWidgets('shows type overline, balance and opening caption', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _card());
    expect(find.text('BANK'), findsOneWidget);
    expect(_amountPlain(tester), '₹1,23,456.00');
    expect(find.text('Opening ₹1,00,000.00'), findsOneWidget);
  });

  testWidgets('card is filled with the account colour and is 200pt tall', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _card());
    expect(_cardMaterial(tester).color, AppColors.accountSbi);
    expect(
      tester.getSize(find.byType(AccountCard)).height,
      AppSizes.accountCardHeight,
    );
  });

  testWidgets('side-tab is primaryDeep with the name in onDark', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _card(colour: 'accountAxis'));
    final ColoredBox tab = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(AccountCard),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(tab.color, AppColors.primaryDeep);
    final Text name = tester.widget<Text>(find.text('SBI'));
    expect(name.style?.color, AppColors.onDark);
    expect(name.style?.fontSize, AppTextStyles.bodyStrong.fontSize);
  });

  testWidgets('PF card: the side-tab is ink, not primaryDeep', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _card(name: 'PF', type: AccountType.pf, colour: 'accountPf'),
    );
    final Iterable<ColoredBox> boxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(AccountCard),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(boxes.map((ColoredBox b) => b.color), contains(AppColors.ink));
    expect(
      boxes.map((ColoredBox b) => b.color),
      isNot(contains(AppColors.primaryDeep)),
    );
    expect(_cardMaterial(tester).color, AppColors.accountPf);
  });

  testWidgets('negative balance shows a hyphen before the ₹ sign', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _card(
        name: 'Card',
        type: AccountType.card,
        colour: 'accountHand',
        balance: -50000,
      ),
    );
    expect(_amountPlain(tester), '-₹500.00');
  });

  testWidgets('archived account shows ARCHIVED in the overline', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _card(archived: true));
    expect(find.text('BANK · ARCHIVED'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'archived$')), findsOneWidget);
  });

  testWidgets('semantics label gives name, type, balance and opening', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _card());
    expect(
      find.bySemanticsLabel(
        'SBI, Bank, balance ₹1,23,456.00, opening ₹1,00,000.00',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tap calls onTap and the card is a button', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpCompact(tester, _card(onTap: () => taps++));
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('long name and large text (2.0) do not overflow', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _card(name: 'A very long account name here', balance: 987654321_00),
      textScale: 2,
      width: 300,
    );
    expect(tester.takeException(), isNull);
  });
}
