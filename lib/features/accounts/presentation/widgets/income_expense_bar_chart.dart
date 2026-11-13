import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../core/utils/date_keys.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../transactions/domain/statement_line.dart';

/// Income-vs-expense bars, one pair per month (DESIGN "Charts"): 6pt pill
/// bars, `primary` for income and `sun` for expense, month labels under
/// the bars and a small legend.
///
/// The bars draw in from zero (`durationChart`, `curveEnter`) and morph
/// when [months] change. With reduce motion the final bars show at once.
/// The chart sits in a `RepaintBoundary`. Each month has one screen-reader
/// label with its income and expense; the drawing itself is hidden from
/// screen readers.
///
/// Money stays in integer paise everywhere. The chart library needs
/// `double` values, and they are only used for bar heights in pixels.
class IncomeExpenseBarChart extends StatefulWidget {
  const IncomeExpenseBarChart({
    required this.months,
    this.chartHeight = AppSizes.statChartHeight,
    this.showLegend = true,
    super.key,
  });

  /// Oldest month first (`YYYY-MM`), e.g. from `accountMonthlyTotalsProvider`.
  final List<MonthlyTotal> months;

  /// Height of the bars area (labels and legend come below it).
  final double chartHeight;
  final bool showLegend;

  @override
  State<IncomeExpenseBarChart> createState() => _IncomeExpenseBarChartState();
}

class _IncomeExpenseBarChartState extends State<IncomeExpenseBarChart> {
  /// False until the first frame is on screen, so the bars start at zero
  /// and grow to their values.
  bool _drawn = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_drawn || _scheduled) return;
    if (AppMotion.reduceMotion(context)) {
      _drawn = true;
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _drawn = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<MonthlyTotal> months = widget.months;
    final int top = months.fold<int>(
      1,
      (int m, MonthlyTotal t) => math.max(m, math.max(t.income, t.expense)),
    );
    // A little head room above the tallest bar.
    final double maxY = (top + top ~/ 10).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: widget.chartHeight,
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: BarChart(
                _data(months, maxY),
                duration: AppMotion.resolve(context, AppMotion.durationChart),
                curve: AppMotion.curveEnter,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: <Widget>[
            for (final MonthlyTotal m in months)
              Expanded(
                child: Semantics(
                  label:
                      '${shortMonthName(m.month)} ${m.month.substring(0, 4)}: '
                      'income ${formatPaise(m.income)}, '
                      'expense ${formatPaise(m.expense)}',
                  child: ExcludeSemantics(
                    child: Text(
                      shortMonthName(m.month),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showLegend) ...<Widget>[
          const SizedBox(height: AppSpacing.space3),
          const _Legend(),
        ],
      ],
    );
  }

  BarChartData _data(List<MonthlyTotal> months, double maxY) {
    double shown(int paise) => _drawn ? paise.toDouble() : 0;
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: maxY,
      barTouchData: const BarTouchData(enabled: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: maxY / 2,
        getDrawingHorizontalLine: (double value) => const FlLine(
          color: AppColors.divider,
          strokeWidth: AppSizes.chartGridLine,
        ),
      ),
      barGroups: <BarChartGroupData>[
        for (int i = 0; i < months.length; i++)
          BarChartGroupData(
            x: i,
            barsSpace: AppSpacing.space1,
            barRods: <BarChartRodData>[
              _rod(shown(months[i].income), AppColors.primary),
              _rod(shown(months[i].expense), AppColors.sun),
            ],
          ),
      ],
    );
  }

  BarChartRodData _rod(double toY, Color colour) => BarChartRodData(
    toY: toY,
    color: colour,
    width: AppSizes.chartBarWidth,
    borderRadius: AppRadius.pill,
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _LegendItem(colour: AppColors.primary, label: 'Income'),
        SizedBox(width: AppSpacing.space6),
        _LegendItem(colour: AppColors.sun, label: 'Expense'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colour,
            borderRadius: AppRadius.pill,
          ),
          child: const SizedBox.square(dimension: AppSizes.stepDot),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
