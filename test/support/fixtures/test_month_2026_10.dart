// The hand-checked test month of session 6 (docs/plans/session-6-dashboard.md,
// section 5). Built on an in-memory database through the REAL repositories,
// so the numbers the tests check come from the same code the app runs.
//
// Clock: 2026-10-31 12:00 local (today = the month's last day). Month M is
// 2026-10. Money is paise (₹ x 100).
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';

import '../test_env.dart';

/// Fixed clock of the test month: 2026-10-31 12:00 local.
final DateTime testMonthNow = DateTime(2026, 10, 31, 12);

/// The month the fixture is about (`YYYY-MM`).
const String testMonth = '2026-10';

/// The built test month. Every id is exposed, so tests can look rows up.
class TestMonth {
  const TestMonth._({
    required this.env,
    required this.accountIds,
    required this.txIds,
    required this.loanId,
    required this.categoryIds,
    required this.budgetIds,
  });

  /// The database and repositories the month was written through.
  final TestEnv env;

  /// Account id by name, archived accounts included (`Old Wallet`).
  final Map<String, String> accountIds;

  /// Transaction id by label `T01` to `T21` (soft-deleted `T19` included).
  final Map<String, String> txIds;

  /// Id of the loan "Ravi" (lent).
  final String loanId;

  /// Category id by name, from the seed.
  final Map<String, String> categoryIds;

  /// Budget id by `"<category name> <month>"`, e.g. `"Rent 2026-10"`.
  /// The Rent budget is soft-deleted.
  final Map<String, String> budgetIds;

  String account(String name) => accountIds[name]!;

  String tx(String label) => txIds[label]!;

  String category(String name) => categoryIds[name]!;

  String budget(String key) => budgetIds[key]!;

  Future<void> close() => env.close();
}

/// One account of plan section 5.1.
class _AccountSpec {
  const _AccountSpec(
    this.name,
    this.type,
    this.colour,
    this.opening, {
    this.presetName,
    this.archived = false,
  });

  final String name;
  final AccountType type;
  final String colour;
  final int opening;

  /// Name of the preset whose fixed id this account uses, if any.
  final String? presetName;
  final bool archived;
}

const List<_AccountSpec> _accounts = <_AccountSpec>[
  _AccountSpec(
    'Hand',
    AccountType.cash,
    'accountHand',
    500000,
    presetName: 'Hand',
  ),
  _AccountSpec(
    'SBI',
    AccountType.bank,
    'accountSbi',
    5000000,
    presetName: 'SBI',
  ),
  _AccountSpec(
    'Axis',
    AccountType.bank,
    'accountAxis',
    2000000,
    presetName: 'Axis',
  ),
  _AccountSpec(
    'Food Card',
    AccountType.wallet,
    'accountFoodCard',
    300000,
    presetName: 'Food Card',
  ),
  _AccountSpec('PF', AccountType.pf, 'accountPf', 10000000, presetName: 'PF'),
  _AccountSpec(
    'Outside',
    AccountType.other,
    'accountOutside',
    0,
    presetName: 'Outside',
  ),
  _AccountSpec('HDFC Card', AccountType.card, 'accountScb', -300000),
  _AccountSpec(
    'Old Wallet',
    AccountType.wallet,
    'accountHand',
    50000,
    archived: true,
  ),
];

/// One row of plan section 5.2.
class _Tx {
  const _Tx(
    this.label,
    this.type,
    this.date,
    this.amount,
    this.account, {
    this.to,
    this.category,
    this.loan = false,
    this.deleted = false,
  });

  final String label;
  final TransactionType type;
  final String date;
  final int amount;
  final String account;
  final String? to;
  final String? category;
  final bool loan;
  final bool deleted;
}

const List<_Tx> _transactions = <_Tx>[
  _Tx(
    'T01',
    TransactionType.expense,
    '2026-09-30',
    150000,
    'Hand',
    category: 'Groceries',
  ),
  _Tx(
    'T02',
    TransactionType.income,
    '2026-10-01',
    6000000,
    'SBI',
    category: 'Salary',
  ),
  _Tx(
    'T03',
    TransactionType.expense,
    '2026-10-01',
    1500000,
    'SBI',
    category: 'Rent',
  ),
  _Tx(
    'T04',
    TransactionType.expense,
    '2026-10-03',
    245050,
    'Hand',
    category: 'Groceries',
  ),
  _Tx('T05', TransactionType.transfer, '2026-10-05', 500000, 'SBI', to: 'Hand'),
  _Tx(
    'T06',
    TransactionType.expense,
    '2026-10-07',
    120000,
    'Food Card',
    category: 'Food & Dining',
  ),
  _Tx(
    'T07',
    TransactionType.expense,
    '2026-10-08',
    20000,
    'Old Wallet',
    category: 'Tea & Snacks',
  ),
  _Tx(
    'T08',
    TransactionType.expense,
    '2026-10-09',
    320000,
    'HDFC Card',
    category: 'Shopping',
  ),
  _Tx(
    'T09',
    TransactionType.income,
    '2026-10-10',
    120000,
    'HDFC Card',
    category: 'Refund / Cashback',
  ),
  _Tx(
    'T10',
    TransactionType.expense,
    '2026-10-12',
    1000000,
    'SBI',
    category: 'Loan Given',
    loan: true,
  ),
  _Tx(
    'T11',
    TransactionType.expense,
    '2026-10-14',
    185075,
    'Axis',
    category: 'Fuel',
  ),
  _Tx(
    'T12',
    TransactionType.expense,
    '2026-10-15',
    300000,
    'Hand',
    category: 'Groceries',
  ),
  _Tx(
    'T13',
    TransactionType.transfer,
    '2026-10-18',
    320000,
    'SBI',
    to: 'HDFC Card',
  ),
  _Tx(
    'T14',
    TransactionType.income,
    '2026-10-20',
    400000,
    'SBI',
    category: 'Loan Repayment Received',
    loan: true,
  ),
  _Tx(
    'T15',
    TransactionType.expense,
    '2026-10-22',
    95000,
    'Food Card',
    category: 'Food & Dining',
  ),
  _Tx(
    'T16',
    TransactionType.income,
    '2026-10-24',
    250000,
    'Axis',
    category: 'Business / Freelance',
  ),
  _Tx(
    'T17',
    TransactionType.expense,
    '2026-10-26',
    70000,
    'Hand',
    category: 'Tea & Snacks',
  ),
  _Tx(
    'T18',
    TransactionType.expense,
    '2026-10-28',
    120000,
    'Axis',
    category: 'Food & Dining',
  ),
  _Tx(
    'T19',
    TransactionType.expense,
    '2026-10-30',
    99900,
    'Hand',
    category: 'Groceries',
    deleted: true,
  ),
  _Tx(
    'T20',
    TransactionType.expense,
    '2026-10-31',
    154925,
    'Axis',
    category: 'Health & Medicine',
  ),
  _Tx(
    'T21',
    TransactionType.expense,
    '2026-11-01',
    80000,
    'SBI',
    category: 'Fuel',
  ),
];

