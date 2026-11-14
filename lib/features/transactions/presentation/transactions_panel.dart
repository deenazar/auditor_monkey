import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/today_provider.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../application/transactions_list_providers.dart';
import '../application/transactions_list_state.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_actions.dart';
import 'widgets/day_header.dart';
import 'widgets/filter_button.dart';
import 'widgets/list_footer.dart';
import 'widgets/saved_filter_chips.dart';
import 'widgets/transaction_row.dart';
import 'widgets/transactions_search_field.dart';

/// The body of the Transactions screen: search and filter button, saved
/// chips, then the day-grouped list. The list pages in as the
/// user scrolls, and reports the month of the topmost visible day.
class TransactionsPanel extends ConsumerStatefulWidget {
  const TransactionsPanel({required this.onMonthChanged, super.key});

  /// Called with `YYYY-MM` when the topmost visible day changes month.
  final ValueChanged<String> onMonthChanged;

  /// Ask for the next page when this close to the end (logical pixels).
  static const double loadMoreDistance = 600;

  /// Rows that get the entrance motion on first load.
  static const int staggerRows = 8;

  @override
  ConsumerState<TransactionsPanel> createState() => _TransactionsPanelState();
}

/// One line of the flat list: a day header or a row.
class _Line {
  const _Line.header(this.group) : item = null;
  const _Line.row(this.item) : group = null;

  final DayGroup? group;
  final TransactionListItem? item;
}

class _TransactionsPanelState extends ConsumerState<TransactionsPanel> {
  final GlobalKey _listKey = GlobalKey();
  final ScrollController _scroll = ScrollController();

  /// Rows whose delete failed: their key changes so the swiped-away row
  /// comes back (a dismissed row cannot be shown again).
  final Map<String, int> _deleteFailures = <String, int>{};
  final Map<String, GlobalKey> _dayKeys = <String, GlobalKey>{};
  TransactionsListState? _memoState;
  List<_Line> _lines = const <_Line>[];
  bool _staggerDone = false;
  bool _staggerQueued = false;

  String _month = '';
  bool _reportQueued = false;

