import 'package:auditor_monkey/features/quick_add/presentation/widgets/date_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

final DateTime _today = DateTime(2026, 11, 12, 15, 30);
final DateTime _first = DateTime(1900, 1, 1);
final DateTime _last = DateTime(2026, 12, 13);

Future<void> _pump(
  WidgetTester tester, {
  required DateTime selected,
  required ValueChanged<DateTime> onChanged,
  double textScale = 1,
}) => pumpCompact(
  tester,
  DateChips(
    selected: selected,
    today: _today,
    firstDate: _first,
    lastDate: _last,
    onChanged: onChanged,
  ),
  textScale: textScale,
);

void main() {
  testWidgets('today selected: Today is on, calendar shows the icon only', (
    WidgetTester tester,
  ) async {
    await _pump(tester, selected: _today, onChanged: (DateTime _) {});
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
    expect(find.text('12 Nov'), findsNothing);
    expect(find.bySemanticsLabel('Pick another date'), findsOneWidget);
  });

  testWidgets('Yesterday and Today report the day-only dates', (
    WidgetTester tester,
  ) async {
    final List<DateTime> picked = <DateTime>[];
    await _pump(tester, selected: _today, onChanged: picked.add);
    await tester.tap(find.text('Yesterday'));
    await tester.tap(find.text('Today'));
    expect(picked, <DateTime>[DateTime(2026, 11, 11), DateTime(2026, 11, 12)]);
  });

  testWidgets('an older date shows in the calendar pill as "3 Nov"', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      selected: DateTime(2026, 11, 3),
      onChanged: (DateTime _) {},
    );
    expect(find.text('3 Nov'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Pick another date, now 3 Nov'),
      findsOneWidget,
    );
  });

  testWidgets('calendar opens the date picker and reports the day picked', (
    WidgetTester tester,
  ) async {
    final List<DateTime> picked = <DateTime>[];
    await _pump(tester, selected: _today, onChanged: picked.add);
    await tester.tap(find.bySemanticsLabel('Pick another date'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('5'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(picked, <DateTime>[DateTime(2026, 11, 5)]);
  });

  testWidgets('text scale 2.0 wraps the chips without overflow', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      selected: DateTime(2026, 11, 3),
      onChanged: (DateTime _) {},
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.bySemanticsLabel('Yesterday')).height,
      greaterThanOrEqualTo(44),
    );
  });
}
