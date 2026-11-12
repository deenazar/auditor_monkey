// Plan 5.6: screenshots of the Quick Add sheet. Tag `golden`, Linux only.
// Masters: flutter test --tags golden --update-goldens (Flutter 3.47.9).
// Fixed seed: seven preset accounts, three fixed entries, clock 2026-11-12.
@Tags(<String>['golden'])
library;

import 'dart:async';

import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/logging/logger_provider.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_body.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_toast.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_providers.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_text_styles.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart';
import '../../../support/test_env.dart';
import 'quick_add_body_support.dart';

/// The database and logger of [env]. The clock comes from [goldenApp]
/// (2026-11-12, noon), so it is not added here (that would override twice).
List<Override> _dbOverrides(TestEnv env) => <Override>[
  appDatabaseProvider.overrideWithValue(env.db),
  loggerProvider.overrideWithValue(env.ctx.logger),
];

/// The seeded data every golden starts from: seven accounts, then three
/// fixed entries (an expense, an income and a transfer).
Future<List<Account>> _seed(TestEnv env) async {
  final List<Account> accounts = await sevenAccounts(env);
  final String groceries = await env.seededCategoryId('Groceries', 'expense');
  final String salary = await env.seededCategoryId('Salary', 'income');
  final List<TransactionDraft> entries = <TransactionDraft>[
    TransactionDraft(
      type: TransactionType.expense,
      amount: 25000,
      date: '2026-11-10',
      accountId: accounts[0].id,
      categoryId: groceries,
      note: 'Weekly vegetables',
    ),
    TransactionDraft(
      type: TransactionType.income,
      amount: 8500000,
      date: '2026-11-01',
      accountId: accounts[1].id,
      categoryId: salary,
    ),
    TransactionDraft(
      type: TransactionType.transfer,
      amount: 200000,
      date: '2026-11-09',
      accountId: accounts[0].id,
      toAccountId: accounts[2].id,
    ),
  ];
  for (int i = 0; i < entries.length; i++) {
    env.clock.now = DateTime(2026, 11, 10, 9, i).millisecondsSinceEpoch;
    await env.transactions.create(entries[i]);
  }
  env.clock.now = DateTime(2026, 11, 12, 10).millisecondsSinceEpoch;
  return accounts;
}

/// A repository whose create never completes (the saving state on screen).
class _NeverFinishingTransactions extends TransactionsRepository {
  _NeverFinishingTransactions(super.ctx);

  @override
  Future<TransactionEntry> create(TransactionDraft draft) =>
      Completer<TransactionEntry>().future;
}

/// Pumps the body in the golden app, lets the data load, then compares.
Future<void> _body(
  WidgetTester tester,
  TestEnv env,
  String name, {
  Future<void> Function(WidgetTester tester)? act,
  double textScale = 1,
  List<Override> extra = const <Override>[],
}) async {
  setGoldenSurface(tester);
  await tester.pumpWidget(
    goldenApp(
      sheetSized(const QuickAddBody()),
      overrides: <Override>[..._dbOverrides(env), ...extra],
      textScale: textScale,
    ),
  );
  await settleDb(tester);
  if (act != null) {
    await act(tester);
    await settleDb(tester);
  }
  await expectGolden(tester, name);
  await endTest(tester);
}

