// The October 2026 acceptance numbers (plan section 5.3, 5.5, 5.6, 5.7),
// read through DashboardRepository.load on the hand-built fixture. Every
// value is checked to the paisa, and the formatted text is checked with
// formatPaise.
import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/features/home/data/dashboard_repository.dart';
import 'package:auditor_monkey/features/home/domain/balance_slices.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/home/domain/top_categories.dart';
import 'package:auditor_monkey/features/mascot/domain/mascot_mood.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures/test_month_2026_10.dart';

void main() {
  late TestMonth month;
  late DashboardSummary summary;

  setUp(() async {
    month = await buildTestMonth();
    summary = await DashboardRepository(month.env.ctx)
        .load(today: '2026-10-31');
  });

  tearDown(() async {
    await month.close();
  });

  group('plan 5.3 top cards', () {
    test('This Month Spent is ₹31,300.50', () {
      expect(summary.spent, 3130050);
      expect(formatPaise(summary.spent), '₹31,300.50');
    });

    test('Income is ₹63,700.00 (loan repayment left out)', () {
      expect(summary.income, 6370000);
      expect(formatPaise(summary.income), '₹63,700.00');
    });

    test('Budget is ₹13,000.00 (deleted Rent and September left out)', () {
      expect(summary.budgetTotal, 1300000);
      expect(formatPaise(summary.budgetTotal), '₹13,000.00');
      expect(summary.hasBudget, isTrue);
    });

    test('Remaining is −₹18,300.50, over budget', () {
      expect(summary.remaining, -1830050);
      expect(summary.isOverBudget, isTrue);
      expect(formatPaise(summary.remaining!), '-₹18,300.50');
    });

    test('Saved % is 51 (lime card)', () {
      expect(summary.toHomeSummary().savingsPercent, 51);
    });

    test('mascot mood is worried (spent is over the budget plan)', () {
      expect(summary.mood, MascotMood.worried);
    });

    test(
      'Dashboard spent and income equal the Transactions month summary',
      () async {
        final MonthSummary tab = await TransactionsListRepository(month.env.ctx)
            .monthSummary(const TransactionFilter(), testMonth);
        expect(summary.spent, tab.spent);
        expect(summary.income, tab.income);
      },
    );
  });

  group('plan 5.5 doughnut', () {
    late BalanceSlices slices;

    setUp(() async {
      slices = buildBalanceSlices(await month.env.accounts.getBalances());
    });

    test('assets are ₹2,01,399.50 and owed is −₹1,800.00', () {
      expect(slices.assets, 20139950);
      expect(formatPaise(slices.assets), '₹2,01,399.50');
      expect(slices.owed, -180000);
      expect(formatPaise(slices.owed), '-₹1,800.00');
      expect(slices.hasOwed, isTrue);
    });

    test('4 biggest accounts plus Other, biggest first', () {
      expect(slices.slices.map((BalanceSlice s) => s.label).toList(), <String>[
        'PF',
        'SBI',
        'Axis',
        'Hand',
        'Other',
      ]);
      expect(slices.slices.last.isOther, isTrue);
      expect(slices.slices.last.amount, 115000);
      expect(formatPaise(slices.slices.last.amount), '₹1,150.00');
      expect(slices.slices.last.memberIds.toSet(), <String>{
        month.account('Food Card'),
        month.account('Old Wallet'),
      });
    });

    test('whole percents are 50, 40, 9, 1 and <1% (largest remainder)', () {
      expect(slices.slices.map((BalanceSlice s) => s.percent).toList(), <int>[
        50,
        40,
        9,
        1,
        0,
      ]);
      expect(
        slices.slices.map((BalanceSlice s) => s.percentLabel).toList(),
        <String>['50%', '40%', '9%', '1%', '<1%'],
      );
      expect(slices.slices.last.lessThanOnePercent, isTrue);
      expect(
        slices.slices.fold<int>(0, (int s, BalanceSlice b) => s + b.percent),
        100,
      );
    });

    test('slice amounts add up to the assets', () {
      expect(
        slices.slices.fold<int>(0, (int s, BalanceSlice b) => s + b.amount),
        slices.assets,
      );
    });

    test('Hand is 1% with its amount ₹2,349.50', () {
      final BalanceSlice hand = slices.slices[3];
      expect(hand.label, 'Hand');
      expect(formatPaise(hand.amount), '₹2,349.50');
    });
  });

  group('plan 5.6 top 3 categories (of ₹31,300.50)', () {
    test('Rent 48%, Groceries 17%, Food & Dining 11%', () {
      final List<TopCategoryShare> top = summary.topCategories;
      expect(top.length, 3);
      expect(top.map((TopCategoryShare c) => c.categoryId).toList(), <String>[
        month.category('Rent'),
        month.category('Groceries'),
        month.category('Food & Dining'),
      ]);
      expect(top.map((TopCategoryShare c) => c.total).toList(), <int>[
        1500000,
        545050,
        335000,
      ]);
      expect(formatPaise(top[0].total), '₹15,000.00');
      expect(formatPaise(top[1].total), '₹5,450.50');
      expect(formatPaise(top[2].total), '₹3,350.00');
      expect(top.map((TopCategoryShare c) => c.percentLabel).toList(), <String>[
        '48%',
        '17%',
        '11%',
      ]);
    });

    test('loan given (₹10,000.00) is not in the top 3', () {
      expect(
        summary.topCategories.any(
          (TopCategoryShare c) => c.categoryId == month.category('Loan Given'),
        ),
        isFalse,
      );
    });
  });

  group('plan 5.7 recent', () {
    test('the 5 newest live rows: T21, T20, T18, T17, T16', () {
      expect(summary.recent.map((r) => r.id).toList(), <String>[
        month.tx('T21'),
        month.tx('T20'),
        month.tx('T18'),
        month.tx('T17'),
        month.tx('T16'),
      ]);
    });

    test('the deleted T19 is not shown', () {
      expect(summary.recent.any((r) => r.id == month.tx('T19')), isFalse);
    });
  });
}
