import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/money/money.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../transactions/domain/statement_line.dart';
import '../../../transactions/domain/transaction_entry.dart';

/// One statement line (DESIGN "List row"): a 44pt circle with the category
/// icon (transfers: a ⇄ arrow), the name in `bodyStrong`, the signed amount
/// in `caption`, and on the right the date in `body` with the running
/// balance under it in `caption`.
class StatementRow extends StatelessWidget {
  const StatementRow({required this.line, required this.todayKey, super.key});

  final StatementLine line;

  /// `YYYY-MM-DD` of today (decides whether the year is shown).
  final String todayKey;

  /// Name shown for the line: "Groceries", "To Axis" or "From SBI".
  static String titleOf(StatementLine line) {
    if (line.isTransfer) {
      final String other = line.counterpartName ?? 'account';
      return line.isOutgoing ? 'To $other' : 'From $other';
    }
    return line.categoryName ?? 'Entry';
  }

  static AmountKind kindOf(TransactionType type) => switch (type) {
    TransactionType.expense => AmountKind.expense,
    TransactionType.income => AmountKind.income,
    TransactionType.transfer => AmountKind.transfer,
  };

  @override
  Widget build(BuildContext context) {
    final String title = titleOf(line);
    final String date = shortDateLabel(line.entry.date, todayKey: todayKey);
    final AmountKind kind = kindOf(line.entry.type);
    return Semantics(
      label:
          '$title, ${_spoken(kind)} ${formatPaise(line.entry.amount)}, '
          '$date, balance after ${spokenPaise(line.balanceAfter)}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _Leading(line: line),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
                AmountText(
                  paise: line.entry.amount,
                  kind: kind,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(date, style: AppTextStyles.body),
              AmountText(
                paise: line.balanceAfter,
                style: AppTextStyles.caption,
                alignment: AlignmentDirectional.centerEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _spoken(AmountKind kind) => switch (kind) {
    AmountKind.expense => 'expense',
    AmountKind.income => 'income',
    AmountKind.transfer => 'transfer',
    AmountKind.plain => 'amount',
  };
}

class _Leading extends StatelessWidget {
  const _Leading({required this.line});

  final StatementLine line;

  @override
  Widget build(BuildContext context) {
    final IconData icon = line.isTransfer
        ? LucideIcons.arrowLeftRight
        : categoryIconFor(line.categoryIcon ?? '');
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navIndicator,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: AppSizes.iconCircle,
        child: Icon(icon, size: AppSizes.iconInline, color: AppColors.ink),
      ),
    );
  }
}
