import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/no_retry.dart';
import '../../../core/utils/validation_failure.dart';
import '../data/transactions_list_repository.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_list_state.dart';
import 'transactions_providers.dart';

export 'saved_filters_notifier.dart';

/// Rows per page of the list.
const int transactionsPageSize = 50;

const String _tag = 'transactions_list';

final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

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
  void setQuery(String query) {
    String text = query.replaceAll(_controlChars, '').trim();
    if (text.length > maxSearchLength) {
      text = text.substring(0, maxSearchLength).trim();
    }
    if (text == state.query) return;
    state = state.copyWith(query: text);
  }

  /// Replaces every facet but keeps the search text.
  void setFacets(TransactionFilter facets) {
    final TransactionFilter next = TransactionFilter(
      query: state.query,
      from: facets.from,
      to: facets.to,
      types: facets.types,
      accountIds: facets.accountIds,
      categoryIds: facets.categoryIds,
    );
    if (next == state) return;
    state = next;
  }

  /// Applies a saved chip (its facets; search text is kept).
  void applySaved(SavedFilter saved) => setFacets(saved.filter);

  /// Back to [TransactionFilter.none].
  void clear() {
    if (state == TransactionFilter.none) return;
    state = TransactionFilter.none;
  }
}

/// The list for the current filter: first page on build, [loadMore] for
/// the next. Reloads (keeping how many rows were loaded) when any
/// transaction, account or category changes, so edits, deletes and undo show
/// at once. A new filter starts again from the first page. The old rows
/// stay on screen (as previous data) until the new ones arrive.
final AsyncNotifierProvider<TransactionsListNotifier, TransactionsListState>
transactionsListProvider =
    AsyncNotifierProvider<TransactionsListNotifier, TransactionsListState>(
      TransactionsListNotifier.new,
      retry: noRetry,
    );

class TransactionsListNotifier extends AsyncNotifier<TransactionsListState> {
  TransactionFilter _filter = TransactionFilter.none;

  /// Grows with every build, so work started for an old filter is dropped.
  int _generation = 0;

  /// Grows with every applied reload, so a page read before a reload is not
  /// glued onto the reloaded list.
  int _epoch = 0;
  bool _ready = false;
  bool _dirty = false;
  bool _reloading = false;
  bool _reloadAgain = false;
  bool _loadingMore = false;
  int _extraRows = 0;

  TransactionsListRepository get _repo =>
      ref.read(transactionsListRepositoryProvider);

  @override
  Future<TransactionsListState> build() async {
    _filter = ref.watch(transactionFilterProvider);
    final int generation = ++_generation;
    _ready = false;
    _dirty = false;
    _reloading = false;
    _reloadAgain = false;
    _loadingMore = false;
    _extraRows = 0;
    // Subscribe first, then load: a write in between still triggers a
    // reload. The first signal comes with the subscription and is skipped.
    final StreamSubscription<void> sub = _repo
        .watchChangeSignal()
        .skip(1)
        .listen(
          (_) {
            if (_ready) {
              unawaited(_reload(generation));
            } else {
              _dirty = true;
            }
          },
          // The repository already logged it. The rows on screen stay; the
          // next change reloads them.
          onError: (Object error, StackTrace stack) {},
        );
    ref.onDispose(sub.cancel);
    final ListPage first = await _repo.page(
      _filter,
      limit: transactionsPageSize,
    );
    if (generation == _generation) {
      _ready = true;
      if (_dirty) {
        _dirty = false;
        unawaited(Future<void>(() => _reload(generation)));
      }
    }
    return _stateOf(first);
  }

  TransactionsListState _stateOf(ListPage page) => TransactionsListState(
    items: page.items,
    dayTotals: page.dayTotals,
    hasMore: page.hasMore,
  );

