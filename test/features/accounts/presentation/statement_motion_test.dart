import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/statement_row.dart';
import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/wow/tilt_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/db_screen.dart';
import '../../../support/test_env.dart';

Future<Account> _withEntry(TestEnv env) async {
  final Account sbi = await env.account('SBI', opening: 20000000);
  final String groceries = await env.seededCategoryId('Groceries', 'expense');
  await env.transactions.create(
    TransactionDraft(
      type: TransactionType.expense,
      amount: 234050,
      date: '2026-11-11',
      accountId: sbi.id,
      categoryId: groceries,
    ),
  );
  return sbi;
}

/// A tall phone, so the whole statement is on screen.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWithEnv('statement has the monkey, tilting cards and a preview', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await _withEntry(env);
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    _tall(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AuditorMonkey), findsOneWidget);
    expect(find.byType(Tilt3D), findsNWidgets(2));

    await tester.longPress(find.text('Groceries'));
    await tester.pumpAndSettle();
    // The row shows twice: in the list and in the preview card.
    expect(find.byType(StatementRow), findsNWidgets(2));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(StatementRow), findsOneWidget);
  });

  testWithEnv('swipe left deletes a statement line; Undo restores it', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await _withEntry(env);
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    _tall(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Groceries'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(await env.count('transactions', liveOnly: true), 0);
    expect(find.text('Entry removed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(await env.count('transactions', liveOnly: true), 1);
  });
}
