import 'dart:async';

import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/account_statement_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/accounts_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_card.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/accounts_loading_view.dart';
import 'package:auditor_monkey/features/setup/presentation/setup_wizard_screen.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
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

Future<void> _tapText(WidgetTester tester, String label) async {
  final Finder target = find.bySemanticsLabel(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWithEnv('shows the cards, the net worth and the list', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI', opening: 1000000);
    await env.account('Hand', type: AccountType.cash, opening: 25000);
    await pumpWithEnv(tester, env, const AccountsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('NET WORTH'), findsOneWidget);
    expect(find.text('All accounts'), findsOneWidget);
    expect(find.byType(AccountCard), findsWidgets);
    expect(find.bySemanticsLabel('SBI, balance ₹10,000.00'), findsWidgets);
    expect(find.text('Add account'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWithEnv('a new transaction changes the balance on screen', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    final Account sbi = await env.account('SBI', opening: 100000);
    await pumpWithEnv(tester, env, const AccountsScreen());
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('SBI, balance ₹1,000.00'), findsWidgets);

    await env.transactions.create(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 25050,
        date: '2026-11-12',
        accountId: sbi.id,
        categoryId: await env.seededCategoryId('Groceries', 'expense'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('SBI, balance ₹749.50'), findsWidgets);
    expect(find.bySemanticsLabel('SBI, balance ₹1,000.00'), findsNothing);
  });

  testWithEnv('archived accounts come last under ARCHIVED', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('Old Bank');
    final Account gone = await env.account('Closed Card');
    await env.accounts.update(
      gone.id,
      const AccountDraft(
        name: 'Closed Card',
        type: AccountType.bank,
        colour: 'accountSbi',
        archived: true,
      ),
    );
    await pumpWithEnv(tester, env, const AccountsScreen());
    await tester.pumpAndSettle();

    expect(find.text('ARCHIVED'), findsOneWidget);
    final double liveY = tester.getTopLeft(find.text('Old Bank').first).dy;
    final double archivedY = tester.getTopLeft(find.text('ARCHIVED')).dy;
    expect(archivedY, greaterThan(liveY));
  });

  testWithEnv('no accounts: empty state leads to the wizard', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await pumpRouted(tester, env, initial: '/accounts');
    await tester.pumpAndSettle();
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);

    await _tapText(tester, 'Set up accounts');
    expect(find.byType(SetupWizardScreen), findsOneWidget);
  });

  testWithEnv('tapping a card opens its statement', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI');
    await pumpRouted(tester, env);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AccountCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(AccountStatementScreen), findsOneWidget);
  });

  testWithEnv('tapping a row opens its statement too', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI');
    await pumpRouted(tester, env);
    await tester.pumpAndSettle();
    await _tapText(tester, 'SBI, balance ₹0.00');
    expect(find.byType(AccountStatementScreen), findsOneWidget);
  });

  testWithEnv('add account saves a new account after setup', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI');
    await pumpWithEnv(tester, env, const AccountsScreen());
    await tester.pumpAndSettle();
    await _tapText(tester, 'Add account');
    expect(find.byType(AccountFormSheet), findsOneWidget);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AccountFormSheet),
            matching: find.byType(TextField),
          )
          .first,
      'Gift Card',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AccountFormSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsNothing);
    expect(await env.count('accounts', liveOnly: true), 2);
  });

  testWithEnv('the loading state shows the skeleton', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await pumpScreen(
      tester,
      const AccountsScreen(),
      overrides: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) => StreamController<List<AccountBalance>>().stream,
        ),
        netWorthProvider.overrideWith((Ref ref) => Stream<int>.value(0)),
      ],
    );
    expect(find.byType(AccountsLoadingView), findsOneWidget);
  });

  testWithEnv('a failed load shows the error and Try again', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    int loads = 0;
    await pumpScreen(
      tester,
      const AccountsScreen(),
      overrides: <Override>[
        accountBalancesProvider.overrideWith((Ref ref) {
          loads++;
          return Stream<List<AccountBalance>>.error(const StorageFailure());
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text("We couldn't load your accounts"), findsOneWidget);
    final int before = loads;
    await _tapText(tester, 'Try again');
    expect(loads, greaterThan(before));
  });

  testWithEnv('an overflowing balance shows the plain message', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await pumpScreen(
      tester,
      const AccountsScreen(),
      overrides: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) =>
              Stream<List<AccountBalance>>.error(const OverflowFailure()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('A balance is too large to show'), findsOneWidget);
  });

  testWithEnv('large text (2.0) keeps the screen whole', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await pumpScreen(
      tester,
      const AccountsScreen(),
      overrides: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) => Stream.value(goldenAccounts()),
        ),
        netWorthProvider.overrideWith(
          (Ref ref) => Stream.value(goldenNetWorth()),
        ),
      ],
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWithEnv('Add account and each row are at least 44pt tall', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI');
    await pumpWithEnv(tester, env, const AccountsScreen());
    await tester.pumpAndSettle();
    final Finder add = find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(add.first).height, AppSizes.buttonHeight);
    final Size row = tester.getSize(
      find
          .descendant(
            of: find.bySemanticsLabel('SBI, balance ₹0.00'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(row.height, greaterThanOrEqualTo(44));
  });
}
