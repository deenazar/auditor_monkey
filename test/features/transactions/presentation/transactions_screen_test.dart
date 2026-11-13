import 'package:auditor_monkey/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_state.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:auditor_monkey/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_pump.dart';
import 'transactions_fixtures.dart';

Future<void> _pumpList(WidgetTester tester) {
  return pumpScreen(
    tester,
    const Scaffold(body: TransactionsScreen()),
    overrides: txOverrides(),
  );
}

void main() {
  testWidgets('groups rows under day headers with daily totals', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Tue 10 Nov'), findsOneWidget);
    // Day totals: 250 + 165 spent on the 12th, 3,100 spent on the 10th.
    expect(find.text('-₹415.00'), findsOneWidget);
    expect(find.text('-₹3,100.00'), findsWidgets);
    expect(find.text('+₹85,000.00'), findsWidgets);
    // Row semantics carry the full label.
    expect(
      find.bySemanticsLabel(
        'Expense, Groceries, -₹250.00, SBI, Milk and bread',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Transfer, SBI → Axis, ₹5,000.00, Card bill'),
      findsOneWidget,
    );
  });

  testWidgets('month summary chips show the month of the list', (
    WidgetTester tester,
  ) async {
    await _pumpList(tester);
    await tester.pumpAndSettle();
    expect(find.text('SPENT'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('NET'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('loads the next page when near the end', (
    WidgetTester tester,
  ) async {
    final FakeListNotifier notifier = FakeListNotifier(
      txListState(<TransactionListItem>[
        for (int i = 1; i <= 40; i++)
          // Newest first, five rows per day (the repository sorts the same way).
          txExpense(
            i,
            100 * i,
            '2026-11-${(12 - (i - 1) ~/ 5).toString().padLeft(2, '0')}',
          ),
      ], hasMore: true),
    );
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(listNotifier: notifier),
    );
    await tester.pumpAndSettle();
    expect(notifier.loadMoreCalls, 0);
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, -4000),
      4000,
    );
    await tester.pumpAndSettle();
    expect(notifier.loadMoreCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('shows the retry row when the next page failed', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(
        list: txListState(txSampleItems(), hasMore: true, loadMoreFailed: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Try again'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Could not load more entries.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('swipe left deletes, then Undo calls undoDelete', (
    WidgetTester tester,
  ) async {
    final FakeActions actions = FakeActions();
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(actions: actions),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.bySemanticsLabel(
        RegExp(r'^Expense, Groceries, -₹250\.00, SBI, Milk and bread'),
      ),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(actions.deleted, <String>[txSampleItems().first.entry.id]);
    expect(find.text('Entry deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(actions.undone, <String>[txSampleItems().first.entry.id]);
    expect(find.text('Entry restored'), findsOneWidget);
  });

  testWidgets('a short swipe springs back without deleting', (
    WidgetTester tester,
  ) async {
    final FakeActions actions = FakeActions();
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(actions: actions),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Groceries').first, const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(actions.deleted, isEmpty);
  });

  testWidgets('swipe right opens Quick Add in edit mode', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Groceries').first, const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddSheet), findsOneWidget);
  });

  testWidgets('rows expose Edit and Delete as semantic actions', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(),
    );
    await tester.pumpAndSettle();
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp(r'^Expense, Groceries, -₹250\.00, SBI, Milk and bread'),
      ),
    );
    final List<int> ids = node.getSemanticsData().customSemanticsActionIds!;
    expect(
      ids,
      containsAll(<int>[
        CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: 'Edit'),
        ),
        CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: 'Delete'),
        ),
      ]),
    );
  });

  testWidgets('empty list invites the first entry', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(list: TransactionsListState.empty),
    );
    await tester.pumpAndSettle();
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Add your first entry'), findsOneWidget);
  });

  testWidgets('no results offers Clear filters', (WidgetTester tester) async {
    final FakeFilterNotifier filters = FakeFilterNotifier(
      const TransactionFilter(query: 'zzz'),
    );
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(
        list: TransactionsListState.empty,
        filterNotifier: filters,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No entries match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(filters.state, TransactionFilter.none);
  });

  testWidgets('loading shows skeleton rows, not the empty state', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(
        listNotifier: FakeListNotifier(
          TransactionsListState.empty,
          never: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No entries yet'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('error shows a friendly message with retry', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(failing: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load entries'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('month follows the list down and back up to the top', (
    WidgetTester tester,
  ) async {
    final List<TransactionListItem> items = <TransactionListItem>[
      for (int i = 1; i <= 40; i++)
        txExpense(
          i,
          100 * i,
          '2026-11-${(12 - (i - 1) ~/ 5).toString().padLeft(2, '0')}',
        ),
      for (int j = 1; j <= 40; j++)
        txExpense(
          40 + j,
          100 * j,
          '2026-10-${(31 - (j - 1) ~/ 5).toString().padLeft(2, '0')}',
        ),
    ];
    await pumpScreen(
      tester,
      const Scaffold(body: TransactionsScreen()),
      overrides: txOverrides(list: txListState(items, hasMore: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);

    final Finder list = find.byType(CustomScrollView).first;
    await tester.fling(list, const Offset(0, -6000), 6000);
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);

    // Back to the very top: no header is above the list top any more, so the
    // month must fall back to the first day (November).
    await tester.fling(list, const Offset(0, 9000), 9000);
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('October 2026'), findsNothing);
  });
}
