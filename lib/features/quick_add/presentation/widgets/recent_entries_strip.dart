import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/category_colours.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../transactions/domain/transaction_entry.dart';
import 'choice_pill.dart';
import 'quick_add_view_models.dart';

/// "RECENT": one horizontal row of chips for the latest entries. Tapping a
/// chip calls [onTap] with its index (the caller applies it). Hidden when
/// [entries] is empty.
class RecentEntriesStrip extends StatelessWidget {
  const RecentEntriesStrip({
    required this.entries,
    required this.onTap,
    super.key,
  });

  final List<RecentEntryView> entries;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Text('RECENT', style: AppTextStyles.overline),
        ),
        const SizedBox(height: AppSpacing.space2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < entries.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.space2),
                RecentEntryChip(entry: entries[i], onTap: () => onTap(i)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One recent entry: icon circle, label and amount on one line (44 tall).
/// Transfers show the transfer arrow in the `other` tint.
class RecentEntryChip extends StatelessWidget {
  const RecentEntryChip({required this.entry, required this.onTap, super.key});

  final RecentEntryView entry;
  final VoidCallback onTap;

  /// Transfers use the plain kind: the chip's badge already shows the arrow.
  static AmountKind kindOf(TransactionType type) => switch (type) {
    TransactionType.expense => AmountKind.expense,
    TransactionType.income => AmountKind.income,
    TransactionType.transfer => AmountKind.plain,
  };

  @override
  Widget build(BuildContext context) {
    final String? iconName = entry.categoryIcon;
    final bool showCategory =
        entry.type != TransactionType.transfer && iconName != null;
    return ChoicePill(
      selected: false,
      onTap: onTap,
      semanticsLabel:
          'Repeat ${entry.label}, ${formatPaise(entry.amountPaise)}',
      leadingBuilder: (bool _) => showCategory
          ? ChipIconBadge(
              icon: categoryIconFor(iconName),
              fill: categoryGroupTint(entry.colourGroup),
            )
          : ChipIconBadge(
              icon: LucideIcons.arrowLeftRight,
              fill: categoryGroupTint(categoryGroupOther),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.recentLabelMaxWidth,
            ),
            child: Text(
              entry.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          AmountText(
            paise: entry.amountPaise,
            kind: kindOf(entry.type),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
