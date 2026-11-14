import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/logger_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../application/transactions_list_providers.dart';
import '../../domain/transaction_filter.dart';
import '../transactions_actions.dart';
import 'save_filter_dialog.dart';

/// Saved filter chips in one horizontal row. Tap applies a chip (springy
/// select); long press removes it after a confirm. A "Save" chip appears
/// while facets are active.
class SavedFilterChips extends ConsumerWidget {
  const SavedFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SavedFilter> saved =
        ref.watch(savedFiltersProvider).value ?? const <SavedFilter>[];
    final TransactionFilter filter = ref.watch(transactionFilterProvider);
    final bool canSave =
        filter.facetCount > 0 && saved.length < maxSavedFilters;
    if (saved.isEmpty && !canSave) return const SizedBox.shrink();
    final List<Widget> chips = <Widget>[
      for (final SavedFilter s in saved)
        _SavedChip(
          saved: s,
          selected: s.filter.withoutQuery() == filter.withoutQuery(),
        ),
      if (canSave) const _SaveChip(),
    ];
    return SizedBox(
      height: AppSizes.chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: chips.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.space2),
        itemBuilder: (BuildContext context, int index) => chips[index],
      ),
    );
  }
}

class _SavedChip extends ConsumerWidget {
  const _SavedChip({required this.saved, required this.selected});

  final SavedFilter saved;
  final bool selected;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove this chip?'),
        content: Text('"${saved.name}" is removed. Your entries stay.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(loggerProvider).info(transactionsLogTag, 'saved filter removed');
    await ref.read(savedFiltersProvider.notifier).remove(saved.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color ink = selected ? AppColors.onDark : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Saved filter ${saved.name}',
      hint: 'Long press to remove',
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        const CustomSemanticsAction(label: 'Remove chip'): () =>
            _remove(context, ref),
      },
      excludeSemantics: true,
      child: SpringPress(
        scale: 0.95,
        onTap: () {
          ref.read(transactionFilterProvider.notifier).applySaved(saved);
          ref
              .read(loggerProvider)
              .debug(transactionsLogTag, 'saved filter applied');
        },
        onLongPress: () => _remove(context, ref),
        child: _SelectPulse(
          selected: selected,
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.durationMedium),
            curve: AppMotion.curveEnter,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDeep : AppColors.tile,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: selected ? AppColors.primaryDeep : AppColors.divider,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              saved.name,
              maxLines: 1,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 13,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short springy pulse each time a chip becomes selected.
class _SelectPulse extends StatelessWidget {
  const _SelectPulse({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selected || AppMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1),
      duration: AppDepth.press,
      curve: AppDepth.springy,
      builder: (BuildContext context, double scale, Widget? child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

class _SaveChip extends ConsumerWidget {
  const _SaveChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SpringPress(
      semanticLabel: 'Save current filter as a chip',
      onTap: () async {
        final TransactionFilter filter = ref.read(transactionFilterProvider);
        await showSaveFilterDialog(context, filter.withoutQuery());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.primaryLight),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              LucideIcons.bookmarkPlus,
              size: AppSizes.iconChip,
              color: AppColors.accentText,
            ),
            const SizedBox(width: 6),
            Text(
              'Save',
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 13,
                color: AppColors.accentText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
