import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/skeleton_block.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../transactions/domain/statement_line.dart';
import 'income_expense_bar_chart.dart';

/// "INCOME VS EXPENSE" stat tile for one account: six months of bars, or a
/// skeleton while loading, or a short message when loading failed or when
/// no month has any entry.
class StatementChartTile extends StatelessWidget {
  const StatementChartTile({
    required this.months,
    this.failed = false,
    super.key,
  });

  /// The months (oldest first), or `null` while they are loading.
  final List<MonthlyTotal>? months;

  /// True when loading the months failed.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final List<MonthlyTotal>? data = months;
    if (failed) {
      return _tile(
        Text(
          "Couldn't load the chart.",
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.danger),
        ),
      );
    }
    if (data == null) {
      return _tile(const SkeletonBlock(height: AppSizes.statChartHeight));
    }
    final bool empty = data.every(
      (MonthlyTotal m) => m.income == 0 && m.expense == 0,
    );
    return _tile(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IncomeExpenseBarChart(months: data),
          if (empty) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            const Text(
              'No income or expense in the last 6 months',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(Widget child) =>
      StatTile(label: 'INCOME VS EXPENSE', child: child);
}
