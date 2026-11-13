import 'dart:ui' show Tristate;

import 'package:auditor_monkey/features/quick_add/presentation/widgets/type_tabs.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

/// Hosts [TypeTabs] with a state so taps change the selection.
class _Host extends StatefulWidget {
  const _Host({
    required this.transferEnabled,
    required this.onChanged,
    this.onDisabledTap,
  });

  final bool transferEnabled;
  final ValueChanged<TransactionType> onChanged;
  final VoidCallback? onDisabledTap;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    return TypeTabs(
      selected: _type,
      transferEnabled: widget.transferEnabled,
      onDisabledTap: widget.onDisabledTap,
      onChanged: (TransactionType t) {
        widget.onChanged(t);
        setState(() => _type = t);
      },
    );
  }
}

void main() {
  testWidgets('tapping a tab selects it and reports the change', (
    WidgetTester tester,
  ) async {
    final List<TransactionType> picked = <TransactionType>[];
    await pumpCompact(
      tester,
      _Host(transferEnabled: true, onChanged: picked.add),
    );
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(picked, <TransactionType>[
      TransactionType.income,
      TransactionType.transfer,
    ]);
  });

  testWidgets('tapping the selected tab does not report a change', (
    WidgetTester tester,
  ) async {
    final List<TransactionType> picked = <TransactionType>[];
    await pumpCompact(
      tester,
      _Host(transferEnabled: true, onChanged: picked.add),
    );
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
  });

  testWidgets('selected segment reads as selected; labels are buttons', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      TypeTabs(
        selected: TransactionType.income,
        onChanged: (TransactionType _) {},
      ),
    );
    final SemanticsNode income = tester.getSemantics(
      find.bySemanticsLabel('Income'),
    );
    expect(income.flagsCollection.isSelected, Tristate.isTrue);
    expect(income.flagsCollection.isButton, isTrue);
    expect(income.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    final SemanticsNode expense = tester.getSemantics(
      find.bySemanticsLabel('Expense'),
    );
    expect(expense.flagsCollection.isSelected, Tristate.isFalse);
    expect(find.bySemanticsLabel('Expense'), findsOneWidget);
  });

  testWidgets('disabled Transfer reads "needs two accounts" and shows a hint', (
    WidgetTester tester,
  ) async {
    int disabledTaps = 0;
    final List<TransactionType> picked = <TransactionType>[];
    await pumpCompact(
      tester,
      _Host(
        transferEnabled: false,
        onChanged: picked.add,
        onDisabledTap: () => disabledTaps++,
      ),
    );
    expect(
      find.bySemanticsLabel('Transfer, needs two accounts'),
      findsOneWidget,
    );
    expect(
      find.text('Add a second account to move money between accounts.'),
      findsNothing,
    );

    await tester.tap(find.bySemanticsLabel('Transfer, needs two accounts'));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    expect(disabledTaps, 1);
    expect(
      find.text('Add a second account to move money between accounts.'),
      findsOneWidget,
    );
    // The tab stays where it was.
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Expense'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('the hint clears when another tab is chosen', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _Host(transferEnabled: false, onChanged: (TransactionType _) {}),
    );
    await tester.tap(find.bySemanticsLabel('Transfer, needs two accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(
      find.text('Add a second account to move money between accounts.'),
      findsNothing,
    );
  });

  testWidgets('the indicator slides with durationFast; reduce motion: zero', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      TypeTabs(
        selected: TransactionType.expense,
        onChanged: (TransactionType _) {},
      ),
    );
    expect(
      tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
      AppMotion.durationFast,
    );

    await pumpCompact(
      tester,
      TypeTabs(
        selected: TransactionType.expense,
        onChanged: (TransactionType _) {},
      ),
      reduceMotion: true,
    );
    expect(
      tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
      Duration.zero,
    );
  });

  testWidgets('segments are at least 44 tall; text scale 2.0 stays whole', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      TypeTabs(
        selected: TransactionType.expense,
        onChanged: (TransactionType _) {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.bySemanticsLabel('Transfer')).height,
      greaterThanOrEqualTo(44),
    );
  });
}
