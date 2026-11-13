@Tags(<String>['golden'])
library;

import 'dart:async';

import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/application/account_statement_provider.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/account_statement_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/accounts_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_card.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_colours.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/account_fixtures.dart';
import '../../../support/golden.dart';
import '../../../support/rupee_golden.dart';

/// Overrides for the Accounts screen with [balances] and a net worth.
List<Override> _accounts(List<AccountBalance> balances) => <Override>[
  accountBalancesProvider.overrideWith(
    (Ref ref) => Stream<List<AccountBalance>>.value(balances),
  ),
  netWorthProvider.overrideWith(
    (Ref ref) => Stream<int>.value(
      balances.fold<int>(0, (int sum, AccountBalance b) => sum + b.balance),
    ),
  ),
];

/// Overrides for the statement screen: [state] and six months of [months].
List<Override> _statement(
  AccountStatementState? state, {
  List<MonthlyTotal> months = const <MonthlyTotal>[],
  bool loadingMonths = false,
}) => <Override>[
  if (state != null) statementStateOverride(state),
  accountMonthlyTotalsProvider.overrideWith(
    (Ref ref, String id) => loadingMonths
        ? StreamController<List<MonthlyTotal>>().stream
        : Stream<List<MonthlyTotal>>.value(months),
  ),
];

void main() {
  testWidgets('golden: accounts_data', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const AccountsScreen(),
      'accounts_data',
      overrides: _accounts(goldenAccounts()),
    );
  });

  testWidgets('golden: accounts_loading', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const AccountsScreen(),
      'accounts_loading',
      overrides: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) => StreamController<List<AccountBalance>>().stream,
        ),
        netWorthProvider.overrideWith((Ref ref) => Stream<int>.value(0)),
      ],
    );
  });

  testWidgets('golden: accounts_empty_illustration', (
    WidgetTester tester,
  ) async {
    await pumpRupeeGolden(
      tester,
      const AccountsScreen(),
      'accounts_empty_illustration',
      overrides: _accounts(const <AccountBalance>[]),
    );
  });

  testWidgets('golden: accounts_error', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const AccountsScreen(),
      'accounts_error',
      overrides: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) =>
              Stream<List<AccountBalance>>.error(const StorageFailure()),
        ),
        netWorthProvider.overrideWith((Ref ref) => Stream<int>.value(0)),
      ],
    );
  });

  testWidgets('golden: accounts_data_textscale2', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const AccountsScreen(),
      'accounts_data_textscale2',
      overrides: _accounts(goldenAccounts()),
      textScale: 2,
    );
  });

  testWidgets('golden: statement_data', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      AccountStatementScreen(accountId: fixtureId(2)),
      'statement_data',
      overrides: _statement(goldenStatement(), months: goldenMonths()),
    );
  });

  testWidgets('golden: statement_empty_illustration', (
    WidgetTester tester,
  ) async {
    await pumpRupeeGolden(
      tester,
      AccountStatementScreen(accountId: fixtureId(2)),
      'statement_empty_illustration',
      overrides: _statement(
        goldenStatement(lines: const <StatementLine>[]),
        months: emptyMonths(),
      ),
    );
  });

  testWidgets('golden: statement_loading', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      AccountStatementScreen(accountId: fixtureId(2)),
      'statement_loading',
      overrides: <Override>[
        accountStatementProvider.overrideWithBuild(
          (Ref ref, notifier) => Completer<AccountStatementState>().future,
        ),
        accountMonthlyTotalsProvider.overrideWith(
          (Ref ref, String id) => StreamController<List<MonthlyTotal>>().stream,
        ),
      ],
    );
  });

  testWidgets('golden: statement_not_found', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const AccountStatementScreen(accountId: 'not-a-uuid'),
      'statement_not_found',
      overrides: _statement(null, months: emptyMonths()),
    );
  });

  testWidgets('golden: account_card_all_colours', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(
        goldenWidth * goldenPixelRatio,
        2400 * goldenPixelRatio,
      )
      ..devicePixelRatio = goldenPixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDisableShadows = false;
    await tester.pumpWidget(
      rupeeGoldenApp(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: <Widget>[
                for (final String token in accountColourTokens) ...<Widget>[
                  AccountCard(
                    name: accountColourName(token),
                    type: AccountType.bank,
                    colourToken: token,
                    balancePaise: 1234500,
                    openingPaise: 1000000,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectGolden(tester, 'account_card_all_colours');
  });

  testWidgets('golden: edit_account_sheet', (WidgetTester tester) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(
      rupeeGoldenApp(
        AccountStatementScreen(accountId: fixtureId(2)),
        overrides: <Override>[
          ..._statement(goldenStatement(), months: goldenMonths()),
          ..._accounts(goldenAccounts()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsOneWidget);
    await expectGolden(tester, 'edit_account_sheet');
  });

  testWidgets('golden: add_account_sheet', (WidgetTester tester) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(
      rupeeGoldenApp(
        const AccountsScreen(),
        overrides: _accounts(goldenAccounts()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsOneWidget);
    await expectGolden(tester, 'add_account_sheet');
  });
}
