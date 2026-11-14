import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger_provider.dart';
import '../../../../core/utils/validation_failure.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton_block.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../accounts/application/accounts_providers.dart';
import '../../../accounts/domain/account.dart';
import '../../../categories/application/categories_providers.dart';
import '../../../categories/domain/category.dart';
import '../../../transactions/presentation/transactions_actions.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/balance_slices.dart';
import '../../domain/dashboard_summary.dart';
import '../../domain/home_summary.dart';
import '../home_actions.dart';
import 'balance_doughnut.dart';
import 'home_section_error.dart';
import 'home_stat_tiles.dart';
import 'month_tiles.dart';
import 'top_spending_card.dart';

/// Budget, Remaining and Income tiles (plan section 3, item 3).
class MonthTilesSection extends ConsumerWidget {
  const MonthTilesSection({
    required this.summary,
    required this.index,
    super.key,
  });

  final AsyncValue<DashboardSummary> summary;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardSummary? s = summary.value;
    if (s == null) {
      return summary.hasError
          ? HomeSectionError(
              message: summaryErrorMessage(
                summary,
                'Could not load this month.',
              ),
              onRetry: () => ref.invalidate(dashboardSummaryProvider),
            )
          : const SkeletonBlock(height: 96);
    }
    return StaggeredEntrance(
      index: index,
      child: MonthTiles(
        budget: s.hasBudget ? s.budgetTotal : null,
        spent: s.spent,
        remaining: s.remaining,
        income: s.income,
        onBudgetTap: () {
          ref.read(loggerProvider).info(homeLogTag, 'budget tile tap');
          showTransactionToast(
            ScaffoldMessenger.of(context),
            'Budgets come in a later update',
          );
        },
      ),
    );
  }
}

/// The week bars and savings ring (kept under the month tiles, Q7).
class StatTilesSection extends StatelessWidget {
  const StatTilesSection({
    required this.summary,
    required this.index,
    super.key,
  });

  final AsyncValue<DashboardSummary> summary;
  final int index;

  @override
  Widget build(BuildContext context) {
    final DashboardSummary? s = summary.value;
    if (s == null) return const SizedBox.shrink();
    final HomeSummary home = s.toHomeSummary();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: StaggeredEntrance(
        index: index,
        child: HomeStatTiles(
          days: <int>[for (final DaySpend d in home.week) d.spent],
          savingsPercent: home.savingsPercent,
        ),
      ),
    );
  }
}

/// "Where your money is": the account balance doughnut. Works on its own:
/// it reads the balances, not the month summary.
class BalanceSection extends ConsumerWidget {
  const BalanceSection({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AccountBalance>> balances = ref.watch(
      accountBalancesProvider,
    );
    void retry() => ref.invalidate(accountBalancesProvider);
    final List<AccountBalance>? data = balances.value;
    if (data == null) {
      return balances.hasError
          ? HomeSectionError(
              message: 'Could not load your accounts.',
              onRetry: retry,
            )
          : const SkeletonBlock(height: 300);
    }
    final BalanceSlices slices;
    try {
      slices = buildBalanceSlices(data);
    } on OverflowFailure {
      return HomeSectionError(
        message: 'A balance is too large to show.',
        onRetry: retry,
      );
    }
    return StaggeredEntrance(
      index: index,
      child: BalanceDoughnut(
        slices: slices,
        onOpenAccount: HomeActions(ref, context).openAccount,
      ),
    );
  }
}

/// "Top spending": the 3 biggest categories of the month.
class TopSpendingSection extends ConsumerWidget {
  const TopSpendingSection({
    required this.summary,
    required this.index,
    super.key,
  });

  final AsyncValue<DashboardSummary> summary;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardSummary? s = summary.value;
    if (s == null) {
      return summary.hasError
          ? HomeSectionError(
              message: summaryErrorMessage(
                summary,
                'Could not load top spending.',
              ),
              onRetry: () => ref.invalidate(dashboardSummaryProvider),
            )
          : const SkeletonBlock(height: 200);
    }
    final Map<String, Category> cats = <String, Category>{
      for (final Category c in <Category>[
        ...?ref.watch(expenseCategoriesProvider).value,
        ...?ref.watch(incomeCategoriesProvider).value,
      ])
        c.id: c,
    };
    return StaggeredEntrance(
      index: index,
      child: TopSpendingCard(
        items: <TopSpendingItem>[
          for (final t in s.topCategories)
            TopSpendingItem(
              categoryId: t.categoryId,
              name: cats[t.categoryId]?.name ?? 'Category',
              iconName: cats[t.categoryId]?.icon ?? '',
              colourGroup: cats[t.categoryId]?.colourGroup.name ?? 'other',
              amount: t.total,
              percent: t.percent,
            ),
        ],
        onOpenCategory: (String id) => HomeActions(
          ref,
          context,
        ).openMonthSpending(s.month, categoryId: id),
      ),
    );
  }
}
