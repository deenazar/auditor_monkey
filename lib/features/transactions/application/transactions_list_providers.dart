// CONTRACT FILE (written by the lead). senior-dev replaces the bodies;
// the names, types and documented behaviour are what the UI builds on.
// Change a signature only together with junior-dev.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transaction_filter.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_list_state.dart';

/// Rows per page of the list.
const int transactionsPageSize = 50;

/// The current list filter (search text + facets). Kept while the app runs.
final NotifierProvider<TransactionFilterNotifier, TransactionFilter>
transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.none;

  /// Search text (trimmed, cut to [maxSearchLength]; control characters
  /// removed). The list debounces it by 250 ms.
  void setQuery(String query) => throw UnimplementedError();

  /// Replaces every facet but keeps the search text.
  void setFacets(TransactionFilter facets) => throw UnimplementedError();

  /// Applies a saved chip (its facets; search text is kept).
  void applySaved(SavedFilter saved) => throw UnimplementedError();

  /// Back to [TransactionFilter.none].
  void clear() => throw UnimplementedError();
}

/// The list for the current filter: first page on build, [loadMore] for
/// the next. Reloads (keeping how many rows were loaded) when the filter
/// changes or when any transaction, account or category changes, so edits,
/// deletes and undo show at once.
final AsyncNotifierProvider<TransactionsListNotifier, TransactionsListState>
transactionsListProvider =
    AsyncNotifierProvider<TransactionsListNotifier, TransactionsListState>(
      TransactionsListNotifier.new,
    );

class TransactionsListNotifier extends AsyncNotifier<TransactionsListState> {
  @override
  Future<TransactionsListState> build() => throw UnimplementedError();

  /// Reads the next page. Safe to call many times (one read at a time; does
  /// nothing without [TransactionsListState.hasMore]).
  Future<void> loadMore() => throw UnimplementedError();
}

/// Spent / income / net of [month] (`YYYY-MM`) for the current filter,
/// kept up to date. Transfers and loan-linked entries never count.
final monthSummaryProvider = StreamProvider.family<MonthSummary, String>(
  (Ref ref, String month) => throw UnimplementedError(),
);

/// One entry with names, kept up to date; `null` once it is deleted or
/// when the id is unknown.
final transactionDetailProvider =
    StreamProvider.family<TransactionListItem?, String>(
      (Ref ref, String id) => throw UnimplementedError(),
    );

/// Saved filter chips, oldest first.
final AsyncNotifierProvider<SavedFiltersNotifier, List<SavedFilter>>
savedFiltersProvider =
    AsyncNotifierProvider<SavedFiltersNotifier, List<SavedFilter>>(
      SavedFiltersNotifier.new,
    );

class SavedFiltersNotifier extends AsyncNotifier<List<SavedFilter>> {
  @override
  Future<List<SavedFilter>> build() => throw UnimplementedError();

  /// Saves [filter]'s facets under [name]. Throws `ValidationFailure`
  /// (plain message) for an empty / too long / duplicate name, an empty
  /// filter, or more than [maxSavedFilters].
  Future<SavedFilter> add(String name, TransactionFilter filter) =>
      throw UnimplementedError();

  Future<void> remove(String id) => throw UnimplementedError();
}

/// Delete and undo for the list and the detail screen.
final Provider<TransactionActions> transactionActionsProvider =
    Provider<TransactionActions>((Ref ref) => throw UnimplementedError());

abstract interface class TransactionActions {
  /// Soft deletes. `true` when done. Never throws; logs without values.
  Future<bool> delete(String id);

  /// Restores a deleted entry. `false` when it cannot come back (for
  /// example its account was removed meanwhile). Never throws.
  Future<bool> undoDelete(String id);
}
