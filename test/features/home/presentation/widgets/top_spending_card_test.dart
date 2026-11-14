import 'package:auditor_monkey/features/home/presentation/widgets/top_spending_card.dart';
import 'package:auditor_monkey/shared/widgets/app_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/haptics_probe.dart';
import '../../../../support/widget_harness.dart';

const List<TopSpendingItem> _plan56 = <TopSpendingItem>[
  TopSpendingItem(
    categoryId: 'cat-rent',
    name: 'Rent',
    iconName: 'home',
    colourGroup: 'essentials',
    amount: 1500000,
    percent: 48,
  ),
  TopSpendingItem(
    categoryId: 'cat-groceries',
    name: 'Groceries',
    iconName: 'shopping-cart',
    colourGroup: 'essentials',
    amount: 545050,
    percent: 17,
  ),
  TopSpendingItem(
    categoryId: 'cat-dining',
    name: 'Food & Dining',
    iconName: 'utensils',
    colourGroup: 'food',
    amount: 335000,
    percent: 11,
  ),
];

void main() {
  group('TopSpendingCard', () {
    testWidgets('three rows with their amount and share (plan 5.6)', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        height: null,
      );
      await tester.pumpAndSettle();
      expect(find.text('Top spending'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Rent, ₹15,000.00, 48% of spending'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Groceries, ₹5,450.50, 17% of spending'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Food & Dining, ₹3,350.00, 11% of spending'),
        findsOneWidget,
      );
      expect(find.text('48%'), findsOneWidget);
    });

    testWidgets('tapping a row calls onOpenCategory with its id', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: opened.add),
        height: null,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Groceries, ₹5,450.50, 17% of spending'),
      );
      await tester.pumpAndSettle();
      expect(opened, <String>['cat-groceries']);
    });

    testWidgets('a tap plays a selection haptic', (WidgetTester tester) async {
      final List<String> played = probeHaptics();
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        height: null,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Rent, ₹15,000.00, 48% of spending'),
      );
      await tester.pumpAndSettle();
      expect(played, contains('HapticFeedbackType.selectionClick'));
    });

    testWidgets('long-press shows the row preview', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        height: null,
      );
      await tester.pumpAndSettle();
      await tester.longPress(
        find.bySemanticsLabel('Rent, ₹15,000.00, 48% of spending'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rent, ₹15,000.00, 48% of spending'), findsWidgets);
    });

    testWidgets('no spending: the empty illustration and a short line', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(
          items: const <TopSpendingItem>[],
          onOpenCategory: (_) {},
        ),
        height: null,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppIllustration), findsOneWidget);
      expect(find.text('No spending this month yet'), findsOneWidget);
    });

    testWidgets('reduce motion: bars are full at once', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        reduceMotion: true,
        height: null,
      );
      await tester.pump();
      final Iterable<Transform> bars = tester.widgetList<Transform>(
        find.byWidgetPredicate(
          (Widget w) => w is Transform && w.alignment == Alignment.centerLeft,
        ),
      );
      expect(bars, isNotEmpty);
      for (final Transform t in bars) {
        expect(t.transform.storage[0], 1.0);
      }
    });

    testWidgets('bars grow in, staggered, when motion is on', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        height: null,
      );
      await tester.pump(const Duration(milliseconds: 50));
      final List<double> scales = tester
          .widgetList<Transform>(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Transform && w.alignment == Alignment.centerLeft,
            ),
          )
          .map((Transform t) => t.transform.storage[0])
          .toList();
      expect(scales.length, 3);
      expect(scales.first, lessThan(1.0));
      await tester.pumpAndSettle();
    });

    testWidgets('text scale 2.0 does not overflow', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        TopSpendingCard(items: _plan56, onOpenCategory: (_) {}),
        textScale: 2,
        height: null,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Rent, ₹15,000.00, 48% of spending'),
        findsOneWidget,
      );
    });
  });
}
