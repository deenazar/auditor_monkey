// Fixed data and fakes for the Transactions screen tests and goldens. No
// database: every provider the screens read is overridden here. Money is
// paise. The golden "now" is 2026-11-12 noon (see support/golden.dart).
import 'dart:async';

import 'package:auditor_monkey/core/sync/sync_status.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/application/categories_providers.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_providers.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_state.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../support/account_fixtures.dart';
import '../../../support/home_fixtures.dart';

/// Account ids used by the fixtures.
final String sbiId = fixtureId(2);
final String handId = fixtureId(1);
final String axisId = fixtureId(3);

/// Accounts with their colour tokens.
final List<Account> txAccounts = <Account>[
  fixtureAccount(
    n: 1,
    name: 'Hand',
    type: AccountType.cash,
    colour: 'accountHand',
  ),
  fixtureAccount(n: 2, name: 'SBI', colour: 'accountSbi'),
  fixtureAccount(n: 3, name: 'Axis', colour: 'accountOutside'),
];

/// Expense categories (Groceries, Food, Fuel) from the Home fixtures.
final List<Category> txExpenseCategories = homeExpenseCategories;
final List<Category> txIncomeCategories = homeIncomeCategories;

TransactionEntry _entry({
  required int n,
  required TransactionType type,
  required int amount,
  required String date,
  required String accountId,
  String? toAccountId,
  String? categoryId,
  String? note,
  int? createdAt,
}) {
  // Realistic stamps: created during the morning of the entry's day, and
  // some edited two hours later.
  final int created =
      createdAt ??
      DateTime(2026, 11, 12, 9, 30).millisecondsSinceEpoch + n * 1800000;
  return TransactionEntry(
    id: '5555555$n-5555-4555-8555-55555555555$n',
    createdAt: created,
    updatedAt: n.isEven ? created : created + 7200000,
    deletedAt: null,
    syncStatus: SyncStatus.synced,
    type: type,
    amount: amount,
    date: date,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    note: note,
    loanId: null,
    importSource: null,
  );
}

/// A list row with names resolved, as the repository would give it.
TransactionListItem txExpense(
  int n,
  int amount,
  String date, {
  int category = 0,
  String? note,
  String account = 'SBI',
  String accountColour = 'accountSbi',
}) {
  final Category c = txExpenseCategories[category];
  return TransactionListItem(
    entry: _entry(
      n: n,
      type: TransactionType.expense,
      amount: amount,
      date: date,
      accountId: account == 'SBI' ? sbiId : handId,
      categoryId: c.id,
      note: note,
    ),
    accountName: account,
    accountColour: accountColour,
    categoryName: c.name,
    categoryIcon: c.icon,
    categoryColourGroup: c.colourGroup.name,
  );
}

TransactionListItem txIncome(int n, int amount, String date, {String? note}) {
  final Category c = txIncomeCategories.first;
  return TransactionListItem(
    entry: _entry(
      n: n,
      type: TransactionType.income,
      amount: amount,
      date: date,
      accountId: sbiId,
      categoryId: c.id,
      note: note,
    ),
    accountName: 'SBI',
    accountColour: 'accountSbi',
    categoryName: c.name,
    categoryIcon: c.icon,
    categoryColourGroup: 'income',
  );
}

TransactionListItem txTransfer(int n, int amount, String date, {String? note}) {
  return TransactionListItem(
    entry: _entry(
      n: n,
      type: TransactionType.transfer,
      amount: amount,
      date: date,
      accountId: sbiId,
      toAccountId: axisId,
      note: note,
    ),
    accountName: 'SBI',
    accountColour: 'accountSbi',
    toAccountName: 'Axis',
    toAccountColour: 'accountOutside',
  );
}

/// A list state for [items] (newest first). Day totals are summed from the
/// items, as the repository does for the whole day.
TransactionsListState txListState(
  List<TransactionListItem> items, {
  bool hasMore = false,
  bool loadingMore = false,
  bool loadMoreFailed = false,
}) {
  final Map<String, int> spent = <String, int>{};
  final Map<String, int> income = <String, int>{};
  for (final TransactionListItem item in items) {
    final String d = item.entry.date;
    if (item.entry.type == TransactionType.expense) {
      spent[d] = (spent[d] ?? 0) + item.entry.amount;
    } else if (item.entry.type == TransactionType.income) {
      income[d] = (income[d] ?? 0) + item.entry.amount;
    }
  }
  final Map<String, DayTotal> totals = <String, DayTotal>{
    for (final TransactionListItem item in items)
      item.entry.date: DayTotal(
        date: item.entry.date,
        expense: spent[item.entry.date] ?? 0,
        income: income[item.entry.date] ?? 0,
      ),
  };
  return TransactionsListState(
    items: items,
    dayTotals: totals,
    hasMore: hasMore,
    loadingMore: loadingMore,
    loadMoreFailed: loadMoreFailed,
  );
}

/// Three days, all three types, one spending day with income.
List<TransactionListItem> txSampleItems() => <TransactionListItem>[
  txExpense(1, 25000, '2026-11-12', category: 0, note: 'Milk and bread'),
  txExpense(2, 16500, '2026-11-12', category: 1),
  txTransfer(3, 500000, '2026-11-11', note: 'Card bill'),
  txIncome(4, 8500000, '2026-11-10', note: 'Salary'),
  txExpense(5, 310000, '2026-11-10', category: 2),
  txExpense(6, 9900, '2026-10-30', category: 1, note: 'Chai'),
];