void main() {
  late TestEnv env;

  setUp(() => env = quickAddTestEnv());
  tearDown(() => env.close());

  testWidgets('quick_add_loading', (WidgetTester tester) async {
    await _seed(env);
    // No settle: the data is still loading, so the skeleton rows show.
    setGoldenSurface(tester);
    await tester.pumpWidget(
      goldenApp(sheetSized(const QuickAddBody()), overrides: _dbOverrides(env)),
    );
    await tester.pump();
    await expectGolden(tester, 'quick_add_loading');
    await endTest(tester);
  });

  testWidgets('quick_add_expense_empty', (WidgetTester tester) async {
    await _seed(env);
    await _body(tester, env, 'quick_add_expense_empty');
  });

  testWidgets('quick_add_expense_typing', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_expense_typing',
      act: (WidgetTester t) => typeKeys(t, '1250.5'),
    );
  });

  testWidgets('quick_add_amount_refused', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_amount_refused',
      act: (WidgetTester t) => typeKeys(t, '12.345'),
    );
  });

  testWidgets('quick_add_income', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_income',
      act: (WidgetTester t) async {
        await t.tap(find.text('Income'));
        await t.pump();
        await typeKeys(t, '1200.5');
      },
    );
  });

  testWidgets('quick_add_transfer', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_transfer',
      act: (WidgetTester t) async {
        await t.tap(find.text('Transfer'));
        await t.pump();
        await typeKeys(t, '2000');
      },
    );
  });

  testWidgets('quick_add_transfer_disabled', (WidgetTester tester) async {
    await env.account('Hand', opening: 100000);
    await _body(
      tester,
      env,
      'quick_add_transfer_disabled',
      act: (WidgetTester t) async {
        await t.tap(find.bySemanticsLabel('Transfer, needs two accounts'));
        await t.pump();
      },
    );
  });

  testWidgets('quick_add_recent_applied', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_recent_applied',
      act: (WidgetTester t) async {
        // Groceries is the third chip: scroll the strip to it first.
        await t.ensureVisible(recentChip('Groceries'));
        await t.pump();
        await t.tap(recentChip('Groceries'));
        await t.pump();
      },
    );
  });

  testWidgets('quick_add_saving', (WidgetTester tester) async {
    await _seed(env);
    setGoldenSurface(tester);
    await tester.pumpWidget(
      goldenApp(
        sheetSized(const QuickAddBody()),
        overrides: <Override>[
          ..._dbOverrides(env),
          // The save never finishes here, so the ring stays on screen.
          transactionsRepositoryProvider.overrideWithValue(
            _NeverFinishingTransactions(env.ctx),
          ),
        ],
      ),
    );
    await settleDb(tester);
    await typeKeys(tester, '250');
    await tester.tap(saveButton('Save expense'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(stateOf(tester).isSaving, isTrue);
    await expectGolden(tester, 'quick_add_saving');
    await endTest(tester);
  });

  testWidgets('quick_add_save_error', (WidgetTester tester) async {
    // No entries: the default account (the first one) can be deleted, so
    // the save fails after the data has loaded.
    final List<Account> accounts = await sevenAccounts(env);
    await _body(
      tester,
      env,
      'quick_add_save_error',
      act: (WidgetTester t) async {
        await typeKeys(t, '250');
        await env.accounts.softDelete(accounts[0].id);
        await t.tap(saveButton('Save expense'));
      },
    );
  });

  testWidgets('quick_add_no_categories', (WidgetTester tester) async {
    await _seed(env);
    await env.rawSql(
      "UPDATE categories SET archived = 1 WHERE kind = 'expense'",
    );
    await _body(
      tester,
      env,
      'quick_add_no_categories',
      act: (WidgetTester t) => typeKeys(t, '30'),
    );
  });

  testWidgets('quick_add_load_error', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_load_error',
      extra: <Override>[
        quickAddDataProvider.overrideWith(
          (Ref ref) => Future<QuickAddData>.error(StateError('boom')),
        ),
      ],
    );
  });

  testWidgets('quick_add_saved_toast', (WidgetTester tester) async {
    setGoldenSurface(tester);
    // The snack bar sets its own text style, which drops the test fallback
    // font for ₹. Give its content style the fallback here (test only).
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.copyWith(
          snackBarTheme: theme.snackBarTheme.copyWith(
            contentTextStyle: AppTextStyles.body.copyWith(
              color: AppColors.onDark,
              fontFamilyFallback: const <String>[rupeeFallbackFamily],
            ),
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  buildQuickAddToast(
                    message: 'Expense saved · ₹250.00',
                    onUndo: () {},
                  ),
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the toast hides itself after toastDuration.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectGolden(tester, 'quick_add_saved_toast');
    await endTest(tester);
  });

  testWidgets('quick_add_account_picker', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_account_picker',
      act: (WidgetTester t) async {
        await t.tap(accountPill('SBI'));
        await t.pumpAndSettle();
      },
    );
  });

  testWidgets('quick_add_all_categories', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_all_categories',
      act: (WidgetTester t) async {
        await t.tap(find.bySemanticsLabel('All categories'));
        await t.pumpAndSettle();
      },
    );
  });

  testWidgets('quick_add_note_sheet', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_note_sheet',
      act: (WidgetTester t) async {
        await t.tap(find.text('Add note'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), 'Lunch with Asha');
        await t.pump();
      },
    );
  });

  testWidgets('quick_add_date_picker', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_date_picker',
      act: (WidgetTester t) async {
        await t.tap(find.bySemanticsLabel('Pick another date'));
        await t.pumpAndSettle();
      },
    );
  });

  testWidgets('quick_add_textscale2', (WidgetTester tester) async {
    await _seed(env);
    await _body(
      tester,
      env,
      'quick_add_textscale2',
      textScale: 2,
      act: (WidgetTester t) => typeKeys(t, '250'),
    );
  });
}
