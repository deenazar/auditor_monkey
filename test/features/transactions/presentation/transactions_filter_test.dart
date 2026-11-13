import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/presentation/filter_sheet.dart';
import 'package:auditor_monkey/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_pump.dart';
import 'transactions_fixtures.dart';

Future<void> _pump(
  WidgetTester tester, {
  FakeFilterNotifier? filters,
  List<SavedFilter> saved = const <SavedFilter>[],
  FakeSavedNotifier? savedNotifier,
  TransactionFilter filter = TransactionFilter.none,
}) {
  return pumpScreen(
    tester,
    const Scaffold(body: TransactionsScreen()),
    overrides: txOverrides(
      filterNotifier: filters,
      filter: filter,
      saved: saved,
      savedNotifier: savedNotifier,
    ),
  );
}

void main() {
  testWidgets('search waits 250 ms before setting the query', (
    WidgetTester tester,
  ) async {
    final FakeFilterNotifier filters = FakeFilterNotifier();
    await _pump(tester, filters: filters);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'milk');
    await tester.pump(const Duration(milliseconds: 200));
    expect(filters.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(filters.queries, <String>['milk']);
  });

  testWidgets('typing again restarts the wait (one query per pause)', (
    WidgetTester tester,
  ) async {
    final FakeFilterNotifier filters = FakeFilterNotifier();
    await _pump(tester, filters: filters);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'm');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'mi');
    await tester.pump(const Duration(milliseconds: 200));
    expect(filters.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(filters.queries, <String>['mi']);
  });

  testWidgets('filter sheet applies dates and a type', (
    WidgetTester tester,
  ) async {
    final FakeFilterNotifier filters = FakeFilterNotifier();
    await _pump(tester, filters: filters);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    final TransactionFilter applied = filters.facetSets.single;
    expect(applied.from, '2026-11-01');
    expect(applied.to, '2026-11-31');
    expect(applied.types, <TransactionType>{TransactionType.expense});
    expect(find.byType(TransactionFilterSheet), findsNothing);
  });

  testWidgets('Reset clears the draft, so Apply sets an empty filter', (
    WidgetTester tester,
  ) async {
    final FakeFilterNotifier filters = FakeFilterNotifier(
      const TransactionFilter(types: <TransactionType>{TransactionType.income}),
    );
    await _pump(tester, filters: filters);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Filters, 1 active')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(filters.facetSets.single.isEmpty, isTrue);
  });

  testWidgets('Save as chip shows the validation message inline', (
    WidgetTester tester,
  ) async {
    final FakeSavedNotifier saved = FakeSavedNotifier(const <SavedFilter>[]);
    await _pump(tester, savedNotifier: saved);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    final Finder sheetField = find.descendant(
      of: find.byType(TransactionFilterSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(sheetField, 'Food');
    await tester.ensureVisible(find.text('Save and apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and apply'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a filter before you save it.'), findsOneWidget);
    expect(saved.added, isEmpty);
  });

  testWidgets('a saved chip applies its filter on tap', (
    WidgetTester tester,
  ) async {
    final FakeFilterNotifier filters = FakeFilterNotifier();
    const SavedFilter food = SavedFilter(
      id: 'chip-food',
      name: 'Food',
      filter: TransactionFilter(
        types: <TransactionType>{TransactionType.expense},
      ),
    );
    await _pump(tester, filters: filters, saved: const <SavedFilter>[food]);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Saved filter Food'));
    await tester.pumpAndSettle();

    expect(filters.applied, <SavedFilter>[food]);
  });

  testWidgets('a long press removes a saved chip after confirm', (
    WidgetTester tester,
  ) async {
    const SavedFilter food = SavedFilter(
      id: 'chip-food',
      name: 'Food',
      filter: TransactionFilter(
        types: <TransactionType>{TransactionType.expense},
      ),
    );
    final FakeSavedNotifier saved = FakeSavedNotifier(const <SavedFilter>[
      food,
    ]);
    await _pump(tester, savedNotifier: saved, saved: const <SavedFilter>[]);
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('Saved filter Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Saved filter Food'), findsNothing);
  });

  testWidgets('Save chip appears while facets are active', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      filter: const TransactionFilter(
        types: <TransactionType>{TransactionType.expense},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
  });
}
