import 'package:auditor_monkey/features/accounts/presentation/widgets/statement_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/account_fixtures.dart';
import '../../../../support/widget_harness.dart';

void main() {
  testWidgets('screen reader label has the title, amount, date and balance', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      StatementRow(line: goldenLines().first, todayKey: '2026-11-12'),
    );
    expect(
      find.bySemanticsLabel(
        'Groceries, expense ₹2,340.50, 11 Nov, balance after ₹2,75,360.50',
      ),
      findsOneWidget,
    );
  });

  testWidgets('transfer label says transfer and names the other account', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      StatementRow(line: goldenLines()[2], todayKey: '2026-11-12'),
    );
    expect(
      find.bySemanticsLabel(
        'To Axis, transfer ₹5,000.00, 28 Oct, balance after ₹1,92,701.00',
      ),
      findsOneWidget,
    );
  });
}
