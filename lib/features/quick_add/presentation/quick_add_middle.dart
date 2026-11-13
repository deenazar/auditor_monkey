import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_data_provider.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_view.dart';
import '../domain/quick_add_defaults.dart';
import 'quick_add_details.dart';
import 'quick_add_mapping.dart';
import 'quick_add_pickers.dart';
import 'widgets/category_chip_row.dart';
import 'widgets/quick_add_view_models.dart';
import 'widgets/recent_entries_strip.dart';
import 'widgets/transfer_accounts_row.dart';

/// Skeleton rows shown while the sheet's data loads.
const int _skeletonPills = 4;

/// The scrolling middle of the sheet: recent entries, the category row (or
/// the transfer accounts), and the details. Loading, load error and "no
/// categories" states are drawn here.
class QuickAddMiddle extends ConsumerWidget {
  const QuickAddMiddle({required this.view, super.key});

  final QuickAddView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (view.hasLoadError) {
      // The middle scrolls (unbounded height): the panel gets a fixed height.
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: SizedBox(
          height: AppSizes.quickAddErrorHeight,
          child: ErrorState(
            title: "We couldn't load your accounts.",
            message: 'Please try again. What you typed is kept.',
            onRetry: () => ref.invalidate(quickAddDataProvider),
          ),
        ),
      );
    }
    final QuickAddData? data = view.data;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: _LoadingRows(),
      );
    }

    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final Map<String, int> balances = <String, int>{
      for (final AccountBalance b
          in ref.watch(accountBalancesProvider).value ??
              const <AccountBalance>[])
        b.account.id: b.balance,
    };
    final bool transfer = view.type == TransactionType.transfer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!view.isEditing && data.recent.isNotEmpty) ...<Widget>[
          RecentEntriesStrip(
            entries: recentViewsOf(data),
            onTap: (int i) => n.applyRecent(data.recent[i]),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        if (transfer)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _TransferBlock(data: data, view: view, balances: balances),
          )
        else
          _CategoryBlock(data: data, view: view),
        const SizedBox(height: AppSpacing.sectionGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: QuickAddDetails(view: view, balances: balances),
        ),
        // Air above the pad when the middle scrolls (large text).
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}

/// Expense / income: the "CATEGORY" row, or the empty caption (Q11).
class _CategoryBlock extends ConsumerWidget {
  const _CategoryBlock({required this.data, required this.view});

  final QuickAddData data;
  final QuickAddView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final String? selected = view.current.categoryId;
    if (view.noCategories) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Text(
          'No ${view.type.name} categories to pick.',
          style: AppTextStyles.caption,
        ),
      );
    }
    final List<Category> all = data.categoriesOf(view.type).all;
    final List<CategoryChipData> chips = <CategoryChipData>[
      for (final Category c in visibleCategories(all, selected)) chipDataOf(c),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Text('CATEGORY', style: AppTextStyles.overline),
        ),
        const SizedBox(height: AppSpacing.space2),
        CategoryChipRow(
          chips: chips,
          selectedId: selected,
          onSelected: n.pickCategory,
          onAll: () => openAllCategoriesSheet(
            context,
            categories: <CategoryChipData>[
              for (final Category c in all) chipDataOf(c),
            ],
            selectedId: selected,
            onPicked: n.pickCategory,
          ),
        ),
      ],
    );
  }
}

/// Transfer: From, swap and To.
class _TransferBlock extends ConsumerWidget {
  const _TransferBlock({
    required this.data,
    required this.view,
    required this.balances,
  });

  final QuickAddData data;
  final QuickAddView view;
  final Map<String, int> balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final List<AccountOption> options = accountOptionsOf(
      data.accounts,
      balances,
    );
    final DefaultPicks current = view.current;
    final AccountOption? from = optionById(options, current.accountId);
    final AccountOption? to = optionById(options, current.toAccountId);
    return TransferAccountsRow(
      from: from,
      to: to,
      swapEnabled: from != null && to != null,
      onSwap: n.swapAccounts,
      onPickFrom: () => pickAccountSheet(
        context,
        title: 'From',
        accounts: options,
        selectedId: current.accountId,
        onPicked: n.pickFrom,
      ),
      onPickTo: () => pickAccountSheet(
        context,
        title: 'To',
        accounts: options,
        selectedId: current.toAccountId,
        disabledId: current.accountId,
        onPicked: n.pickTo,
      ),
    );
  }
}

/// Q1: the rows as static `tile` pills that fade in (no shimmer).
class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.durationFast),
      builder: (BuildContext context, double opacity, Widget? child) =>
          Opacity(opacity: opacity, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _pillRow(),
          const SizedBox(height: AppSpacing.sectionGap),
          _pillRow(),
        ],
      ),
    );
  }

  static Widget _pillRow() {
    return Row(
      children: <Widget>[
        for (int i = 0; i < _skeletonPills; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          const Expanded(
            child: SkeletonBlock(
              height: AppSizes.chipHeight,
              borderRadius: AppRadius.pill,
            ),
          ),
        ],
      ],
    );
  }
}