/// Builds the test month on a fresh in-memory database.
///
/// The clock reads [testMonthNow] at the end. While rows are written it
/// moves one millisecond per row, so `created_at` follows the T01 to T21
/// order.
Future<TestMonth> buildTestMonth() async {
  final TestEnv env = TestEnv();
  final int base = testMonthNow.millisecondsSinceEpoch;
  env.clock.now = base;

  // 5.1 Accounts. Presets keep their fixed ids (account_presets.dart).
  final List<AccountDraft> drafts = <AccountDraft>[
    for (final _AccountSpec s in _accounts)
      AccountDraft(
        name: s.name,
        type: s.type,
        colour: s.colour,
        openingBalance: s.opening,
        archived: s.archived,
      ),
  ];
  final List<String?> fixedIds = <String?>[
    for (final _AccountSpec s in _accounts) _presetId(s.presetName),
  ];
  final List<Account> accounts = await env.accounts.createAll(
    drafts,
    fixedIds: fixedIds,
  );
  final Map<String, String> accountIds = <String, String>{
    for (final Account a in accounts) a.name: a.id,
  };

  // Seeded category ids, by name. Each name is unique within its kind.
  final Map<String, String> categoryIds = <String, String>{};
  for (final _Tx t in _transactions) {
    final String? name = t.category;
    if (name != null && !categoryIds.containsKey(name)) {
      categoryIds[name] = await env.seededCategoryId(name, t.type.name);
    }
  }

  // Loan "Ravi": lent, principal 10,000.00, started 2026-10-12.
  final Loan loan = await env.loans.create(
    const LoanDraft(
      direction: LoanDirection.lent,
      person: 'Ravi',
      principal: 1000000,
      startDate: '2026-10-12',
    ),
  );

  // 5.2 Transactions, in id order.
  final Map<String, String> txIds = <String, String>{};
  final List<String> toDelete = <String>[];
  for (int i = 0; i < _transactions.length; i++) {
    final _Tx t = _transactions[i];
    env.clock.now = base + i + 1;
    final TransactionEntry entry = await env.transactions.create(
      TransactionDraft(
        type: t.type,
        amount: t.amount,
        date: t.date,
        accountId: accountIds[t.account]!,
        toAccountId: t.to == null ? null : accountIds[t.to!],
        categoryId: t.category == null ? null : categoryIds[t.category!],
        loanId: t.loan ? loan.id : null,
      ),
    );
    txIds[t.label] = entry.id;
    if (t.deleted) toDelete.add(entry.id);
  }
  for (final String id in toDelete) {
    env.clock.now = base + _transactions.length + 1;
    await env.transactions.softDelete(id);
  }

  // 5.1 Budgets: three for 2026-10, Rent (soft-deleted) and September.
  env.clock.now = base + _transactions.length + 2;
  final Map<String, String> budgetIds = <String, String>{};
  Future<void> budget(String category, String month, int amount) async {
    final Budget b = await env.budgets.create(
      BudgetDraft(
        categoryId: categoryIds[category]!,
        month: month,
        amount: amount,
      ),
    );
    budgetIds['$category $month'] = b.id;
  }

  await budget('Groceries', testMonth, 600000);
  await budget('Food & Dining', testMonth, 400000);
  await budget('Fuel', testMonth, 300000);
  await budget('Rent', testMonth, 1000000);
  await env.budgets.softDelete(budgetIds['Rent $testMonth']!);
  await budget('Groceries', '2026-09', 9999900);

  env.clock.now = base;
  return TestMonth._(
    env: env,
    accountIds: accountIds,
    txIds: txIds,
    loanId: loan.id,
    categoryIds: categoryIds,
    budgetIds: budgetIds,
  );
}

/// Fixed id of the preset called [name], or `null` for a custom account.
String? _presetId(String? name) {
  if (name == null) return null;
  return accountPresets.firstWhere((AccountPreset p) => p.name == name).id;
}
