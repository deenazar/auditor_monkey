import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_type_chips.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

void main() {
  testWidgets('shows all six account types', (WidgetTester tester) async {
    await pumpCompact(
      tester,
      AccountTypeChips(selected: AccountType.bank, onChanged: (_) {}),
    );
    for (final String label in <String>[
      'Cash',
      'Bank',
      'Card',
      'Wallet',
      'PF',
      'Other',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('selected chip is primaryDeep and marked selected', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      AccountTypeChips(selected: AccountType.card, onChanged: (_) {}),
    );
    final AnimatedContainer chip = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.bySemanticsLabel('Card'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((chip.decoration! as BoxDecoration).color, AppColors.primaryDeep);
    final Semantics semantics = tester.widget<Semantics>(
      find.bySemanticsLabel('Card'),
    );
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.button, isTrue);
  });

  testWidgets('tapping a chip reports its type', (WidgetTester tester) async {
    final List<AccountType> picked = <AccountType>[];
    await pumpCompact(
      tester,
      AccountTypeChips(selected: AccountType.bank, onChanged: picked.add),
    );
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pump();
    expect(picked, <AccountType>[AccountType.wallet]);
  });

  testWidgets('chips are at least 44pt tall and wrap at large text', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      AccountTypeChips(selected: AccountType.cash, onChanged: (_) {}),
      textScale: 2,
      width: 240,
    );
    expect(tester.takeException(), isNull);
    final Size size = tester.getSize(
      find
          .descendant(
            of: find.bySemanticsLabel('PF'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