  Future<void> _reload(int generation) async {
    if (_reloading) {
      _reloadAgain = true;
      return;
    }
    _reloading = true;
    try {
      do {
        _reloadAgain = false;
        final int loaded = state.value?.items.length ?? 0;
        final int wanted = (loaded + _extraRows).clamp(
          transactionsPageSize,
          maxListReload,
        );
        _extraRows = 0;
        final ListPage fresh = await _repo.page(_filter, limit: wanted);
        if (!ref.mounted || generation != _generation) return;
        _epoch++;
        state = AsyncData<TransactionsListState>(_stateOf(fresh));
      } while (_reloadAgain);
    } on Object {
      // Keep the rows on screen; the next change reloads them.
      if (ref.mounted && generation == _generation) {
        ref.read(loggerProvider).warning(_tag, 'reload failed');
      }
    } finally {
      if (generation == _generation) _reloading = false;
    }
  }

  /// Reads the next page. Safe to call many times (one read at a time; does
  /// nothing without [TransactionsListState.hasMore]).
  Future<void> loadMore() async {
    final TransactionsListState? current = state.value;
    if (current == null ||
        !current.hasMore ||
        _loadingMore ||
        current.items.isEmpty) {
      return;
    }
    final int generation = _generation;
    final int epoch = _epoch;
    _loadingMore = true;
    state = AsyncData<TransactionsListState>(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final ListPage page = await _repo.page(
        _filter,
        limit: transactionsPageSize,
        after: TransactionCursor.after(current.items.last.entry),
      );
      if (!ref.mounted || generation != _generation) return;
      if (epoch != _epoch) {
        // The list was reloaded meanwhile: read once more, one page longer.
        _extraRows += transactionsPageSize;
        unawaited(_reload(generation));
        return;
      }
      final TransactionsListState latest = state.value ?? current;
      state = AsyncData<TransactionsListState>(
        latest.copyWith(
          items: <TransactionListItem>[...latest.items, ...page.items],
          dayTotals: <String, DayTotal>{...latest.dayTotals, ...page.dayTotals},
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on Object {
      if (!ref.mounted || generation != _generation) return;
      ref.read(loggerProvider).warning(_tag, 'load more failed');
      final TransactionsListState latest = state.value ?? current;
      state = AsyncData<TransactionsListState>(
        latest.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }
}

/// Spent / income / net of [month] (`YYYY-MM`) for the current filter,
/// kept up to date. Transfers and loan-linked entries never count.
final monthSummaryProvider = StreamProvider.family<MonthSummary, String>(
  retry: noRetry,
  (Ref ref, String month) => ref
      .watch(transactionsListRepositoryProvider)
      .watchMonthSummary(ref.watch(transactionFilterProvider), month),
);

/// One entry with names, kept up to date; `null` once it is deleted or
/// when the id is unknown.
final transactionDetailProvider =
    StreamProvider.family<TransactionListItem?, String>(
      retry: noRetry,
      (Ref ref, String id) =>
          ref.watch(transactionsListRepositoryProvider).watchDetail(id),
    );

/// Delete and undo for the list and the detail screen.
final Provider<TransactionActions> transactionActionsProvider =
    Provider<TransactionActions>(
      (Ref ref) => _RepositoryActions(
        ref.watch(transactionsRepositoryProvider),
        ref.watch(loggerProvider),
      ),
    );

abstract interface class TransactionActions {
  /// Soft deletes. `true` when done. Never throws; logs without values.
  Future<bool> delete(String id);

  /// Restores a deleted entry. `false` when it cannot come back (for
  /// example its account was removed meanwhile). Never throws.
  Future<bool> undoDelete(String id);
}

class _RepositoryActions implements TransactionActions {
  const _RepositoryActions(this._repository, this._logger);

  final TransactionsRepository _repository;
  final AppLogger _logger;

  @override
  Future<bool> delete(String id) => _run('delete', id, _repository.softDelete);

  @override
  Future<bool> undoDelete(String id) =>
      _run('undo delete', id, _repository.restore);

  Future<bool> _run(
    String op,
    String id,
    Future<Object?> Function(String id) action,
  ) async {
    // The repository already logs the operation with the short id; here
    // only the outcome is added (never amounts, notes or names).
    try {
      await action(id);
      return true;
    } on DataFailure catch (failure) {
      _logger.warning(_tag, '$op refused: ${failure.code.name}');
      return false;
    } on Object {
      _logger.warning(_tag, '$op failed');
      return false;
    }
  }
}
