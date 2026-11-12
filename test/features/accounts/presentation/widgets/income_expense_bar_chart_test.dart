import 'package:auditor_monkey/features/accounts/presentation/widgets/income_expense_bar_chart.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden.dart';

const List<MonthlyTotal> _months = <MonthlyTotal>[
  MonthlyTotal(month: '2026-06', income: 0, expense: 0),
  MonthlyTotal(month: '2026-07', income: 500000, expense: 120000),
  MonthlyTotal(month: '2026-08', income: 0, expense: 250000),
  MonthlyTotal(month: '2026-09', income: 300000, expense: 0),
  MonthlyTotal(month: '2026-10', income: 800000, expense: 400000),
  MonthlyTotal(month: '2026-11', income: 100000, expense: 90000),
];

Widget _chart(List<MonthlyTotal> months) => Scaffold(
  body: Padding(
    padding: const EdgeInsets.all(24),
    child: IncomeExpenseBarChart(months: months),
  ),
);

BarChartData _data(WidgetTester tester) =>
    tester.widget<BarChart>(find.byType(BarChart)).data;

List<double> _rods(WidgetTester tester) => <double>[
  for (final BarChartGroupData g in _data(tester).barGroups)
    for (final BarChartRodData r in g.barRods) r.toY,
];

void main() {
  testWidgets('shows 6 month labels, a legend and two bars per month', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    await tester.pumpAndSettle();
    for (final String m in <String>['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov']) {
      expect(find.text(m), findsOneWidget);
    }
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(_data(tester).barGroups, hasLength(6));
    expect(_rods(tester), hasLength(12));
  });

  testWidgets('bars are 6pt pills: primary income, sun expense', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    await tester.pumpAndSettle();
    final BarChartRodData income = _data(tester).barGroups[1].barRods[0];
    final BarChartRodData expense = _data(tester).barGroups[1].barRods[1];
    expect(income.width, 6);
    expect(income.color, const Color(0xFF70D0B2));
    expect(expense.color, const Color(0xFFFDD85C));
    // The library caps the radius at half the width: a full pill.
    expect(income.borderRadius, BorderRadius.circular(3));
    expect(income.toY, 500000);
    expect(expense.toY, 120000);
  });

  testWidgets('with reduce motion the final bars show on the first frame', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    expect(_rods(tester).where((double v) => v > 0), isNotEmpty);
    expect(
      tester.widget<BarChart>(find.byType(BarChart)).duration,
      Duration.zero,
    );
  });

  testWidgets('without reduce motion the bars start at 0 and draw in', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months), reduceMotion: false));
    expect(_rods(tester).every((double v) => v == 0), isTrue);
    expect(
      tester.widget<BarChart>(find.byType(BarChart)).duration,
      AppMotion.durationChart,
    );
    await tester.pump(); // post-frame callback sets the real values
    expect(_rods(tester).where((double v) => v > 0), isNotEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('all-zero months draw empty bars without crashing', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(
      goldenApp(
        _chart(<MonthlyTotal>[
          for (final String m in <String>['2026-10', '2026-11'])
            MonthlyTotal(month: m, income: 0, expense: 0),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(_rods(tester).every((double v) => v == 0), isTrue);
    expect(_data(tester).maxY, greaterThan(0));
  });

  testWidgets('the chart is in a RepaintBoundary', (WidgetTester tester) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    expect(
      find.ancestor(
        of: find.byType(BarChart),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });

  testWidgets('each month has one screen-reader label; the drawing has none', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Jul 2026: income ₹5,000.00, expense ₹1,200.00'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Jun 2026: income ₹0.00, expense ₹0.00'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('new data morphs: the bars change when months change', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_chart(_months)));
    await tester.pumpAndSettle();
    final List<MonthlyTotal> changed = <MonthlyTotal>[
      ..._months.take(5),
      const MonthlyTotal(month: '2026-11', income: 700000, expense: 0),
    ];
    await tester.pumpWidget(goldenApp(_chart(changed)));
    await tester.pumpAndSettle();
    expect(_data(tester).barGroups[5].barRods[0].toY, 700000);
  });
}
