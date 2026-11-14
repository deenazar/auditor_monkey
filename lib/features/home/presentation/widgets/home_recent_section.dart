import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger_provider.dart';
import '../../../../core/utils/today_provider.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_block.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../accounts/application/accounts_providers.dart';
import '../../../categories/application/categories_providers.dart';
import '../../../categories/domain/category.dart';
import '../../../transactions/application/transactions_list_providers.dart';
import '../../../transactions/domain/transaction_entry.dart';
import '../../../transactions/presentation/transactions_actions.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/dashboard_summary.dart';
import '../home_actions.dart';
import 'home_section_error.dart';
import 'recent_row.dart';
import 'recent_rows_view.dart';
import 'see_all_button.dart';

/// "Recent transactions": the 5 newest rows plus "See all". Rows open the
/// detail, swipe to edit or delete (with Undo, the same actions as the
/// Transactions tab).
class RecentSection extends ConsumerWidget {
  const RecentSection({
    required this.summary,
    required this.firstIndex,
    required this.onDeleted,
    super.key,
  });

  final AsyncValue<DashboardSummary> summary;
  final int firstIndex;

  /// Called after a swipe delete started (the monkey reacts).
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardSummary? s = summary.value;
    final Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space8,
        AppSpacing.screenPadding,
        AppSpacing.space3,
      ),
      child: Semantics(
        header: true,
        child: const Text('Recent transactions', style: AppTextStyles.title),
      ),
    );
    if (s == null) {
      return Column(
        children: <Widget>[
          header,
          if (summary.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: HomeSectionError(
                message: 'Could not load recent entries.',
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
            )
          else
            for (int i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.space2,
                ),
                child: SkeletonBlock(height: 52),
              ),
        ],
      );
    }
    final List<Category> categories = <Category>[
      ...?ref.watch(expenseCategoriesProvider).value,
      ...?ref.watch(incomeCategoriesProvider).value,
    ];
    final List<RecentRowView> rows = buildRecentRows(
      s.recent,
      categories,
      ref.watch(accountsProvider).value ?? const [],
      ref.watch(todayProvider),
    );
    if (rows.isEmpty) {
      return Column(
        children: <Widget>[
          header,
          const SizedBox(
            height: 320,
            child: EmptyState(
              illustration: 'empty_home',
              title: 'No transactions yet',
              message: 'Tap + to add your first entry.',
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        header,
        for (int i = 0; i < rows.length; i++)
          StaggeredEntrance(
            key: ValueKey<String>('row-${rows[i].entry.id}'),
            index: firstIndex + i,
            child: RecentRow(
              view: rows[i],
              onTap: () =>
                  HomeActions(ref, context).openEntry(rows[i].entry.id),
              onEdit: () => openEditEntry(
                context,
                ref.read(loggerProvider),
                rows[i].entry,
              ),
              onDelete: () => _delete(context, ref, rows[i].entry),
            ),
          ),
        Align(
          alignment: Alignment.center,
          child: SeeAllButton(onTap: HomeActions(ref, context).seeAll),
        ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntry entry,
  ) async {
    onDeleted();
    final bool ok = await deleteEntryWithUndo(
      actions: ref.read(transactionActionsProvider),
      messenger: ScaffoldMessenger.of(context),
      log: ref.read(loggerProvider),
      entry: entry,
    );
    // A refused delete: reload so the swiped row comes back.
    if (!ok) ref.invalidate(dashboardSummaryProvider);
  }
}
