// Fixed data for goldens and widget tests. Every id is a fixed UUID so the
// screens look the same on every run. Money is paise.
import 'package:auditor_monkey/core/sync/sync_status.dart';
import 'package:auditor_monkey/features/accounts/application/account_statement_provider.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_notifier.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_state.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'golden.dart' show goldenClock;

/// A fixed account id (UUID v4 shape) by number, 1 to 9.
String fixtureId(int n) => '1111111$n-1111-4111-8111-11111111111$n';

Account fixtureAccount({
  required int n,
  required String name,
  AccountType type = AccountType.bank,
  String colour = 'accountSbi',
  int opening = 0,
  bool archived = false,
  int sortOrder = 0,
}) => Account(
  id: fixtureId(n),
  createdAt: 0,
  updatedAt: 0,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  name: name,
  type: type,
  colour: colour,
  openingBalance: opening,
  sortOrder: sortOrder,
  archived: archived,
);

AccountBalance fixtureBalance(Account account, int balance) =>
    AccountBalance(account: account, balance: balance);

/// The seven presets with the balances the goldens show. Axis is a card
/// with a debt, so one balance is negative.
List<AccountBalance> goldenAccounts() {
  final List<(Account, int)> rows = <(Account, int)>[
    (
      fixtureAccount(
        n: 1,
        name: 'Hand',
        type: AccountType.cash,
        colour: 'accountHand',
        opening: 125000,
        sortOrder: 0,
      ),
      125000,
    ),
    (
      fixtureAccount(
        n: 2,
        name: 'SBI',
        colour: 'accountSbi',
        opening: 24567850,
        sortOrder: 1,
      ),
      24567850,
    ),
    (
      fixtureAccount(
        n: 3,
        name: 'Axis',
        type: AccountType.card,
        colour: 'accountAxis',
        opening: -150000,
        sortOrder: 2,
      ),
      -150000,
    ),
    (
      fixtureAccount(
        n: 4,
        name: 'SCB',
        colour: 'accountScb',
        opening: 3821000,
        sortOrder: 3,
      ),
      3821000,
    ),
    (
      fixtureAccount(
        n: 5,
        name: 'Food Card',
        type: AccountType.wallet,
        colour: 'accountFoodCard',
        opening: 64000,
        sortOrder: 4,
      ),
      64000,
    ),
    (
      fixtureAccount(
        n: 6,
        name: 'Outside',
        type: AccountType.other,
        colour: 'accountOutside',
        opening: 1200000,
        sortOrder: 5,
      ),
      1200000,
    ),
    (
      fixtureAccount(
        n: 7,
        name: 'PF',
        type: AccountType.pf,
        colour: 'accountPf',
        opening: 48000000,
        sortOrder: 6,
      ),
      48000000,
    ),
  ];
  return <AccountBalance>[
    for (final (Account a, int b) in rows) fixtureBalance(a, b),
  ];
}

/// Net worth of [goldenAccounts].
int goldenNetWorth() => goldenAccounts().fold<int>(
  0,
  (int sum, AccountBalance b) => sum + b.balance,
);

/// The statement of the SBI account: opening 2,00,000.00, five lines.
/// Balances are computed oldest first, so the newest balance is the
/// balance card.
Account goldenSbi() => goldenAccounts()[1].account;

TransactionEntry fixtureEntry({
  required int n,
  required TransactionType type,
  required int amount,
  required String date,
  required String accountId,
  String? toAccountId,
  String? categoryId,
}) => TransactionEntry(
  id: '2222222$n-2222-4222-8222-22222222222$n',
  createdAt: n,
  updatedAt: n,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  type: type,
  amount: amount,
  date: date,
  accountId: accountId,
  toAccountId: toAccountId,
  categoryId: categoryId,
  note: null,
  loanId: null,
  importSource: null,
);

