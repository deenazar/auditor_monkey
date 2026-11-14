import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/home/domain/home_summary.dart';
import 'package:auditor_monkey/features/mascot/domain/mascot_mood.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardSummary _s({int spent = 0, int income = 0, int budget = 0}) =>
    DashboardSummary(
      today: '2026-10-31',
      month: '2026-10',
      days: const <DaySpend>[],
      spent: spent,
      income: income,
      budgetTotal: budget,
      topCategories: const [],
      recent: const [],
    );

void main() {
  test('hand-checked month: remaining is -18,300.50 and over budget', () {
    final DashboardSummary s = _s(
      spent: 3130050,
      income: 6370000,
      budget: 1300000,
    );
    expect(s.remaining, -1830050);
    expect(s.isOverBudget, isTrue);
    expect(s.hasBudget, isTrue);
    expect(s.mood, MascotMood.worried);
    expect(s.toHomeSummary().savingsPercent, 51);
  });

  test('no budget: remaining is null, mood uses income as the plan', () {
    final DashboardSummary s = _s(spent: 100, income: 1000);
    expect(s.hasBudget, isFalse);
    expect(s.remaining, isNull);
    expect(s.isOverBudget, isFalse);
    expect(s.mood, MascotMood.happy);
  });

  test('under budget and exactly on budget', () {
    expect(_s(spent: 500, budget: 1000).remaining, 500);
    final DashboardSummary even = _s(spent: 1000, budget: 1000);
    expect(even.remaining, 0);
    expect(even.isOverBudget, isFalse);
  });

  test('empty month', () {
    expect(_s().isEmptyMonth, isTrue);
    expect(_s(income: 1).isEmptyMonth, isFalse);
  });
}