  /// Flattens the groups once per loaded state (not on every build).
  void _flatten(TransactionsListState state) {
    _memoState = state;
    final List<_Line> lines = <_Line>[];
    for (final DayGroup g in state.groups) {
      lines.add(_Line.header(g));
      for (final TransactionListItem item in g.items) {
        lines.add(_Line.row(item));
      }
    }
    _lines = lines;
    // Keys of days no longer loaded (filter changes, reloads) are dropped.
    final Set<String> dates = <String>{
      for (final DayGroup g in state.groups) g.date,
    };
    _dayKeys.removeWhere((String date, GlobalKey _) => !dates.contains(date));
    // The first rows get the entrance, once, when real rows first show.
    if (!_staggerDone && !_staggerQueued && state.items.isNotEmpty) {
      _staggerQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _staggerDone = true;
      });
    }
    _queueMonthReport();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String date) => _dayKeys.putIfAbsent(date, GlobalKey.new);

  void _queueMonthReport() {
    if (_reportQueued) return;
    _reportQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportQueued = false;
      if (mounted) _reportMonth();
    });
  }

  /// The day header nearest above the top of the list is the topmost day.
  void _reportMonth() {
    final RenderObject? listBox = _listKey.currentContext?.findRenderObject();
    if (listBox is! RenderBox || !listBox.attached || !listBox.hasSize) {
      return;
    }
    final double top = listBox.localToGlobal(Offset.zero).dy;
    String? best;
    double bestY = double.negativeInfinity;
    for (final MapEntry<String, GlobalKey> entry in _dayKeys.entries) {
      final RenderObject? box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final double y = box.localToGlobal(Offset.zero).dy;
      if (y <= top + 8 && y > bestY) {
        bestY = y;
        best = entry.key;
      }
    }
    // Nothing above the top: at the very start the first day is the topmost.
    if (best == null) {
      final bool atStart = !_scroll.hasClients || _scroll.offset <= 0;
      final DayGroup? first = _lines.isEmpty ? null : _lines.first.group;
      if (!atStart || first == null) return;
      best = first.date;
    }
    final String month = best.substring(0, 7);
    if (month != _month) {
      _month = month;
      widget.onMonthChanged(month);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _maybeLoadMore(n.metrics);
      _queueMonthReport();
    }
    return false;
  }

  void _maybeLoadMore(ScrollMetrics metrics) {
    if (metrics.extentAfter > TransactionsPanel.loadMoreDistance) return;
    final TransactionsListState? state = ref
        .read(transactionsListProvider)
        .value;
    if (state == null || !state.hasMore || state.loadingMore) return;
    if (state.loadMoreFailed) return; // the retry row asks the user instead
    ref.read(loggerProvider).debug(transactionsLogTag, 'next page requested');
    unawaited(ref.read(transactionsListProvider.notifier).loadMore());
  }

  void _open(TransactionListItem item) {
    ref.read(loggerProvider).debug(transactionsLogTag, 'row opened');
    context.push(AppRoutes.transactionDetail(item.entry.id));
  }

  void _edit(TransactionListItem item) {
    unawaited(openEditEntry(context, ref.read(loggerProvider), item.entry));
  }

  Future<bool> _delete(TransactionListItem item) async {
    final bool deleted = await deleteEntryWithUndo(
      actions: ref.read(transactionActionsProvider),
      messenger: ScaffoldMessenger.of(context),
      log: ref.read(loggerProvider),
      entry: item.entry,
    );
    if (!deleted && mounted) {
      final String id = item.entry.id;
      setState(() => _deleteFailures[id] = (_deleteFailures[id] ?? 0) + 1);
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TransactionsListState> async = ref.watch(
      transactionsListProvider,
    );
    final TransactionFilter filter = ref.watch(transactionFilterProvider);
    final String today = ref.watch(todayProvider);
    final TransactionsListState? state = async.value;
    if (state != null && !identical(state, _memoState)) _flatten(state);

    final bool loading =
        async.isLoading && (state == null || state.items.isEmpty);
    final bool failed = async.hasError && state == null;
    final double bottom = MediaQuery.paddingOf(context).bottom + 24;
    const double side = AppSpacing.screenPadding;
    // Room for an illustration, a title, a message and a button, also at
    // large text sizes (the views scroll inside this box if they must).
    final double stateHeight = MediaQuery.sizeOf(context).height * 0.5;

    final Widget? footer = state == null
        ? null
        : state.loadingMore
        ? const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space2),
            child: SkeletonRows(),
          )
        : state.loadMoreFailed
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: LoadMoreRetry(
              onRetry: () => unawaited(
                ref.read(transactionsListProvider.notifier).loadMore(),
              ),
            ),
          )
        : null;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        key: _listKey,
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(side, AppSpacing.space4, side, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  Expanded(child: TransactionsSearchField()),
                  SizedBox(width: AppSpacing.space2),
                  TransactionsFilterButton(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacing.space3),
              child: SavedFilterChips(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space2)),
          if (loading)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: side),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: AppSpacing.space4),
                    SkeletonBlock(height: 18, width: 110),
                    SizedBox(height: AppSpacing.space3),
                    SkeletonRows(count: 6),
                  ],
                ),
              ),
            )
          else if (failed)
            SliverToBoxAdapter(
              child: SizedBox(
                height: stateHeight,
                child: ErrorState(
                  title: 'Could not load entries',
                  message: 'Your data is safe. Try again.',
                  onRetry: () => ref.invalidate(transactionsListProvider),
                ),
              ),
            )
          else if (state == null || state.items.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: stateHeight,
                child: filter.isEmpty
                    ? EmptyState(
                        illustration: 'empty_transactions',
                        title: 'No entries yet',
                        message:
                            'Add your first expense, income or transfer. '
                            'The monkey keeps count.',
                        action: PrimaryButton(
                          label: 'Add your first entry',
                          fullWidth: false,
                          onPressed: () => unawaited(
                            openAddEntry(context, ref.read(loggerProvider)),
                          ),
                        ),
                      )
                    : EmptyState(
                        illustration: 'no_results',
                        title: 'No entries match',
                        message:
                            'Try other words, or clear the filters to see '
                            'everything.',
                        action: PrimaryButton(
                          label: 'Clear filters',
                          fullWidth: false,
                          onPressed: () {
                            ref
                                .read(loggerProvider)
                                .info(transactionsLogTag, 'filters cleared');
                            ref
                                .read(transactionFilterProvider.notifier)
                                .clear();
                          },
                        ),
                      ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: side),
              sliver: SliverList.builder(
                itemCount: _lines.length + (footer == null ? 0 : 1),
                itemBuilder: (BuildContext context, int i) {
                  if (i >= _lines.length) return footer!;
                  final _Line line = _lines[i];
                  final DayGroup? group = line.group;
                  if (group != null) {
                    return DayHeader(
                      key: _keyFor(group.date),
                      group: group,
                      today: today,
                    );
                  }
                  final TransactionListItem item = line.item!;
                  final Widget row = KeyedSubtree(
                    key: ValueKey<String>(
                      '${item.entry.id}#'
                      '${_deleteFailures[item.entry.id] ?? 0}',
                    ),
                    child: RepaintBoundary(
                      child: TransactionRow(
                        item: item,
                        onTap: () => _open(item),
                        onEdit: () => _edit(item),
                        onDelete: () => _delete(item),
                      ),
                    ),
                  );
                  // Same wrapper type for every row, so switching the
                  // entrance off never remounts a row.
                  return StaggeredEntrance(
                    index: i,
                    animate: !_staggerDone && i < TransactionsPanel.staggerRows,
                    child: row,
                  );
                },
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }
}
