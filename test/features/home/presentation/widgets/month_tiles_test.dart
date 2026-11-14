import 'package:auditor_monkey/features/home/presentation/widgets/month_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/haptics_probe.dart';
import '../../../../support/widget_harness.dart';

MonthTiles _tiles({
  int? budget = 1300000,
  int? remaining = -1830050,
  VoidCallback? onBudgetTap,
  int income = 6370000,
}) => MonthTiles(
  budget: budget,
  spent: 3130050,
  remaining: remaining,
  income: income,
  onBudgetTap: onBudgetTap,
);

void main() {
  group('MonthTiles', () {
    testWidgets('shows budget, remaining (over budget) and income', (
      WidgetTester tester,
    ) async {
      await pumpThemed(tester, _tiles(), height: null);
      expect(find.text('BUDGET'), findsOneWidget);
      expect(find.text('REMAINING'), findsOneWidget);
      expect(find.text('INCOME'), findsOneWidget);
      expect(find.bySemanticsLabel('Budget, ₹13,000.00'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Remaining: −₹18,300.50, over budget'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Income, ₹63,700.00'), findsOneWidget);
      expect(find.text('over budget'), findsOneWidget);
    });

    testWidgets('positive remaining is plain with the caption "left"', (
      WidgetTester tester,
    ) async {
      await pumpThemed(tester, _tiles(remaining: 50000), height: null);
      expect(find.bySemanticsLabel('Remaining: ₹500.00'), findsOneWidget);
      expect(find.text('left'), findsOneWidget);
    });

    testWidgets('no budget: "No budget yet" and remaining is a dash', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        _tiles(budget: null, remaining: null),
        height: null,
      );
      expect(find.text('No budget yet'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Set a budget (coming soon)'), findsOneWidget);
      expect(find.bySemanticsLabel('Remaining: no budget'), findsOneWidget);
      expect(find.textContaining('₹0.00'), findsNothing);
    });

    testWidgets('tapping the Budget tile calls onBudgetTap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpThemed(tester, _tiles(onBudgetTap: () => taps++), height: null);
      await tester.tap(find.bySemanticsLabel('Budget, ₹13,000.00'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a tile without onBudgetTap does nothing on tap', (
      WidgetTester tester,
    ) async {
      await pumpThemed(tester, _tiles(), height: null);
      await tester.tap(find.bySemanticsLabel('Budget, ₹13,000.00'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('long-press shows the budget and spent sum', (
      WidgetTester tester,
    ) async {
      await pumpThemed(tester, _tiles(), height: null);
      await tester.longPress(find.bySemanticsLabel('Budget, ₹13,000.00'));
      await tester.pumpAndSettle();
      expect(find.text('₹13,000.00 budget − ₹31,300.50 spent'), findsOneWidget);
    });

    testWidgets('a touch plays a press haptic', (WidgetTester tester) async {
      final List<String> played = probeHaptics();
      await pumpThemed(tester, _tiles(), height: null);
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Income, ₹63,700.00')),
      );
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();
      expect(played, contains('HapticFeedbackType.lightImpact'));
    });

    testWidgets(
      'reduce motion: a changed amount shows its final value at once',
      (WidgetTester tester) async {
        await pumpThemed(
          tester,
          _tiles(budget: 1300000),
          reduceMotion: true,
          height: null,
        );
        await pumpThemed(
          tester,
          _tiles(budget: 2000000),
          reduceMotion: true,
          height: null,
        );
        await tester.pump();
        expect(find.bySemanticsLabel('Budget, ₹20,000.00'), findsOneWidget);
      },
    );

    testWidgets('text scale 2.0 does not overflow or clip', (
      WidgetTester tester,
    ) async {
      await pumpThemed(tester, _tiles(), textScale: 2, height: null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Budget, ₹13,000.00'), findsOneWidget);
    });

    for (final double scale in <double>[1, 2]) {
      testWidgets('labels never break mid-word on 360pt at text scale $scale', (
        WidgetTester tester,
      ) async {
        await pumpThemed(
          tester,
          _tiles(),
          textScale: scale,
          width: 360,
          height: null,
        );
        await tester.pumpAndSettle();
        // A single overline line is about 14pt at scale 1. A wrapped
        // label would be two lines, so it is far taller than 1.5 lines.
        for (final String label in <String>['BUDGET', 'REMAINING', 'INCOME']) {
          final double h = tester.getSize(find.text(label)).height;
          expect(h, lessThan(14.3 * scale * 1.5), reason: label);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
