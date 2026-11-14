import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../../shared/wow/long_press_preview.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../../shared/wow/swipe_action_row.dart';
import '../../../transactions/domain/transaction_entry.dart';

/// What one recent row shows, resolved from ids to names.
class RecentRowView {
  const RecentRowView({
    required this.entry,
    required this.title,
    required this.account,
    required this.date,
    required this.iconName,
    required this.colourGroup,
  });

  final TransactionEntry entry;
  final String title;
  final String account;

  /// Short label, e.g. "Today" or "12 Nov".
  final String date;
  final String iconName;
  final String colourGroup;

  String get signedAmount => switch (entry.type) {
    TransactionType.expense => '−${formatPaise(entry.amount)}',
    TransactionType.income => '+${formatPaise(entry.amount)}',
    TransactionType.transfer => formatPaise(entry.amount),
  };
}

/// DESIGN.md list row: 44pt icon circle, name in `bodyStrong`, amount
/// below in `caption`, date on the right in `body`.
///
/// Motion & 3D: swipe left to delete, swipe right to edit (haptic at the
/// threshold, like the Transactions rows), springy tap that opens the
/// detail, long-press for a preview card.
class RecentRow extends StatelessWidget {
  const RecentRow({
    required this.view,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    super.key,
  });

  final RecentRowView view;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SwipeActionRow(
      id: 'recent-${view.entry.id}',
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
        onTrigger: onDelete,
      ),
      child: LongPressPreview(
        preview: (_) => _Preview(view: view),
        child: SpringPress(
          scale: 0.98,
          onTap: onTap,
          child: _RowBody(view: view),
        ),
      ),
    );
  }
}

class _RowBody extends StatelessWidget {
  const _RowBody({required this.view});

  final RecentRowView view;

  @override
  Widget build(BuildContext context) {
    final bool transfer = view.entry.type == TransactionType.transfer;
    return Semantics(
      container: true,
      label:
          '${view.title}, ${view.signedAmount}, ${view.account}, ${view.date}',
      excludeSemantics: true,
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.space2 + 2,
          ),
          child: Row(
            children: <Widget>[
              if (transfer)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.tile,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: AppSizes.iconCircle,
                    child: Icon(
                      LucideIcons.arrowLeftRight,
                      size: AppSizes.iconInline,
                      color: AppColors.inkMuted,
                    ),
                  ),
                )
              else
                CategoryIconCircle(
                  iconName: view.iconName,
                  colourGroup: view.colourGroup,
                ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      view.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      view.signedAmount,
                      style: AppTextStyles.caption.copyWith(
                        color: view.entry.type == TransactionType.income
                            ? AppColors.accentText
                            : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(view.date, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.view});

  final RecentRowView view;

  @override
  Widget build(BuildContext context) {
    final String kind = switch (view.entry.type) {
      TransactionType.expense => 'Expense',
      TransactionType.income => 'Income',
      TransactionType.transfer => 'Transfer',
    };
    final String note = (view.entry.note ?? '').trim();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(kind.toUpperCase(), style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.space2),
          Text(
            view.signedAmount,
            style: AppTextStyles.displayAmount,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(view.title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.space1),
          Text('${view.account} · ${view.date}', style: AppTextStyles.caption),
          if (note.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            Text(note, style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
