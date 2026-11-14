// Fixed Home data for widget tests and goldens (golden "now" is
// 2026-11-12 noon). Money is paise.
import 'package:auditor_monkey/core/sync/sync_status.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/application/categories_providers.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/home/application/dashboard_providers.dart';
import 'package:auditor_monkey/features/home/application/home_providers.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/home/domain/home_summary.dart';
import 'package:auditor_monkey/features/home/domain/top_categories.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'account_fixtures.dart';

Category homeCategory(
  int n,
  String name,
  CategoryColourGroup group,
  String icon, {
  CategoryKind kind = CategoryKind.expense,
}) => Category(
  id: '2222222$n-2222-4222-8222-22222222222$n',
  createdAt: 0,
  updatedAt: 0,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  name: name,
  kind: kind,
  colourGroup: group,
  icon: icon,
  sortOrder: n,
  archived: false,
);

final List<Category> homeExpenseCategories = <Category>[
  homeCategory(1, 'Groceries', CategoryColourGroup.essentials, 'shopping-cart'),
  homeCategory(2, 'Food', CategoryColourGroup.food, 'utensils'),
  homeCategory(3, 'Fuel', CategoryColourGroup.transport, 'fuel'),
];

final List<Category> homeIncomeCategories = <Category>[
  homeCategory(
    4,
    'Salary',
    CategoryColourGroup.income,
    'briefcase',
    kind: CategoryKind.income,
  ),
];

final List<Account> homeAccounts = <Account>[
  fixtureAccount(n: 1, name: 'Hand', type: AccountType.cash),
  fixtureAccount(n: 2, name: 'SBI'),
];

TransactionEntry homeEntry(
  int n,
  TransactionType type,
  int amount,
  String date, {
  String? category,
  String? note,
  int account = 1,
  int? toAccount,
}) => TransactionEntry(
  id: '3333333$n-3333-4333-8333-33333333333$n',
  createdAt: n,
  updatedAt: n,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  type: type,
  amount: amount,
  date: date,
  accountId: fixtureId(account),
  toAccountId: toAccount == null ? null : fixtureId(toAccount),
  categoryId: category,
  note: note,
  loanId: null,
  importSource: null,
);

/// Nine days of spending ending 2026-11-12 and a few entries.
HomeSummary homeSummary({int monthSpent = 1854000, int monthIncome = 8500000}) {
  const List<int> spent = <int>[
    42000,
    0,
    185000,
    64000,
    120000,
    9900,
    310000,
    76000,
    48500,
  ];
  return HomeSummary(
    today: '2026-11-12',
    days: <DaySpend>[
      for (int i = 0; i < 9; i++)
        DaySpend(
          date: '2026-11-${(i + 4).toString().padLeft(2, '0')}',
          spent: spent[i],
        ),
    ],
    monthSpent: monthSpent,
    monthIncome: monthIncome,
    recent: <TransactionEntry>[
      homeEntry(
        1,
        TransactionType.expense,
        32000,
        '2026-11-12',
        category: homeExpenseCategories[0].id,
        note: 'Milk and bread',
      ),
      homeEntry(
        2,
        TransactionType.expense,
        16500,
        '2026-11-12',
        category: homeExpenseCategories[1].id,
      ),
      homeEntry(
        3,
        TransactionType.transfer,
        500000,
        '2026-11-11',
        account: 2,
        toAccount: 1,
      ),
      homeEntry(
        4,
        TransactionType.income,
        8500000,
        '2026-11-10',
        category: homeIncomeCategories[0].id,
        account: 2,
      ),
      homeEntry(
        5,
        TransactionType.expense,
        310000,
        '2026-11-10',
        category: homeExpenseCategories[2].id,
        account: 2,
      ),
    ],
  );
}

/// The Dashboard numbers for [summary] (same spent, income, days and
/// recent rows), plus a [budget] total. Top categories come from the
/// expense rows of `recent` (loan rows do not exist in these fixtures).
DashboardSummary homeDashboard(HomeSummary summary, {int budget = 0}) {
  final Map<String, int> byCategory = <String, int>{};
  for (final TransactionEntry e in summary.recent) {
    final String? c = e.categoryId;
    if (e.type == TransactionType.expense && c != null) {
      byCategory[c] = (byCategory[c] ?? 0) + e.amount;
    }
  }
  return DashboardSummary(
    today: summary.today,
    month: summary.today.substring(0, 7),
    days: summary.days,
    spent: summary.monthSpent,
    income: summary.monthIncome,
    budgetTotal: budget,
    topCategories: topCategoryShares(<CategoryTotal>[
      for (final MapEntry<String, int> m in byCategory.entries)
        CategoryTotal(categoryId: m.key, total: m.value),
    ], summary.monthSpent),
    recent: summary.recent,
  );
}

/// Account balances that add up to the net worth below (Hand + SBI).
final List<AccountBalance> homeBalances = <AccountBalance>[
  AccountBalance(account: homeAccounts[0], balance: 184300),
  AccountBalance(account: homeAccounts[1], balance: 12500000),
];

/// Overrides that feed Home without a database.
List<Override> homeOverrides(
  HomeSummary summary, {
  int budget = 0,
  List<AccountBalance>? balances,

  /// False leaves out the dashboard / balances override, so a test can
  /// supply its own (a provider cannot be overridden twice).
  bool dashboard = true,
  bool withBalances = true,
}) => <Override>[
  if (dashboard)
    dashboardSummaryProvider.overrideWith(
      (Ref ref) => Stream<DashboardSummary>.value(
        homeDashboard(summary, budget: budget),
      ),
    ),
  if (withBalances)
    accountBalancesProvider.overrideWith(
      (Ref ref) => Stream<List<AccountBalance>>.value(balances ?? homeBalances),
    ),
  monthBudgetTotalProvider.overrideWithValue(AsyncData<int>(budget)),
  expenseCategoriesProvider.overrideWith(
    (Ref ref) => Stream<List<Category>>.value(homeExpenseCategories),
  ),
  incomeCategoriesProvider.overrideWith(
    (Ref ref) => Stream<List<Category>>.value(homeIncomeCategories),
  ),
  accountsProvider.overrideWith(
    (Ref ref) => Stream<List<Account>>.value(homeAccounts),
  ),
  netWorthProvider.overrideWith((Ref ref) => Stream<int>.value(12684300)),
];

/// A first-day Home: nothing spent, no entries.
HomeSummary emptyHomeSummary() => HomeSummary(
  today: '2026-11-12',
  days: <DaySpend>[
    for (int i = 4; i <= 12; i++)
      DaySpend(date: '2026-11-${i.toString().padLeft(2, '0')}', spent: 0),
  ],
  monthSpent: 0,
  monthIncome: 0,
  recent: const <TransactionEntry>[],
);
