import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/transaction_list_item.dart';
import '../transactions_format.dart';

/// A day's heading in the list: `Today`, `Yesterday` or `Thu 12 Nov`, with
/// the day's spent (ink, `-₹`) and income (success, `+₹`) on the right. The
/// whole-day total comes from the list state, so it is right even for rows
/// that are not loaded yet.
class DayHeader extends StatelessWidget {
  const DayHeader({required this.group, required this.today, super.key});

  final DayGroup group;

  /// `YYYY-MM-DD` of today, for the label.
  final String today;

  @override
  Widget build(BuildContext context) {
    final DayTotal total = group.total;
    final String label = dayHeaderLabel(group.date, today);
    return Semantics(
      header: true,
      label:
          '$label, ${dayTotalSpoken(total.expense, total.income)}'
          '${total.expense == 0 && total.income == 0 ? ', no money in or out' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.space4, 4, 6),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
              ),
            ),
            if (total.expense > 0 || total.income > 0) ...<Widget>[
              const SizedBox(width: AppSpacing.space2),
              // Totals shrink to fit (large text) instead of pushing the label.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (total.expense > 0)
                        Text(
                          '-${formatPaise(total.expense)}',
                          maxLines: 1,
                          style: AppTextStyles.amountSmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      if (total.expense > 0 && total.income > 0)
                        const SizedBox(width: AppSpacing.space2),
                      if (total.income > 0)
                        Text(
                          '+${formatPaise(total.income)}',
                          maxLines: 1,
                          style: AppTextStyles.amountSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
