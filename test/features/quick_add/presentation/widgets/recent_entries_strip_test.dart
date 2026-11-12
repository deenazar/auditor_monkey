import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_view_models.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/recent_entries_strip.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

const List<RecentEntryView> _entries = <RecentEntryView>[
  RecentEntryView(
    type: TransactionType.expense,
    amountPaise: 25000,
    label: 'Groceries',
    categoryIcon: 'shopping-cart',
    colourGroup: 'food',
  ),
  RecentEntryView(
    type: TransactionType.transfer,
    amountPaise: 200000,
    label: 'SBI → Axis',
    colourGroup: 'other',
  ),
  RecentEntryView(
    type: TransactionType.income,
    amountPaise: 120050,
    label: 'Salary',
    categoryIcon: 'banknote',
    colourGroup: 'income',
  ),
];

void main() {
  testWidgets('empty list shows nothing at all', (WidgetTester tester) async {
    await pumpCompact(
      tester,
      RecentEntriesStrip(entries: const <RecentEntryView>[], onTap: (int _) {}),
    );
    expect(find.text('RECENT'), findsNothing);
    expect(tester.getSize(find.byType(RecentEntriesStrip)).height, 0);
  });

  testWidgets('chips show the label, the amount and report their index', (
    WidgetTester tester,
  ) async {
    final List<int> taps = <int>[];
    await pumpCompact(
      tester,
      RecentEntriesStrip(entries: _entries, onTap: taps.add),
    );
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('SBI → Axis'), findsOneWidget);
    expect(find.bySemanticsLabel('Repeat Groceries, ₹250.00'), findsOneWidget);
    expect(find.bySemanticsLabel('Repeat Salary, ₹1,200.50'), findsOneWidget);

    await tester.tap(find.text('SBI → Axis'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary'));
    expect(taps, <int>[1, 2]);
  });

  testWidgets('transfer shows the arrow; income amount in accentText', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      RecentEntriesStrip(entries: _entries, onTap: (int _) {}),
    );
    expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);
    final RichText rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (Widget w) => w is RichText && w.text.toPlainText().contains('+'),
      ),
    );
    expect(rich.text.style?.color, AppColors.accentText);
  });

  testWidgets('text scale 2.0 scrolls the strip, no overflow', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      RecentEntriesStrip(entries: _entries, onTap: (int _) {}),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.bySemanticsLabel('Repeat Groceries, ₹250.00')).height,
      44,
    );
  });
}
