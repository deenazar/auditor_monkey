import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/home/domain/balance_slices.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/balance_doughnut.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/account_fixtures.dart';
import '../../../../support/haptics_probe.dart';
import '../../../../support/widget_harness.dart';

/// Plan section 5.5 balances: PF, SBI, Axis, Hand, Food Card, Old Wallet
/// (positive) and HDFC Card (owed). Outside is zero and gets no slice.
BalanceSlices _plan55() => buildBalanceSlices(<AccountBalance>[
  fixtureBalance(
    fixtureAccount(
      n: 1,
      name: 'Hand',
      type: AccountType.cash,
      colour: 'accountHand',
      sortOrder: 0,
    ),
    234950,
  ),
  fixtureBalance(
    fixtureAccount(n: 2, name: 'SBI', colour: 'accountSbi', sortOrder: 1),
    8000000,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 3,
      name: 'Axis',
      colour: 'accountAxis',
      type: AccountType.bank,
      sortOrder: 2,
    ),
    1790000,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 4,
      name: 'HDFC Card',
      type: AccountType.card,
      colour: 'accountScb',
      sortOrder: 3,
    ),
    -180000,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 5,
      name: 'Food Card',
      type: AccountType.wallet,
      colour: 'accountFoodCard',
      sortOrder: 4,
    ),
    85000,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 6,
      name: 'Outside',
      type: AccountType.other,
      colour: 'accountOutside',
      sortOrder: 5,
    ),
    0,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 7,
      name: 'PF',
      type: AccountType.pf,
      colour: 'accountPf',
      opening: 10000000,
      sortOrder: 6,
    ),
    10000000,
  ),
  fixtureBalance(
    fixtureAccount(
      n: 8,
      name: 'Old Wallet',
      type: AccountType.wallet,
      colour: 'accountHand',
      archived: true,
      sortOrder: 7,
    ),
    30000,
  ),
]);

BalanceSlices _onlyOwed() => buildBalanceSlices(<AccountBalance>[
  fixtureBalance(
    fixtureAccount(n: 4, name: 'HDFC Card', type: AccountType.card),
    -180000,
  ),
]);

BalanceSlices _none() => buildBalanceSlices(<AccountBalance>[]);

void main() {
  group('BalanceDoughnut', () {
    testWidgets('legend rows read as one label each (plan 5.5)', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        height: null,
      );
      expect(find.bySemanticsLabel('PF, ₹1,00,000.00, 50%'), findsOneWidget);
      expect(find.bySemanticsLabel('SBI, ₹80,000.00, 40%'), findsOneWidget);
      expect(find.bySemanticsLabel('Axis, ₹17,900.00, 9%'), findsOneWidget);
      expect(find.bySemanticsLabel('Hand, ₹2,349.50, 1%'), findsOneWidget);
      expect(find.bySemanticsLabel('Other, ₹1,150.00, <1%'), findsOneWidget);
      expect(find.text('Owed −₹1,800.00'), findsOneWidget);
      expect(find.text('ASSETS'), findsOneWidget);
    });

    testWidgets('first tap selects a slice and shows it in the centre', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: opened.add),
        height: null,
      );
      await tester.tap(find.bySemanticsLabel('SBI, ₹80,000.00, 40%'));
      await tester.pump();
      expect(opened, isEmpty, reason: 'the first tap only selects');
      // The centre and the legend row both say SBI.
      expect(find.text('SBI'), findsNWidgets(2));
      expect(find.text('ASSETS'), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('SBI holds 40%'), findsOneWidget);
    });

    testWidgets('second tap on the same slice opens the account', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: opened.add),
        height: null,
      );
      final Finder sbi = find.bySemanticsLabel('SBI, ₹80,000.00, 40%');
      await tester.tap(sbi);
      await tester.pump();
      await tester.tap(sbi);
      await tester.pump();
      expect(opened, <String>[fixtureId(2)]);
    });

    testWidgets('second tap on Other does not open anything', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: opened.add),
        height: null,
      );
      final Finder other = find.bySemanticsLabel('Other, ₹1,150.00, <1%');
      await tester.tap(other);
      await tester.pump();
      await tester.tap(other);
      await tester.pump();
      expect(opened, isEmpty);
    });

    testWidgets('tapping the ring selects the slice under the finger', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        height: null,
      );
      final Finder ring = find.byType(PieChart);
      final Offset centre = tester.getCenter(ring);
      final double size = tester.getSize(ring).width;
      // PF is the first slice (it starts at 12 o'clock and runs clockwise),
      // so 3 o'clock is inside it, in the middle of the ring.
      final double outer = size / 2 - 10;
      final double mid = outer - outer * 0.25 / 2;
      await tester.tapAt(centre + Offset(mid, 0));
      await tester.pump();
      expect(find.text('PF'), findsOneWidget);
    });

    testWidgets('a selected slice pops out by 6pt and others do not', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        height: null,
      );
      await tester.tap(find.bySemanticsLabel('SBI, ₹80,000.00, 40%'));
      await tester.pump();
      final PieChart chart = tester.widget<PieChart>(find.byType(PieChart));
      final List<PieChartSectionData> s = chart.data.sections;
      expect(s[1].radius - s[0].radius, closeTo(6, 0.001));
    });

    testWidgets('the ring sweeps in: a transparent filler exists until done', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        height: null,
      );
      final PieChart start = tester.widget<PieChart>(find.byType(PieChart));
      expect(start.data.sections.length, 6, reason: '5 slices + filler');
      await tester.pumpAndSettle();
      final PieChart done = tester.widget<PieChart>(find.byType(PieChart));
      expect(done.data.sections.length, 5);
    });

    testWidgets('reduce motion: the final ring at once, no filler', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        reduceMotion: true,
        height: null,
      );
      await tester.pump();
      final PieChart chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections.length, 5);
    });

    testWidgets('only debts: the owed line and a mascot moment, no ring', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _onlyOwed(), onOpenAccount: (_) {}),
        height: null,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PieChart), findsNothing);
      expect(find.text('Owed −₹1,800.00'), findsOneWidget);
      expect(find.text('Only debts for now'), findsOneWidget);
    });

    testWidgets('no accounts: a mascot moment explains the empty card', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _none(), onOpenAccount: (_) {}),
        height: null,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PieChart), findsNothing);
      expect(
        find.text('Add an account balance to see it here'),
        findsOneWidget,
      );
    });

    testWidgets('a selection plays a selection haptic', (
      WidgetTester tester,
    ) async {
      final List<String> played = probeHaptics();
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        height: null,
      );
      await tester.tap(find.bySemanticsLabel('Axis, ₹17,900.00, 9%'));
      await tester.pump();
      expect(played, contains('HapticFeedbackType.selectionClick'));
    });

    testWidgets('text scale 2.0 does not overflow', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        BalanceDoughnut(slices: _plan55(), onOpenAccount: (_) {}),
        textScale: 2,
        height: null,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('PF, ₹1,00,000.00, 50%'), findsOneWidget);
    });
  });
}
