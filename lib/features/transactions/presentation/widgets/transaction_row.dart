import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../../shared/wow/swipe_action_row.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/transaction_list_item.dart';
import '../transactions_format.dart';

/// One entry in the list (DESIGN "List row", with swipe actions from
/// `SwipeActionRow`: right = Edit, left = Delete). Tap opens the detail. Screen readers get the full label and the Edit and Delete
/// actions, so nothing depends on the swipe.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final TransactionListItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Deletes the entry. `true` once it is removed.
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final TransactionEntry e = item.entry;
    final Color colour = switch (e.type) {
      TransactionType.expense => AppColors.ink,
      TransactionType.income => AppColors.accentText,
      TransactionType.transfer => AppColors.inkMuted,
    };
    return Semantics(
      container: true,
      button: true,
      label: rowSemanticsLabel(item),
      onTap: onTap,
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        const CustomSemanticsAction(label: 'Edit'): onEdit,
        const CustomSemanticsAction(label: 'Delete'): () => onDelete(),
      },
      excludeSemantics: true,
      child: SwipeActionRow(
        id: e.id,
        start: SwipeAction(
          icon: LucideIcons.pencil,
          label: 'Edit',
          colour: AppColors.primaryDeep,
          onTrigger: onEdit,
        ),
        end: SwipeAction(
          icon: LucideIcons.trash2,
          label: 'Delete',
          colour: AppColors.swipeDelete,
          removesRow: true,
          onTrigger: () => unawaited(onDelete()),
        ),
        // Opaque, so the swipe panel only shows where the row has moved.
        child: ColoredBox(
          color: AppColors.background,
          child: SpringPress(
            scale: 0.98,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space1,
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: <Widget>[
                    if (e.type == TransactionType.transfer)
                      const _TransferBadge()
                    else
                      CategoryIconCircle(
                        iconName: item.categoryIcon ?? '',
                        colourGroup:
                            item.categoryColourGroup ??
                            (e.type == TransactionType.income
                                ? 'income'
                                : 'other'),
                      ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (e.type == TransactionType.transfer)
                            _TransferTitle(item: item)
                          else
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyStrong,
                            ),
                          Text(
                            rowMeta(item).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      signedAmount(e),
                      maxLines: 1,
                      style: AppTextStyles.tabular(AppTextStyles.bodyStrong)
                          .copyWith(color: colour),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "SBI → Axis" with an arrow icon (the bundled fonts have no arrow glyph).
class _TransferTitle extends StatelessWidget {
  const _TransferTitle({required this.item});

  final TransactionListItem item;

  @override
  Widget build(BuildContext context) {
    // Text (not a Row) so a long pair of names wraps to a second line at
    // large text sizes instead of truncating.
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: item.accountName),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: ExcludeSemantics(
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          TextSpan(text: item.toAccountName ?? ''),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyStrong,
    );
  }
}

class _TransferBadge extends StatelessWidget {
  const _TransferBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navIndicator,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: AppSizes.iconCircle,
        child: Icon(
          LucideIcons.arrowLeftRight,
          size: AppSizes.iconInline,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
