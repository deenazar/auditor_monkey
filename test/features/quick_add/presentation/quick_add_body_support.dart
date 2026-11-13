// Shared helpers for the Quick Add body tests and goldens: the body in a
// phone-sized scaffold, real database settling, pad and widget finders, and
// the saved rows read back from the in-memory database.
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_notifier.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_view.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_body.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/account_pill.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/category_chip.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/num_pad_key.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/recent_entries_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/db_screen.dart' show pumpWithEnv;
import '../../../support/test_env.dart';

export '../../../support/quick_add_env.dart'
    show quickAddTestEnv, threeAccounts;

/// The body inside a phone-sized sheet (92% of the height, bottom aligned).
Widget sheetSized(Widget body) => Scaffold(
  body: Align(
    alignment: Alignment.bottomCenter,
    child: FractionallySizedBox(heightFactor: 0.92, child: body),
  ),
);

/// Pumps the Quick Add body on the phone surface with the database of [env].
Future<void> pumpBody(
  WidgetTester tester,
  TestEnv env, {
  double textScale = 1,
  bool reduceMotion = true,
  List<Override> extra = const <Override>[],
}) => pumpWithEnv(
  tester,
  env,
  sheetSized(const QuickAddBody()),
  extra: extra,
  textScale: textScale,
  reduceMotion: reduceMotion,
);

/// Lets the real database work finish, then plays the animations. A plain
/// pumpAndSettle does not wait for the database.
Future<void> settleDb(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Removes the tree so streams close and no timer is left.
Future<void> endTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

/// The pad key with [label] ("1", "point", "delete"...).
Finder padKey(String label) =>
    find.byWidgetPredicate((Widget w) => w is NumPadKey && w.label == label);

/// Taps the pad keys for [keys] ('.' is the point).
Future<void> typeKeys(WidgetTester tester, String keys) async {
  for (final String k in keys.split('')) {
    await tester.tap(padKey(k == '.' ? 'point' : k));
    await tester.pump();
  }
}

/// A category chip by its name.
Finder categoryChip(String name) =>
    find.byWidgetPredicate((Widget w) => w is CategoryChip && w.name == name);

/// A recent chip by its label.
Finder recentChip(String label) => find.byWidgetPredicate(
  (Widget w) => w is RecentEntryChip && w.entry.label == label,
);

/// The account pill showing [name].
Finder accountPill(String name) => find.byWidgetPredicate(
  (Widget w) => w is AccountPill && w.account?.name == name,
);

/// The Save button (its label is "Save expense", "Save income" or
/// "Save transfer").
Finder saveButton(String label) => find.text(label);

/// The live state of the notifier in the body's scope.
QuickAddState stateOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(QuickAddBody)))
        .read(quickAddProvider);

/// The view of the body's scope.
QuickAddView viewOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(QuickAddBody)))
        .read(quickAddViewProvider);

/// The live (not deleted) rows of the transactions table, oldest first.
Future<List<Map<String, Object?>>> savedRows(TestEnv env) async {
  final rows = await env.db
      .customSelect(
        'SELECT id, type, amount, date, account_id, to_account_id, '
        'category_id, note FROM transactions WHERE deleted_at IS NULL '
        'ORDER BY created_at, id',
      )
      .get();
  return <Map<String, Object?>>[for (final r in rows) r.data];
}

/// Creates the seven preset accounts of the design (fixed names and order).
Future<List<Account>> sevenAccounts(TestEnv env) async {
  const List<(String, String, int)> specs = <(String, String, int)>[
    ('SBI', 'accountSbi', 27536050),
    ('SCB', 'accountScb', 4520000),
    ('Axis', 'accountAxis', 1200000),
    ('Hand', 'accountHand', 180000),
    ('Food Card', 'accountFoodCard', 0),
    ('Outside', 'accountOutside', 350000),
    ('PF', 'accountPf', 80000000),
  ];
  final List<Account> out = <Account>[];
  for (final (String name, String colour, int opening) in specs) {
    out.add(
      await env.accounts.create(
        AccountDraft(
          name: name,
          type: AccountType.bank,
          colour: colour,
          openingBalance: opening,
          sortOrder: out.length,
        ),
      ),
    );
  }
  return out;
}