/// Records every call. Behaves as the real notifier does, minus storage.
class FakeListNotifier extends TransactionsListNotifier {
  FakeListNotifier(this.initial, {this.never = false});

  final TransactionsListState initial;

  /// Keep the first load pending (loading state).
  final bool never;
  int loadMoreCalls = 0;

  @override
  Future<TransactionsListState> build() async {
    if (never) {
      return Completer<TransactionsListState>().future;
    }
    return initial;
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }
}

/// A list whose first load fails.
class FailingListNotifier extends TransactionsListNotifier {
  @override
  Future<TransactionsListState> build() async {
    throw const StorageFailure('Could not read entries.');
  }
}

/// The filter without the database. Records what was set.
class FakeFilterNotifier extends TransactionFilterNotifier {
  FakeFilterNotifier([this.start = TransactionFilter.none]);

  final TransactionFilter start;
  final List<String> queries = <String>[];
  final List<TransactionFilter> facetSets = <TransactionFilter>[];
  final List<SavedFilter> applied = <SavedFilter>[];

  @override
  TransactionFilter build() => start;

  @override
  void setQuery(String query) {
    queries.add(query);
    state = state.copyWith(query: query);
  }

  @override
  void setFacets(TransactionFilter facets) {
    facetSets.add(facets);
    state = facets.copyWith(query: state.query);
  }

  @override
  void applySaved(SavedFilter saved) {
    applied.add(saved);
    state = saved.filter.copyWith(query: state.query);
  }

  @override
  void clear() => state = TransactionFilter.none;
}

/// Saved chips in memory. Same name rules as the real notifier.
class FakeSavedNotifier extends SavedFiltersNotifier {
  FakeSavedNotifier(this.initial);

  final List<SavedFilter> initial;
  final List<String> added = <String>[];

  @override
  Future<List<SavedFilter>> build() async => initial;

  @override
  Future<SavedFilter> add(String name, TransactionFilter filter) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure(
        'name',
        FailureCode.required,
        'Give the chip a name.',
      );
    }
    if (filter.isEmpty) {
      throw const ValidationFailure(
        'filter',
        FailureCode.rule,
        'Pick a filter before you save it.',
      );
    }
    final List<SavedFilter> current = state.value ?? initial;
    if (current.any((SavedFilter s) => s.name == trimmed)) {
      throw const ValidationFailure(
        'name',
        FailureCode.duplicate,
        'A chip with this name exists.',
      );
    }
    added.add(trimmed);
    final SavedFilter saved = SavedFilter(
      id: 'saved-${added.length}',
      name: trimmed,
      filter: filter,
    );
    state = AsyncData<List<SavedFilter>>(<SavedFilter>[...current, saved]);
    return saved;
  }

  @override
  Future<void> remove(String id) async {
    final List<SavedFilter> current = state.value ?? initial;
    state = AsyncData<List<SavedFilter>>(
      current.where((SavedFilter s) => s.id != id).toList(),
    );
  }
}

/// Delete and undo, recorded.
class FakeActions implements TransactionActions {
  FakeActions({this.deleteOk = true, this.undoOk = true});

  final bool deleteOk;
  final bool undoOk;
  final List<String> deleted = <String>[];
  final List<String> undone = <String>[];

  @override
  Future<bool> delete(String id) async {
    deleted.add(id);
    return deleteOk;
  }

  @override
  Future<bool> undoDelete(String id) async {
    undone.add(id);
    return undoOk;
  }
}

/// Overrides for every screen read: accounts, categories, month summary and
/// the list. [list] defaults to the sample rows.
List<Override> txOverrides({
  TransactionsListState? list,
  FakeListNotifier? listNotifier,
  TransactionFilter filter = TransactionFilter.none,
  FakeFilterNotifier? filterNotifier,
  List<SavedFilter> saved = const <SavedFilter>[],
  FakeSavedNotifier? savedNotifier,
  FakeActions? actions,
  bool failing = false,
}) {
  final FakeListNotifier notifier =
      listNotifier ?? FakeListNotifier(list ?? txListState(txSampleItems()));
  final FakeFilterNotifier filters =
      filterNotifier ?? FakeFilterNotifier(filter);
  final FakeSavedNotifier savedNotes =
      savedNotifier ?? FakeSavedNotifier(saved);
  return <Override>[
    transactionsListProvider.overrideWith(
      failing ? FailingListNotifier.new : () => notifier,
    ),
    transactionFilterProvider.overrideWith(() => filters),
    savedFiltersProvider.overrideWith(() => savedNotes),
    transactionActionsProvider.overrideWithValue(actions ?? FakeActions()),
    monthSummaryProvider.overrideWith(
      (Ref ref, String month) => Stream<MonthSummary>.value(
        MonthSummary(month: month, spent: 1854000, income: 8500000),
      ),
    ),
    accountsProvider.overrideWith(
      (Ref ref) => Stream<List<Account>>.value(txAccounts),
    ),
    expenseCategoriesProvider.overrideWith(
      (Ref ref) => Stream<List<Category>>.value(txExpenseCategories),
    ),
    incomeCategoriesProvider.overrideWith(
      (Ref ref) => Stream<List<Category>>.value(txIncomeCategories),
    ),
  ];
}
