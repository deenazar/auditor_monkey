import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/repository_support.dart' show shortId;
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/no_retry.dart';
import '../../../core/utils/today_provider.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/statement_line.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';
import 'accounts_providers.dart';

/// Lines per statement page.
const int statementPageSize = 50;

/// Months shown in the income-vs-expense chart (this month included).
const int chartMonthCount = 6;

/// What the statement screen shows. Immutable; the notifier replaces it.
class AccountStatementState {
  const AccountStatementState({
    required this.account,
    required this.balance,
    required this.lines,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final Account account;

  /// Current balance (paise): opening plus every entry.
  final int balance;

  /// Loaded lines, newest first. The opening balance row is NOT in the
  /// list: show it after the last line when [hasMore] is false.
  final List<StatementLine> lines;

  /// Older lines exist beyond [lines].
  final bool hasMore;
  final bool loadingMore;

  /// The last "load more" failed. Call `loadMore()` again to retry.
  final bool loadMoreFailed;

  /// Show the opening balance row (all lines are loaded).
  bool get showOpeningRow => !hasMore;

  AccountStatementState copyWith({
    Account? account,
    int? balance,
    List<StatementLine>? lines,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => AccountStatementState(
    account: account ?? this.account,
    balance: balance ?? this.balance,
    lines: lines ?? this.lines,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// Statement of one account: pages of lines with the running balance.
///
/// The first page loads in `build`. `loadMore()` appends the next page.
/// Whenever transactions, accounts or categories change, everything loaded
/// so far is read again (so edits and new entries show up live, and the
/// loaded pages are kept). A malformed or unknown id ends in an error with
/// [NotFoundFailure]; a balance too large ends in [OverflowFailure].
class AccountStatementNotifier extends AsyncNotifier<AccountStatementState> {
  AccountStatementNotifier(this.accountId);

  final String accountId;

  bool _ready = false;
  bool _dirty = false;
  bool _reloading = false;
  bool _reloadAgain = false;

  @override
  Future<AccountStatementState> build() async {
    if (!isUuidShape(accountId)) {
      throw const NotFoundFailure('This account is not available.');
    }
    final TransactionsRepository tx = ref.read(transactionsRepositoryProvider);
    // Subscribe first, then load: a write in between still triggers a
    // reload. The first signal comes with the subscription itself and is
    // skipped (the initial load covers it).
    final StreamSubscription<void> sub = tx
        .watchStatementSignal()
        .skip(1)
        .listen(
          (_) {
            if (_ready) {
              unawaited(_reload());
            } else {
              _dirty = true;
            }
          },
          onError: (Object error, StackTrace stack) =>
              state = AsyncError<AccountStatementState>(error, stack),
        );
    ref.onDispose(sub.cancel);
    ref
        .read(loggerProvider)
        .debug('statement', 'open id=${shortId(accountId)}');
    final AccountStatementState first = await _read(statementPageSize);
    _ready = true;
    if (_dirty) {
      // A change arrived while loading: read once more, right after.
      _dirty = false;
      unawaited(Future<void>(_reload));
    }
    return first;
  }

  Future<AccountStatementState> _read(int count) async {
    final AccountsRepository accounts = ref.read(accountsRepositoryProvider);
    final TransactionsRepository tx = ref.read(transactionsRepositoryProvider);
    final AccountBalance? header = await accounts.getBalance(accountId);
    if (header == null) {
      throw const NotFoundFailure('This account is not available.');
    }
    final StatementPage page = await tx.statementThrough(
      accountId,
      count: count,
    );
    return AccountStatementState(
      account: header.account,
      balance: header.balance,
      lines: page.lines,
      hasMore: page.hasMore,
    );
  }

  Future<void> _reload() async {
    if (_reloading) {
      _reloadAgain = true;
      return;
    }
    _reloading = true;
    try {
      do {
        _reloadAgain = false;
        // Re-read everything loaded so far, rounded up to whole pages, so
        // a new entry does not push the oldest loaded line out of view.
        final int loaded = state.value?.lines.length ?? 0;
        final int count =
            ((loaded + statementPageSize - 1) ~/ statementPageSize).clamp(
              1,
              1000,
            ) *
            statementPageSize;
        final AccountStatementState fresh = await _read(count);
        if (!ref.mounted) return;
        state = AsyncData<AccountStatementState>(fresh);
      } while (_reloadAgain);
    } on Object catch (error, stack) {
      if (ref.mounted) {
        ref.read(loggerProvider).warning('statement', 'reload failed');
        state = AsyncError<AccountStatementState>(error, stack);
      }
    } finally {
      _reloading = false;
    }
  }

  /// Loads the next (older) page. Does nothing while loading, when there
  /// is nothing more, or when the statement is not ready. On failure
  /// `loadMoreFailed` is set; call again to retry.
  Future<void> loadMore() async {
    final AccountStatementState? current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.loadingMore ||
        current.lines.isEmpty) {
      return;
    }
    state = AsyncData<AccountStatementState>(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final StatementPage page = await ref
          .read(transactionsRepositoryProvider)
          .statementPage(
            accountId,
            limit: statementPageSize,
            after: TransactionCursor.after(current.lines.last.entry),
          );
      if (!ref.mounted) return;
      // Lines may have changed while loading: merge on the latest state.
      final AccountStatementState latest = state.value ?? current;
      final Set<String> have = latest.lines
          .map((StatementLine l) => l.entry.id)
          .toSet();
      state = AsyncData<AccountStatementState>(
        latest.copyWith(
          lines: <StatementLine>[
            ...latest.lines,
            ...page.lines.where(
              (StatementLine l) => !have.contains(l.entry.id),
            ),
          ],
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on Object {
      if (!ref.mounted) return;
      ref.read(loggerProvider).warning('statement', 'load more failed');
      final AccountStatementState latest = state.value ?? current;
      state = AsyncData<AccountStatementState>(
        latest.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

/// Statement of one account (see [AccountStatementNotifier]). Dropped when
/// the screen goes away.
final accountStatementProvider = AsyncNotifierProvider.autoDispose
    .family<AccountStatementNotifier, AccountStatementState, String>(
      AccountStatementNotifier.new,
      retry: noRetry,
    );

/// Income and expense of one account for the last [chartMonthCount] months
/// (this month included), oldest first, kept up to date. Months without
/// entries are 0. Transfers and loan-linked entries are left out.
final accountMonthlyTotalsProvider = StreamProvider.autoDispose
    .family<List<MonthlyTotal>, String>(retry: noRetry, (
      Ref ref,
      String accountId,
    ) {
      final String thisMonth = ref.watch(currentMonthProvider);
      return ref
          .watch(transactionsRepositoryProvider)
          .watchMonthlyTotalsForAccount(
            accountId,
            fromMonth: addMonths(thisMonth, 1 - chartMonthCount),
            toMonth: thisMonth,
          );
    });
