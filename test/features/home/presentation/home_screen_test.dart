import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/home_entry_row.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/week_bars.dart';
import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart';
import '../../../support/home_fixtures.dart';

Future<void> _pump(WidgetTester t, {int budget = 0}) async {
  setPhoneSurface(t);
  await t.pumpWidget(
    goldenApp(
      const Scaffold(body: HomeScreen()),
      overrides: homeOverrides(homeSummary(), budget: budget),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('shows the date, monkey, week bars, chips and entries', (
    WidgetTester t,
  ) async {
    await _pump(t);
    expect(find.text('12'), findsWidgets);
    expect(find.text('THURSDAY'), findsOneWidget);
    expect(find.byType(AuditorMonkey), findsOneWidget);
    expect(find.byType(WeekBars), findsOneWidget);
    expect(find.text('TODAY SPENT'), findsOneWidget);
    expect(find.text('MONTH LEFT'), findsOneWidget);
    expect(find.text('SAVINGS'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(HomeEntryRow), findsNWidgets(5));
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('SBI › Hand'), findsOneWidget);
  });

  testWidgets('a budget changes the chip label', (WidgetTester t) async {
    await _pump(t, budget: 1000000);
    expect(find.text('BUDGET LEFT'), findsOneWidget);
  });

  testWidgets('picking a day filters the list; Recent clears it', (
    WidgetTester t,
  ) async {
    await _pump(t);
    await t.tap(find.bySemanticsLabel(RegExp(r'^Tuesday 10')));
    await t.pumpAndSettle();
    expect(find.text('Tue 10 Nov'), findsOneWidget);
    expect(find.byType(HomeEntryRow), findsNWidgets(2));
    await t.tap(find.bySemanticsLabel('Show recent entries'));
    await t.pumpAndSettle();
    expect(find.byType(HomeEntryRow), findsNWidgets(5));
  });

  testWidgets('a day with nothing shows the empty state', (
    WidgetTester t,
  ) async {
    await _pump(t);
    await t.tap(find.bySemanticsLabel(RegExp(r'^Thursday 5')));
    await t.pumpAndSettle();
    expect(find.text('No entries this day'), findsOneWidget);
  });
}
