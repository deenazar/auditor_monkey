import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_values.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/owes_toggle.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/show_account_form_sheet.dart';
import 'package:auditor_monkey/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/screen_pump.dart';

/// Opens the sheet from a button, so Navigator.pop works as in the app.
Future<void> _open(
  WidgetTester tester,
  AccountFormSheet Function(BuildContext context) build,
) async {
  await pumpScreen(
    tester,
    Builder(
      builder: (BuildContext context) => Center(
        child: TextButton(
          onPressed: () => showAccountFormSheet(context, build(context)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  _tallSurface(tester);
  await tester.pump();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _name(WidgetTester tester, String text) async {
  await tester.enterText(
    find
        .descendant(
          of: find.byType(AccountFormSheet),
          matching: find.byType(TextField),
        )
        .first,
    text,
  );
  await tester.pump();
}

Finder _submit() => find.descendant(
  of: find.byType(AccountFormSheet),
  matching: find.byType(PrimaryButton),
);

/// Taps the sheet's button. The surface is tall enough that the whole sheet
/// (with the opening balance and "I owe" toggle) fits without scrolling.
Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(_submit());
}

/// A tall surface for the sheet tests (the sheet is taller than a phone).
void _tallSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(780, 2400)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('an empty name shows an error when Save is pressed', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Add account',
        submitLabel: 'Add account',
        otherNames: const <String>[],
        onSave: (AccountFormValues v) async => null,
      ),
    );
    await _tapSubmit(tester);
    await tester.pump();
    expect(find.text('Enter a name for this account.'), findsOneWidget);
    expect(find.byType(AccountFormSheet), findsOneWidget);
  });

  testWidgets('a name another account has shows the duplicate error', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Add account',
        submitLabel: 'Add account',
        otherNames: const <String>['SBI'],
        onSave: (AccountFormValues v) async => null,
      ),
    );
    await _name(tester, 'sbi');
    expect(
      find.text('You already have an account with this name.'),
      findsOneWidget,
    );
  });

  testWidgets('"I owe" only shows for a card and makes the balance negative', (
    WidgetTester tester,
  ) async {
    AccountFormValues? saved;
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Edit account',
        submitLabel: 'Save changes',
        otherNames: const <String>[],
        showOpeningBalance: true,
        initial: const AccountFormValues(
          name: 'Axis',
          type: AccountType.bank,
          colour: 'accountAxis',
        ),
        onSave: (AccountFormValues v) async {
          saved = v;
          return null;
        },
      ),
    );
    expect(find.byType(OwesToggle), findsNothing);
    await tester.tap(find.bySemanticsLabel('Card'));
    await tester.pump();
    expect(find.byType(OwesToggle), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('I owe'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Opening balance'),
        matching: find.byType(TextField),
      ),
      '4500',
    );
    await tester.pump();
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.type, AccountType.card);
    expect(saved!.owes, isTrue);
    expect(saved!.balanceText, '4500');
    expect(find.byType(AccountFormSheet), findsNothing);
  });

  testWidgets('switching away from card clears "I owe"', (
    WidgetTester tester,
  ) async {
    AccountFormValues? saved;
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Edit account',
        submitLabel: 'Save changes',
        otherNames: const <String>[],
        showOpeningBalance: true,
        initial: const AccountFormValues(
          name: 'Axis',
          type: AccountType.card,
          colour: 'accountAxis',
          owes: true,
          balanceText: '100',
        ),
        onSave: (AccountFormValues v) async {
          saved = v;
          return null;
        },
      ),
    );
    await tester.tap(find.bySemanticsLabel('Bank'));
    await tester.pump();
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(saved!.owes, isFalse);
  });

  testWidgets('a save error is shown under the field it belongs to', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Add account',
        submitLabel: 'Add account',
        otherNames: const <String>[],
        onSave: (AccountFormValues v) async =>
            const AccountFormError('Name is taken.', field: 'name'),
      ),
    );
    await _name(tester, 'New');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Name is taken.'), findsOneWidget);
    expect(find.byType(AccountFormSheet), findsOneWidget);
  });

  testWidgets('a general save error shows under the form', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Add account',
        submitLabel: 'Add account',
        otherNames: const <String>[],
        onSave: (AccountFormValues v) async =>
            const AccountFormError('Could not save. Please try again.'),
      ),
    );
    await _name(tester, 'New');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
  });

  testWidgets('Remove account calls onRemove and closes the sheet', (
    WidgetTester tester,
  ) async {
    int removed = 0;
    await _open(
      tester,
      (BuildContext c) => AccountFormSheet(
        title: 'Edit account',
        submitLabel: 'Save',
        otherNames: const <String>[],
        initial: const AccountFormValues(
          name: 'Gift',
          type: AccountType.wallet,
          colour: 'primary',
        ),
        onRemove: () => removed++,
        onSave: (AccountFormValues v) async => null,
      ),
    );
    await tester.tap(find.text('Remove account'));
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(find.byType(AccountFormSheet), findsNothing);
  });

  testWidgets('the sheet fits at text scale 2.0', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showAccountFormSheet(
            context,
            AccountFormSheet(
              title: 'Add account',
              submitLabel: 'Add account',
              otherNames: const <String>[],
              showOpeningBalance: true,
              onSave: (AccountFormValues v) async => null,
            ),
          ),
          child: const Text('open'),
        ),
      ),
      textScale: 2,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
