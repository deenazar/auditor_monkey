import '../domain/transaction_list_item.dart';

/// What the Transactions list shows for the current filter.
class TransactionsListState {
  const TransactionsListState({
    required this.items,
    required this.dayTotals,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  static const TransactionsListState empty = TransactionsListState(
    items: <TransactionListItem>[],
    dayTotals: <String, DayTotal>{},
    hasMore: false,
  );

  /// Loaded rows, newest first (date, then entry time).
  final List<TransactionListItem> items;

  /// Totals of every day that has a loaded row. A day's total always covers
  /// the WHOLE day (also rows not loaded yet), for the current filter.
  final Map<String, DayTotal> dayTotals;

  /// More (older) rows exist after the last loaded one.
  final bool hasMore;

  /// The next page is being read.
  final bool loadingMore;

  /// The last next-page read failed; the list shows a retry row.
  final bool loadMoreFailed;

  List<DayGroup> get groups => groupByDay(items, dayTotals);

  TransactionsListState copyWith({
    List<TransactionListItem>? items,
    Map<String, DayTotal>? dayTotals,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => TransactionsListState(
    items: items ?? this.items,
    dayTotals: dayTotals ?? this.dayTotals,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}
