import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/today_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/categories_providers.dart';
import '../../categories/domain/category.dart';
import '../application/transactions_list_providers.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_filter.dart';
import 'filter_presets.dart';
import 'transactions_actions.dart';
import 'widgets/filter_sheet_sections.dart';
import 'widgets/save_filter_field.dart';

/// Opens the filter sheet with the Quick Add sheet's spring.
Future<void> showTransactionFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.resolve(context, AppMotion.durationSheetOpen),
      reverseDuration: AppMotion.resolve(context, AppMotion.durationMedium),
      curve: AppMotion.sheetSpringCurve,
      reverseCurve: AppMotion.curveExit,
    ),
    builder: (BuildContext context) => const TransactionFilterSheet(),
  );
}

/// Date presets, types, accounts, categories and "Save as chip". Edits a
/// draft; Apply sets the list filter, Reset clears the draft.
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionFilter _draft = ref
      .read(transactionFilterProvider)
      .withoutQuery();

  void _setDraft(TransactionFilter next) => setState(() => _draft = next);

  void _apply() {
    ref.read(transactionFilterProvider.notifier).setFacets(_draft);
    ref
        .read(loggerProvider)
        .info(
          transactionsLogTag,
          'filter applied, ${_draft.facetCount} facets',
        );
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(loggerProvider).debug(transactionsLogTag, 'filter draft reset');
    _setDraft(TransactionFilter.none);
  }

  void _toggleType(TransactionType t) {
    final Set<TransactionType> next = <TransactionType>{..._draft.types};
    if (!next.add(t)) next.remove(t);
    _setDraft(_draft.copyWith(types: next));
  }

  void _toggleAccount(String id) {
    final Set<String> next = <String>{..._draft.accountIds};
    if (!next.add(id)) next.remove(id);
    _setDraft(_draft.copyWith(accountIds: next));
  }

  void _toggleCategory(String id) {
    final Set<String> next = <String>{..._draft.categoryIds};
    if (!next.add(id)) next.remove(id);
    _setDraft(_draft.copyWith(categoryIds: next));
  }

  void _choosePreset(DatePreset preset, String today) {
    if (matchPreset(_draft, today) == preset) {
      _setDraft(_draft.copyWith(clearDates: true));
      return;
    }
    final DateSpan? span = presetRange(preset, today);
    if (span == null) return;
    _setDraft(_draft.copyWith(from: span.from, to: span.to));
  }

  Future<void> _pickCustom(String today) async {
    final int year = int.parse(today.substring(0, 4));
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(year + 1, 12, 31),
      initialDateRange: _draft.hasDateRange
          ? DateTimeRange(
              start: DateTime.parse(_draft.from ?? today),
              end: DateTime.parse(_draft.to ?? today),
            )
          : null,
    );
    if (picked == null || !mounted) return;
    _setDraft(
      _draft.copyWith(from: dateKey(picked.start), to: dateKey(picked.end)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String today = ref.watch(todayProvider);
    final List<Account> accounts =
        (ref.watch(accountsProvider).value ?? const <Account>[])
            .where((Account a) => !a.archived)
            .toList();
    final List<Category> categories = <Category>[
      ...?ref.watch(expenseCategoriesProvider).value,
      ...?ref.watch(incomeCategoriesProvider).value,
    ];
    final bool transferOnly =
        _draft.types.length == 1 &&
        _draft.types.contains(TransactionType.transfer);
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final double bottom = MediaQuery.paddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Semantics(
              header: true,
              child: const Text('Filters', style: AppTextStyles.title),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DateSection(
                    filter: _draft,
                    today: today,
                    onPreset: (DatePreset p) => _choosePreset(p, today),
                    onCustom: () => _pickCustom(today),
                  ),
                  TypeSection(types: _draft.types, onToggle: _toggleType),
                  AccountSection(
                    accounts: accounts,
                    selected: _draft.accountIds,
                    onToggle: _toggleAccount,
                  ),
                  if (transferOnly)
                    const FilterSection(
                      title: 'CATEGORIES',
                      child: Text(
                        'Transfers have no category.',
                        style: AppTextStyles.caption,
                      ),
                    )
                  else
                    CategorySection(
                      categories: categories,
                      selected: _draft.categoryIds,
                      onToggle: _toggleCategory,
                    ),
                  FilterSection(
                    title: 'SAVE AS CHIP',
                    child: SaveFilterField(
                      filter: _draft,
                      buttonLabel: 'Save and apply',
                      onSaved: _apply,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: <Widget>[
                _ResetButton(onTap: _reset),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: PrimaryButton(label: 'Apply', onPressed: _apply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      semanticLabel: 'Reset filters',
      onTap: onTap,
      child: Container(
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.fill,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          'Reset',
          style: AppTextStyles.button.copyWith(color: AppColors.ink),
        ),
      ),
    );
  }
}
