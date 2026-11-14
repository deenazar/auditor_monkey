import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../home/domain/home_format.dart';
import '../../application/transactions_list_providers.dart';
import '../../domain/transaction_list_item.dart';

/// Spent, Income and Net of [month] (`YYYY-MM`) as three compact stat tiles.
/// The amounts roll when the month changes while the list is scrolled.
class MonthSummaryChips extends ConsumerWidget {
  const MonthSummaryChips({required this.month, super.key});

  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MonthSummary summary =
        ref.watch(monthSummaryProvider(month)).value ??
        MonthSummary(month: month);
    return Row(
      children: <Widget>[
        Expanded(
          child: _Amount(paise: summary.spent, label: 'SPENT'),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _Amount(
            paise: summary.income,
            label: 'INCOME',
            colour: AppColors.accentText,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _Amount(
            paise: summary.net,
            label: 'NET',
            colour: summary.net < 0 ? AppColors.danger : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.paise,
    required this.label,
    this.colour = AppColors.ink,
  });

  final int paise;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return StatTile(
      label: label,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space3,
      ),
      child: RollingAmount(
        paise: paise,
        builder: (BuildContext context, int value) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            compactRupees(value),
            maxLines: 1,
            style: AppTextStyles.headline.copyWith(fontSize: 16, color: colour),
          ),
        ),
      ),
    );
  }
}
