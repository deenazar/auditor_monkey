// Plan 5.5: the Quick Add body with an in-memory database and a fixed clock
// (2026-11-12 10:00). Saves are checked in the database, not only on screen.
import 'dart:ui' show Tristate;

import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/account_pill.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/all_categories_sheet.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/amount_display.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/note_sheet.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/save_error_card.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';
import 'quick_add_body_support.dart';

void main() {
  late TestEnv env;

  setUp(() => env = quickAddTestEnv());
  tearDown(() => env.close());

  testWidgets('the pad works before the data arrives', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    await typeKeys(tester, '5');
    expect(find.bySemanticsLabel('₹5'), findsOneWidget);
    expect(stateOf(tester).amount.text, '5');
    await settleDb(tester);
    await endTest(tester);
  });

  testWidgets('expense in three steps: amount, Save, one row in the DB', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);

    await typeKeys(tester, '250');
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);

    final List<Map<String, Object?>> rows = await savedRows(env);
    expect(rows, hasLength(1));
    expect(rows.single['type'], 'expense');
    expect(rows.single['amount'], 25000);
    expect(rows.single['date'], '2026-11-12');
    expect(stateOf(tester).status, SaveStatus.done);
    await endTest(tester);
  });

  testWidgets('income: the Income tab saves an income row', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 0);
    await pumpBody(tester, env);
    await settleDb(tester);

    await tester.tap(find.text('Income'));
    await tester.pump();
    await typeKeys(tester, '1200.5');
    expect(find.text('Save income'), findsOneWidget);
    await tester.tap(saveButton('Save income'));
    await settleDb(tester);

    final List<Map<String, Object?>> rows = await savedRows(env);
    expect(rows.single['type'], 'income');
    expect(rows.single['amount'], 120050);
    await endTest(tester);
  });

  testWidgets('transfer: From and To from the defaults, one transfer row', (
    WidgetTester tester,
  ) async {
    final List<Account> accounts = await threeAccounts(env);
    await pumpBody(tester, env);
    await settleDb(tester);

    await tester.tap(find.text('Transfer'));
    await settleDb(tester);
    await typeKeys(tester, '2000');
    await tester.tap(saveButton('Save transfer'));
    await settleDb(tester);

    final Map<String, Object?> row = (await savedRows(env)).single;
    expect(row['type'], 'transfer');
    expect(row['amount'], 200000);
    expect(row['account_id'], isNot(row['to_account_id']));
    expect(
      <Object?>[
        row['account_id'],
        row['to_account_id'],
      ].every((Object? id) => accounts.any((Account a) => a.id == id)),
      isTrue,
    );
    await endTest(tester);
  });

  testWidgets('repeat a recent entry: tap the chip, Save, two rows', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);
    await typeKeys(tester, '250');
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);
    await endTest(tester);

    // A fresh sheet: the saved entry is now a recent chip.
    await pumpBody(tester, env);
    await settleDb(tester);
    expect(recentChip('Groceries'), findsOneWidget);
    await tester.tap(recentChip('Groceries'));
    await tester.pump();
    expect(find.bySemanticsLabel('₹250'), findsOneWidget);
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);

    final List<Map<String, Object?>> rows = await savedRows(env);
    expect(rows, hasLength(2));
    expect(rows.last['amount'], 25000);
    expect(rows.last['category_id'], rows.first['category_id']);
    await endTest(tester);
  });

  testWidgets('Save is off for an empty and for a zero amount', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);

    SemanticsNode save() =>
        tester.getSemantics(find.bySemanticsLabel('Save expense'));
    expect(save().flagsCollection.isEnabled, Tristate.isFalse);
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);
    expect(await savedRows(env), isEmpty);

    await typeKeys(tester, '0.00');
    expect(save().flagsCollection.isEnabled, Tristate.isFalse);
    await endTest(tester);
  });

  testWidgets('refused digits show the hint and the buffer stays', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    await typeKeys(tester, '12.345');
    expect(stateOf(tester).amount.text, '12.34');
    expect(find.text('Only 2 decimal places'), findsOneWidget);
    expect(stateOf(tester).refusalCount, 1);
    await settleDb(tester);
    await endTest(tester);
  });

  testWidgets('a double tap on Save saves one row', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);
    await typeKeys(tester, '250');
    await tester.tap(saveButton('Save expense'));
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);
    expect(await savedRows(env), hasLength(1));
    await endTest(tester);
  });

  testWidgets(
    'a forced save failure shows the error card and keeps the fields',
    (WidgetTester tester) async {
      final Account hand = await env.account('Hand', opening: 100000);
      await pumpBody(tester, env);
      await settleDb(tester);
      await typeKeys(tester, '250');
      // The account goes away after the data loaded: the save must fail.
      await env.accounts.softDelete(hand.id);
      await tester.tap(saveButton('Save expense'));
      await settleDb(tester);

      expect(find.byType(SaveErrorCard), findsOneWidget);
      expect(stateOf(tester).saveError, isNotEmpty);
      expect(find.bySemanticsLabel('₹250'), findsOneWidget);
      expect(await savedRows(env), isEmpty);
      await endTest(tester);
    },
  );

  testWidgets('Transfer with one account is disabled and shows the hint', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);

    expect(
      find.bySemanticsLabel('Transfer, needs two accounts'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Transfer, needs two accounts'));
    await settleDb(tester);
    expect(
      find.text('Add a second account to move money between accounts.'),
      findsOneWidget,
    );
    expect(stateOf(tester).type, TransactionType.expense);
    await endTest(tester);
  });

  testWidgets('the To picker disables From, and swap exchanges the sides', (
    WidgetTester tester,
  ) async {
    final List<Account> accounts = await threeAccounts(env);
    final Account axis = accounts[2];
    await pumpBody(tester, env);
    await settleDb(tester);
    await tester.tap(find.text('Transfer'));
    await settleDb(tester);
    final String? from = viewOf(tester).current.accountId;
    expect(from, isNotNull);

    // Open the To picker from the To pill.
    await tester.tap(
      find.byWidgetPredicate(
        (Widget w) =>
            w is AccountPill &&
            w.account != null &&
            w.account!.id == viewOf(tester).current.toAccountId,
      ),
    );
    await settleDb(tester);
    final SemanticsNode fromRow = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Hand, balance')).last,
    );
    expect(fromRow.flagsCollection.isEnabled, Tristate.isFalse);

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Axis, balance')));
    await settleDb(tester);
    expect(viewOf(tester).current.toAccountId, axis.id);
    expect(viewOf(tester).current.accountId, from);

    await tester.tap(find.bySemanticsLabel('Swap from and to accounts'));
    await settleDb(tester);
    expect(viewOf(tester).current.accountId, axis.id);
    expect(viewOf(tester).current.toAccountId, from);
    await endTest(tester);
  });

  testWidgets('date chips: Yesterday and the calendar pick a day that saves', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);

    await tester.tap(find.text('Yesterday'));
    await tester.pump();
    expect(stateOf(tester).date, '2026-11-11');

    await tester.tap(find.bySemanticsLabel('Pick another date'));
    await settleDb(tester);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(GridView), matching: find.text('5')),
    );
    await tester.tap(find.text('OK'));
    await settleDb(tester);
    expect(stateOf(tester).date, '2026-11-05');
    expect(find.text('5 Nov'), findsOneWidget);

    await typeKeys(tester, '40');
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);
    expect((await savedRows(env)).single['date'], '2026-11-05');
    await endTest(tester);
  });

  testWidgets('the note sheet: counter from 180, the note is trimmed on Done', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    await settleDb(tester);
    await tester.tap(find.text('Add note'));
    await settleDb(tester);
    expect(find.byType(NoteSheet), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  ${'x' * 179}');
    await tester.pump();
    expect(find.text('180/200'), findsNothing);
    await tester.enterText(find.byType(TextField), 'x' * 180);
    await tester.pump();
    expect(find.text('180/200'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'y' * 250);
    await tester.pump();
    expect(find.text('200/200'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text.length,
      200,
    );

    await tester.tap(find.text('Done'));
    await settleDb(tester);
    expect(stateOf(tester).note.length, 200);
    expect(stateOf(tester).note, 'y' * 200);
    await endTest(tester);
  });

  testWidgets('loan categories are never shown, also in the full list', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    await settleDb(tester);
    await tester.tap(find.bySemanticsLabel('All categories'));
    await settleDb(tester);
    expect(find.byType(AllCategoriesSheet), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    for (final String loan in <String>[
      'Loan Given',
      'Loan Repayment',
      'Loan Received',
      'Loan Repayment Received',
    ]) {
      expect(find.text(loan), findsNothing, reason: loan);
    }
    await endTest(tester);
  });

  testWidgets('text scale 2.0: the body lays out without overflow', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env, textScale: 2);
    await settleDb(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Save expense'), findsOneWidget);
    await endTest(tester);
  });

  testWidgets('reduce motion: the chips have zero animation time', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await pumpBody(tester, env);
    await settleDb(tester);
    final AnimatedContainer chip = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    expect(chip.duration, Duration.zero);
    expect(AppMotion.durationFast, isNot(Duration.zero));
    await endTest(tester);
  });

  testWidgets('amount display shows the typed amount grouped', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    await typeKeys(tester, '1250.5');
    expect(find.bySemanticsLabel('₹1,250.5'), findsOneWidget);
    expect(find.byType(AmountDisplay), findsOneWidget);
    await settleDb(tester);
    await endTest(tester);
  });
}
