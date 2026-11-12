import 'package:auditor_monkey/features/accounts/application/account_statement_provider.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/account_statement_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/statement_row.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/widgets/empty_state.dart';
import 'package:auditor_monkey/shared/widgets/error_state.dart';
import 'package:auditor_monkey/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/account_fixtures.dart';
import '../../../support/db_screen.dart';
import '../../../support/screen_pump.dart';
import '../../../support/test_env.dart';

void main() {
  testWithEnv('shows the header, balance card, lines and the opening row', (
    WidgetTester tester,
    TestEnv env,
  ) async {
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
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('SBI'), findsWidgets);
    expect(find.text('BALANCE'), findsOneWidget);
    expect(find.text('Statement'), findsOneWidget);
    expect(find.byType(StatementRow), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Opening balance'), findsOneWidget);
    expect(find.text('INCOME VS EXPENSE'), findsOneWidget);
    // Balance = opening 2,00,000.00 less the 2,340.50 expense.
    expect(
      find.bySemanticsLabel('Opening balance, starting amount'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^Groceries, expense')),
      findsOneWidget,
    );
  });

  testWithEnv('an account with no entries shows the empty messages', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await env.account('SBI', opening: 100000);
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    await tester.pumpAndSettle();
    expect(find.text('Entries you add with + show here.'), findsOneWidget);
    expect(
      find.text('No income or expense in the last 6 months'),
      findsOneWidget,
    );
    expect(find.text('Opening balance'), findsOneWidget);
  });

  testWithEnv('an unknown or malformed id shows "not available"', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await pumpRouted(tester, env, initial: '/accounts/not-a-uuid');
    await tester.pumpAndSettle();
    expect(find.text("This account isn't available"), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Back to Accounts'), findsOneWidget);
  });

  testWithEnv('scrolling to the end loads the next page of 50', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await env.account('SBI', opening: 1000000);
    final String food = await env.seededCategoryId('Food & Dining', 'expense');
    for (int i = 0; i < 60; i++) {
      await env.transactions.create(
        TransactionDraft(
          type: TransactionType.expense,
          amount: 100 + i,
          date: '2026-11-${((i % 28) + 1).toString().padLeft(2, '0')}',
          accountId: sbi.id,
          categoryId: food,
        ),
      );
    }
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    await tester.pumpAndSettle();

    ProviderContainer container() => ProviderScope.containerOf(
      tester.element(find.byType(AccountStatementScreen)),
    );
    expect(
      container().read(accountStatementProvider(sbi.id)).value!.lines.length,
      50,
    );

    for (int i = 0; i < 6; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();
    }
    expect(
      container().read(accountStatementProvider(sbi.id)).value!.lines.length,
      60,
    );
    expect(
      container().read(accountStatementProvider(sbi.id)).value!.showOpeningRow,
      isTrue,
    );
  });

  testWidgets('a failed next page shows "Try again" in the footer', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const AccountStatementScreen(accountId: 'x'),
      overrides: <Override>[
        statementStateOverride(
          goldenStatement(hasMore: true, loadMoreFailed: true),
        ),
        accountMonthlyTotalsProvider.overrideWith(
          (Ref ref, String id) => Stream.value(goldenMonths()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load more. Try again"), findsOneWidget);
  });

  testWidgets('a failed load shows the error with Try again', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const AccountStatementScreen(accountId: 'x'),
      overrides: <Override>[
        accountStatementProvider.overrideWithBuild(
          (Ref ref, notifier) => throw const StorageFailureForTest(),
        ),
        accountMonthlyTotalsProvider.overrideWith(
          (Ref ref, String id) => Stream.value(goldenMonths()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text("We couldn't load this statement"), findsOneWidget);
  });

  testWithEnv('edit account renames it and the header follows', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await env.account('SBI', opening: 100000);
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsOneWidget);
    final Finder nameField = find.descendant(
      of: find.bySemanticsLabel('Name'),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(nameField).controller!.text, 'SBI');
    await tester.enterText(nameField, 'SBI Gold');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AccountFormSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AccountFormSheet), findsNothing);
    expect(find.text('SBI Gold'), findsWidgets);
    final Map<String, Object?> row = await env.rawRow('accounts', sbi.id);
    expect(row['name'], 'SBI Gold');
  });

  testWithEnv('the statement reads the balance shown on its card', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await env.account('SBI', opening: 50000);
    final String food = await env.seededCategoryId('Food & Dining', 'expense');
    await env.transactions.create(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 20000,
        date: '2026-11-12',
        accountId: sbi.id,
        categoryId: food,
      ),
    );
    await pumpRouted(tester, env, initial: '/accounts/${sbi.id}');
    await tester.pumpAndSettle();
    final AccountStatementState state = ProviderScope.containerOf(
      tester.element(find.byType(AccountStatementScreen)),
    ).read(accountStatementProvider(sbi.id)).value!;
    expect(state.balance, 30000);
    expect(find.bySemanticsLabel('₹300.00'), findsOneWidget);
  });

  testWidgets('large text (2.0) and reduce motion keep the screen whole', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const AccountStatementScreen(accountId: 'x'),
      overrides: <Override>[
        statementStateOverride(goldenStatement()),
        accountMonthlyTotalsProvider.overrideWith(
          (Ref ref, String id) => Stream.value(goldenMonths()),
        ),
      ],
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// A failure that is not a DataFailure, to reach the generic error view.
class StorageFailureForTest implements Exception {
  const StorageFailureForTest();
}
