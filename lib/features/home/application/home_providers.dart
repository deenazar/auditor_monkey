import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/no_retry.dart';
import '../../../core/utils/today_provider.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../budgets/domain/budget.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../domain/home_summary.dart';

/// Live Home numbers: re-read whenever entries, accounts or categories
/// change. Read-only; no money rules live here (the repository sums).
final StreamProvider<HomeSummary> homeSummaryProvider =
    StreamProvider<HomeSummary>((Ref ref) {
      final TransactionsRepository repo = ref.watch(
        transactionsRepositoryProvider,
      );
      final String today = ref.watch(todayProvider);
      return repo.watchStatementSignal().asyncMap(
        (_) => loadHomeSummary(repo, today),
      );
    }, retry: noRetry);

/// This month's budget total (paise; 0 when there are no budgets).
final Provider<AsyncValue<int>> monthBudgetTotalProvider =
    Provider<AsyncValue<int>>((Ref ref) {
      final String month = ref.watch(currentMonthProvider);
      return ref
          .watch(budgetsForMonthProvider(month))
          .whenData(
            (List<Budget> budgets) =>
                budgets.fold<int>(0, (int sum, Budget b) => sum + b.amount),
          );
    });

/// Reads one [HomeSummary] for [today] (`YYYY-MM-DD`).
Future<HomeSummary> loadHomeSummary(
  TransactionsRepository repo,
  String today,
) async {
  final List<String> dates = <String>[
    for (int i = HomeSummary.stripDays - 1; i >= 0; i--) addDays(today, -i),
  ];
  final List<int> spent = await Future.wait(<Future<int>>[
    for (final String d in dates) repo.expenseTotal(from: d, to: d),
  ]);
  final String monthStart = '${today.substring(0, 7)}-01';
  final (
    int monthSpent,
    int monthIncome,
    List<TransactionEntry> recent,
  ) = await (
    repo.expenseTotal(from: monthStart, to: today),
    repo.incomeTotal(from: monthStart, to: today),
    repo.page(limit: HomeSummary.recentLimit),
  ).wait;
  return HomeSummary(
    today: today,
    days: <DaySpend>[
      for (int i = 0; i < dates.length; i++)
        DaySpend(date: dates[i], spent: spent[i]),
    ],
    monthSpent: monthSpent,
    monthIncome: monthIncome,
    recent: recent,
  );
}
