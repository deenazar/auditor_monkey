import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/hero_area_chart.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/recent_row.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/summary_card.dart';
import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:auditor_monkey/shared/wow/tilt_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/db_screen.dart';
import '../../../support/fixtures.dart';
import '../../../support/golden.dart';
import '../../../support/home_fixtures.dart';

/// A tall phone, so the whole Home (hero, tiles, rows) is on screen.
void _tallSurface(WidgetTester t) {
  setPhoneSurface(t);
  t.view.physicalSize = const Size(goldenWidth * 2, 1700 * 2);
}

Future<void> _pump(WidgetTester t) async {
  _tallSurface(t);
  await t.pumpWidget(
    goldenApp(
      const Scaffold(body: HomeScreen()),
      overrides: homeOverrides(homeSummary()),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('reference layout: hero, summary card, recent rows', (
    WidgetTester t,
  ) async {
    await _pump(t);
    expect(find.text('NET WORTH'), findsOneWidget);
    expect(find.text('₹1,26,843.00'), findsOneWidget);
    expect(find.byType(HeroAreaChart), findsOneWidget);
    expect(find.byType(AuditorMonkey), findsOneWidget);
    expect(find.byType(SummaryCard), findsOneWidget);
    expect(find.text('+78%'), findsOneWidget);
    expect(find.text('SPENDINGS'), findsOneWidget);
    expect(find.text('SAVINGS'), findsOneWidget);
    expect(find.text('₹18,540.00'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.byType(RecentRow), findsNWidgets(5));
    expect(find.text('SBI to Hand'), findsOneWidget);
    // 78% saved is above the 20% goal.
    expect(find.text('Savings goal reached'), findsOneWidget);
  });

  testWidgets('reduce motion: the summary card does not tilt', (
    WidgetTester t,
  ) async {
    await _pump(t);
    final Finder tilt = find.descendant(
      of: find.byType(SummaryCard),
      matching: find.byType(Tilt3D),
    );
    expect(tilt, findsOneWidget);
    expect(
      find.descendant(of: tilt, matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('long press on a row opens a preview; a tap closes it', (
    WidgetTester t,
  ) async {
    await _pump(t);
    await t.longPress(find.text('Groceries'));
    await t.pumpAndSettle();
    expect(find.text('EXPENSE'), findsOneWidget);
    expect(find.text('Milk and bread'), findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('EXPENSE'), findsNothing);
  });

  testWithEnv('swipe left deletes the entry; Undo brings it back', (
    WidgetTester t,
    env,
  ) async {
    final Account hand = await env.account('Hand');
    final String groceries = await env.seededCategoryId('Groceries', 'expense');
    env.clock.now = goldenNow.millisecondsSinceEpoch;
    await env.transactions.create(
      expenseDraft(accountId: hand.id, categoryId: groceries, date: day),
    );
    await pumpWithEnv(t, env, const Scaffold(body: HomeScreen()));
    _tallSurface(t);
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(find.byType(RecentRow), findsOneWidget);

    await t.drag(find.byType(RecentRow), const Offset(-500, 0));
    await t.pumpAndSettle();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(await env.count('transactions', liveOnly: true), 0);
    expect(find.text('Entry removed'), findsOneWidget);

    await t.tap(find.text('Undo'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(await env.count('transactions', liveOnly: true), 1);
  });
}
