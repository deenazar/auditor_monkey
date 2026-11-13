import 'package:flutter/material.dart';

import '../../../../core/utils/date_labels.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/category_colours.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/transaction_filter.dart';
import '../filter_presets.dart';
import '../transactions_format.dart';
import 'filter_pill.dart';

/// A titled group of filter pills.
class FilterSection extends StatelessWidget {
  const FilterSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.overline.copyWith(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          child,
        ],
      ),
    );
  }
}

/// Date presets; choosing Custom opens the range picker. [today] is
/// `YYYY-MM-DD`.
class DateSection extends StatelessWidget {
  const DateSection({
    required this.filter,
    required this.today,
    required this.onPreset,
    required this.onCustom,
    super.key,
  });

  final TransactionFilter filter;
  final String today;
  final ValueChanged<DatePreset> onPreset;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final DatePreset? selected = matchPreset(filter, today);
    return FilterSection(
      title: 'DATES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: <Widget>[
              for (final DatePreset p in DatePreset.values)
                FilterPill(
                  label: p.label,
                  selected: p == selected,
                  onTap: () =>
                      p == DatePreset.custom ? onCustom() : onPreset(p),
                ),
            ],
          ),
          if (filter.hasDateRange && selected == DatePreset.custom)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space2),
              child: Text(
                '${shortDateLabel(filter.from ?? today, todayKey: today)} '
                '– ${shortDateLabel(filter.to ?? today, todayKey: today)}',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

/// Expense, Income and Transfer; several can be on.
class TypeSection extends StatelessWidget {
  const TypeSection({required this.types, required this.onToggle, super.key});

  final Set<TransactionType> types;
  final ValueChanged<TransactionType> onToggle;

  @override
  Widget build(BuildContext context) {
    return FilterSection(
      title: 'TYPE',
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: <Widget>[
          for (final TransactionType t in TransactionType.values)
            FilterPill(
              label: kindLabel(t),
              selected: types.contains(t),
              onTap: () => onToggle(t),
            ),
        ],
      ),
    );
  }
}

/// Accounts in their colours; several can be on.
class AccountSection extends StatelessWidget {
  const AccountSection({
    required this.accounts,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<Account> accounts;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return FilterSection(
      title: 'ACCOUNTS',
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: <Widget>[
          for (final Account a in accounts)
            FilterPill(
              label: a.name,
              selected: selected.contains(a.id),
              colour: accountColourFor(a.colour),
              leading: selected.contains(a.id)
                  ? null
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: accountColourFor(a.colour),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(
                        dimension: AppSizes.colourDot / 2,
                      ),
                    ),
              onTap: () => onToggle(a.id),
            ),
        ],
      ),
    );
  }
}

/// Categories grouped by colour group. Hidden when only Transfer is chosen
/// (transfers have no category).
class CategorySection extends StatelessWidget {
  const CategorySection({
    required this.categories,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<Category> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static String _groupLabel(String group) => group == 'income'
      ? 'Income'
      : '${group[0].toUpperCase()}${group.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Category>> byGroup = <String, List<Category>>{};
    for (final Category c in categories) {
      if (c.archived) continue;
      byGroup.putIfAbsent(c.colourGroup.name, () => <Category>[]).add(c);
    }
    return FilterSection(
      title: 'CATEGORIES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String group in categoryGroupOrder)
            if (byGroup[group] case final List<Category> list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _groupLabel(group),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: <Widget>[
                        for (final Category c in list)
                          FilterPill(
                            label: c.name,
                            selected: selected.contains(c.id),
                            onTap: () => onToggle(c.id),
                            leading: CategoryIconCircle(
                              iconName: c.icon,
                              colourGroup: group,
                              size: AppSizes.chipIconCircle,
                              iconSize: AppSizes.iconChip,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
