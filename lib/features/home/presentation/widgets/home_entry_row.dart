import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../transactions/domain/transaction_entry.dart';

/// What one row shows, already resolved from ids to names.
class HomeEntryView {
  const HomeEntryView({
    required this.entry,
    required this.title,
    required this.meta,
    required this.iconName,
    required this.colourGroup,
  });

  final TransactionEntry entry;
  final String title;
  final String meta;
  final String iconName;
  final String colourGroup;
}

/// mini_checklist `.tile` / `.row`: white card, 1px line, 18 corners, an
/// icon circle, title + meta, the amount in DM Mono on the right
/// (expense `-₹`, income `+₹` in green, transfer `⇄` in grey).
class HomeEntryRow extends StatelessWidget {
  const HomeEntryRow({required this.view, super.key});

  final HomeEntryView view;

  @override
  Widget build(BuildContext context) {
    final TransactionEntry e = view.entry;
    final (String sign, Color colour, String kind) = switch (e.type) {
      TransactionType.expense => ('-', AppColors.ink, 'Expense'),
      TransactionType.income => ('+', AppColors.success, 'Income'),
      TransactionType.transfer => ('', AppColors.inkMuted, 'Transfer'),
    };
    final String amount = '$sign${formatPaise(e.amount)}';
    return Semantics(
      container: true,
      label: '$kind, ${view.title}, $amount, ${view.meta}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 14, 9),
            child: Row(
              children: <Widget>[
                if (e.type == TransactionType.transfer)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.fill,
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
                const SizedBox(width: 12),
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
                        view.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: AppTextStyles.amount.copyWith(
                    fontSize: 14,
                    color: colour,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
