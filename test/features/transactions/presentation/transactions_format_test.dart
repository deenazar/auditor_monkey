import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/presentation/filter_presets.dart';
import 'package:auditor_monkey/features/transactions/presentation/transactions_format.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transactions_fixtures.dart';

void main() {
  group('day headers', () {
    test('Today and Yesterday, then a short date', () {
      expect(dayHeaderLabel('2026-11-12', '2026-11-12'), 'Today');
      expect(dayHeaderLabel('2026-11-11', '2026-11-12'), 'Yesterday');
      expect(dayHeaderLabel('2026-11-10', '2026-11-12'), 'Tue 10 Nov');
    });

    test('adds the year for another year', () {
      expect(dayHeaderLabel('2025-12-31', '2026-11-12'), 'Wed 31 Dec 2025');
    });
  });

  test('month title reads as words', () {
    expect(monthTitle('2026-11'), 'November 2026');
    expect(monthTitle('2026-01-05'), 'January 2026');
  });

  test('row semantics read kind, title, amount, account and note', () {
    expect(
      rowSemanticsLabel(txExpense(1, 25000, '2026-11-12', note: 'Milk')),
      'Expense, Groceries, -₹250.00, SBI, Milk',
    );
    expect(
      rowSemanticsLabel(txExpense(2, 25000, '2026-11-12')),
      'Expense, Groceries, -₹250.00, SBI',
    );
    expect(
      rowSemanticsLabel(txIncome(3, 100, '2026-11-12')),
      'Income, Salary, +₹1.00, SBI',
    );
    expect(
      rowSemanticsLabel(txTransfer(4, 500000, '2026-11-12')),
      'Transfer, SBI → Axis, ₹5,000.00, Transfer',
    );
  });

  test('amount signs follow the type', () {
    expect(amountSign(TransactionType.expense), '-');
    expect(amountSign(TransactionType.income), '+');
    expect(amountSign(TransactionType.transfer), '');
  });

  test('preset ranges and matching', () {
    const String today = '2026-11-12';
    expect(presetRange(DatePreset.thisMonth, today), (
      from: '2026-11-01',
      to: '2026-11-31',
    ));
    expect(presetRange(DatePreset.lastMonth, today), (
      from: '2026-10-01',
      to: '2026-10-31',
    ));
    expect(presetRange(DatePreset.last30Days, today), (
      from: '2026-10-14',
      to: '2026-11-12',
    ));
    expect(presetRange(DatePreset.thisYear, today), (
      from: '2026-01-01',
      to: '2026-12-31',
    ));
    expect(presetRange(DatePreset.custom, today), isNull);

    expect(matchPreset(TransactionFilter.none, today), isNull);
    const TransactionFilter month = TransactionFilter(
      from: '2026-11-01',
      to: '2026-11-31',
    );
    expect(matchPreset(month, today), DatePreset.thisMonth);
    const TransactionFilter odd = TransactionFilter(
      from: '2026-11-03',
      to: '2026-11-09',
    );
    expect(matchPreset(odd, today), DatePreset.custom);
  });
}
