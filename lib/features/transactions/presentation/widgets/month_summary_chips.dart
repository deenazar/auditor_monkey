import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../home/domain/home_format.dart';
import '../../../home/presentation/widgets/stat_chip.dart';
import '../../application/transactions_list_providers.dart';
import '../../domain/transaction_list_item.dart';

/// Spent, Income and Net of [month] (`YYYY-MM`) as three glass chips. The
/// amounts roll when the month changes while the list is scrolled.
class MonthSummaryChips extends ConsumerWidget {
  const MonthSummaryChips({required this.month, super.key});

  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MonthSummary summary =
        ref.watch(monthSummaryProvider(month)).value ??
        MonthSummary(month: month);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _Amount(paise: summary.spent, label: 'Spent'),
        _Amount(paise: summary.income, label: 'Income'),
        _Amount(
          paise: summary.net,
          label: 'Net',
          valueColour: summary.net < 0
              ? AppColors.todayBarTop
              : AppColors.glassInk,
        ),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.paise,
    required this.label,
    this.valueColour = AppColors.glassInk,
  });

  final int paise;
  final String label;
  final Color valueColour;

  @override
  Widget build(BuildContext context) {
    return RollingAmount(
      paise: paise,
      builder: (BuildContext context, int value) => StatChip(
        value: compactRupees(value),
        label: label,
        valueColour: valueColour,
      ),
    );
  }
}
