@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/transactions/application/transactions_list_providers.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_state.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:auditor_monkey/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:auditor_monkey/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart';
import '../../../support/rupee_golden.dart';
import 'transactions_fixtures.dart';

Widget _list() => const Scaffold(body: TransactionsScreen());

Future<void> _pumpList(
  WidgetTester tester,
  String name, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
}) {
  return pumpRupeeGolden(
    tester,
    _list(),
    name,
    overrides: overrides,
    textScale: textScale,
  );
}

Override _detail(TransactionListItem? item, {bool loading = false}) =>
    transactionDetailProvider.overrideWith(
      (Ref ref, String id) => loading
          ? const Stream<TransactionListItem?>.empty()
          : Stream<TransactionListItem?>.value(item),
    );

void main() {
  testWidgets('golden: transactions_list_data', (WidgetTester tester) async {
    await _pumpList(tester, 'transactions_list_data', overrides: txOverrides());
  });

  testWidgets('golden: transactions_list_textscale2', (
    WidgetTester tester,
  ) async {
    await _pumpList(
      tester,
      'transactions_list_textscale2',
      overrides: txOverrides(),
      textScale: 2,
    );
  });

  testWidgets('golden: transactions_list_loading', (WidgetTester tester) async {
    await _pumpList(
      tester,
      'transactions_list_loading',
      overrides: txOverrides(
        listNotifier: FakeListNotifier(
          TransactionsListState.empty,
          never: true,
        ),
      ),
    );
  });

  testWidgets('golden: transactions_empty', (WidgetTester tester) async {
    await _pumpList(
      tester,
      'transactions_empty',
      overrides: txOverrides(list: TransactionsListState.empty),
    );
  });

  testWidgets('golden: transactions_no_results', (WidgetTester tester) async {
    await _pumpList(
      tester,
      'transactions_no_results',
      overrides: txOverrides(
        list: TransactionsListState.empty,
        filter: const TransactionFilter(query: 'zzz'),
      ),
    );
  });

  testWidgets('golden: transactions_error', (WidgetTester tester) async {
    await _pumpList(
      tester,
      'transactions_error',
      overrides: txOverrides(failing: true),
    );
  });

  testWidgets('golden: transactions_swipe_delete_mid_drag', (
    WidgetTester tester,
  ) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(rupeeGoldenApp(_list(), overrides: txOverrides()));
    await tester.pumpAndSettle();
    final Offset rowCentre = tester.getCenter(find.text('Groceries').first);
    final TestGesture gesture = await tester.startGesture(rowCentre);
    for (int i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-16, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    await expectGolden(tester, 'transactions_swipe_delete_mid_drag');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('golden: transactions_filter_sheet', (WidgetTester tester) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(rupeeGoldenApp(_list(), overrides: txOverrides()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    await expectGolden(tester, 'transactions_filter_sheet');
  });

  testWidgets('golden: transactions_filter_sheet_save', (
    WidgetTester tester,
  ) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(rupeeGoldenApp(_list(), overrides: txOverrides()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    final Finder sheetField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(sheetField, 'Food this month');
    await tester.ensureVisible(find.text('Save and apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and apply'));
    await tester.pumpAndSettle();
    await expectGolden(tester, 'transactions_filter_sheet_save');
  });

  testWidgets('golden: transaction_detail_expense', (
    WidgetTester tester,
  ) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: TransactionDetailScreen(transactionId: 'x')),
      'transaction_detail_expense',
      overrides: <Override>[_detail(txSampleItems().first)],
    );
  });

  testWidgets('golden: transaction_detail_transfer', (
    WidgetTester tester,
  ) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: TransactionDetailScreen(transactionId: 'x')),
      'transaction_detail_transfer',
      overrides: <Override>[_detail(txSampleItems()[2])],
    );
  });

  testWidgets('golden: transaction_detail_not_found', (
    WidgetTester tester,
  ) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: TransactionDetailScreen(transactionId: 'x')),
      'transaction_detail_not_found',
      overrides: <Override>[_detail(null)],
    );
  });
}