/// Five golden lines, newest first, with running balances for the SBI
/// opening balance of 2,00,000.00.
List<StatementLine> goldenLines() {
  final String acc = fixtureId(2);
  return <StatementLine>[
    StatementLine(
      entry: fixtureEntry(
        n: 5,
        type: TransactionType.expense,
        amount: 234050,
        date: '2026-11-11',
        accountId: acc,
      ),
      effect: -234050,
      balanceAfter: 27536050,
      categoryName: 'Groceries',
      categoryIcon: 'shopping-cart',
      categoryColourGroup: 'food',
    ),
    StatementLine(
      entry: fixtureEntry(
        n: 4,
        type: TransactionType.income,
        amount: 8500000,
        date: '2026-11-01',
        accountId: acc,
      ),
      effect: 8500000,
      balanceAfter: 27770100,
      categoryName: 'Salary',
      categoryIcon: 'briefcase',
      categoryColourGroup: 'income',
    ),
    StatementLine(
      entry: fixtureEntry(
        n: 3,
        type: TransactionType.transfer,
        amount: 500000,
        date: '2026-10-28',
        accountId: acc,
        toAccountId: fixtureId(3),
      ),
      effect: -500000,
      balanceAfter: 19270100,
      counterpartName: 'Axis',
    ),
    StatementLine(
      entry: fixtureEntry(
        n: 2,
        type: TransactionType.expense,
        amount: 180000,
        date: '2026-10-20',
        accountId: acc,
      ),
      effect: -180000,
      balanceAfter: 19770100,
      categoryName: 'Fuel',
      categoryIcon: 'fuel',
      categoryColourGroup: 'transport',
    ),
    StatementLine(
      entry: fixtureEntry(
        n: 1,
        type: TransactionType.expense,
        amount: 49900,
        date: '2025-12-30',
        accountId: acc,
      ),
      effect: -49900,
      balanceAfter: 19950100,
      categoryName: 'Entertainment & OTT',
      categoryIcon: 'tv',
      categoryColourGroup: 'lifestyle',
    ),
  ];
}

/// Six months of income and expense for the chart (oldest first).
List<MonthlyTotal> goldenMonths() => const <MonthlyTotal>[
  MonthlyTotal(month: '2026-06', income: 0, expense: 0),
  MonthlyTotal(month: '2026-07', income: 4200000, expense: 2900000),
  MonthlyTotal(month: '2026-08', income: 4200000, expense: 3100000),
  MonthlyTotal(month: '2026-09', income: 4200000, expense: 2600000),
  MonthlyTotal(month: '2026-10', income: 4200000, expense: 2300000),
  MonthlyTotal(month: '2026-11', income: 8500000, expense: 234050),
];

/// Six empty months (no entries).
List<MonthlyTotal> emptyMonths() => const <MonthlyTotal>[
  MonthlyTotal(month: '2026-06', income: 0, expense: 0),
  MonthlyTotal(month: '2026-07', income: 0, expense: 0),
  MonthlyTotal(month: '2026-08', income: 0, expense: 0),
  MonthlyTotal(month: '2026-09', income: 0, expense: 0),
  MonthlyTotal(month: '2026-10', income: 0, expense: 0),
  MonthlyTotal(month: '2026-11', income: 0, expense: 0),
];

/// The statement state of the SBI account with [lines] (newest first).
AccountStatementState goldenStatement({
  List<StatementLine>? lines,
  bool hasMore = false,
  bool loadingMore = false,
  bool loadMoreFailed = false,
}) => AccountStatementState(
  account: goldenSbi(),
  balance: (lines ?? goldenLines()).isEmpty ? 24567850 : 27536050,
  lines: lines ?? goldenLines(),
  hasMore: hasMore,
  loadingMore: loadingMore,
  loadMoreFailed: loadMoreFailed,
);

/// Wizard rows for the seven presets, all picked, with optional amounts.
List<WizardAccount> presetWizardAccounts({
  Map<String, String> amounts = const <String, String>{},
  Set<String> owes = const <String>{},
  Set<String> unpicked = const <String>{},
}) => <WizardAccount>[
  for (final AccountPreset p in accountPresets)
    WizardAccount(
      key: p.id,
      presetId: p.id,
      name: p.name,
      type: p.type,
      colour: p.colour,
      selected: !unpicked.contains(p.id),
      balanceText: amounts[p.id] ?? '',
      owes: owes.contains(p.id),
    ),
];

/// Overrides the wizard state with [state] (the notifier still works, so
/// taps change the state as in the app).
Override wizardStateOverride(SetupWizardState state) =>
    setupWizardProvider.overrideWithBuild((ref, notifier) => state);

/// Overrides the statement of every account with [state].
Override statementStateOverride(AccountStatementState state) =>
    accountStatementProvider.overrideWithBuild((ref, notifier) => state);

/// The clock value the goldens use.
int goldenNowMs() => goldenClock().nowMs();
