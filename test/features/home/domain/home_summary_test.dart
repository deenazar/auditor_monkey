import 'package:auditor_monkey/features/home/domain/home_summary.dart';
import 'package:auditor_monkey/features/mascot/domain/mascot_mood.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

HomeSummary _summary({int spent = 0, int income = 0, int today = 0}) =>
    HomeSummary(
      today: '2026-11-12',
      days: <DaySpend>[
        for (int i = 4; i <= 12; i++)
          DaySpend(
            date: '2026-11-${i.toString().padLeft(2, '0')}',
            spent: i == 12 ? today : i * 100,
          ),
      ],
      monthSpent: spent,
      monthIncome: income,
      recent: const <TransactionEntry>[],
    );

void main() {
  test('today, week and spentOn come from the nine days', () {
    final HomeSummary s = _summary(today: 4200);
    expect(s.days, hasLength(HomeSummary.stripDays));
    expect(s.todaySpent, 4200);
    expect(s.week, hasLength(7));
    expect(s.week.first.date, '2026-11-06');
    expect(s.spentOn('2026-11-05'), 500);
    expect(s.spentOn('2026-10-01'), isNull);
  });

  test('plan is the budget when set, else income', () {
    final HomeSummary s = _summary(spent: 30000, income: 100000);
    expect(s.plan(50000), 50000);
    expect(s.monthLeft(50000), 20000);
    expect(s.plan(0), 100000);
    expect(s.monthLeft(0), 70000);
  });

  test('savings percent is rounded and null without income', () {
    expect(_summary(spent: 25000, income: 100000).savingsPercent, 75);
    expect(_summary(spent: 150000, income: 100000).savingsPercent, -50);
    expect(_summary(spent: 100).savingsPercent, isNull);
  });

  test('budget state and the monkey mood', () {
    expect(_summary().budgetState(0), BudgetState.none);
    expect(_summary().mood(0), MascotMood.idle);
    expect(_summary(spent: 100).budgetState(0), BudgetState.over);
    expect(_summary(spent: 10000).budgetState(50000), BudgetState.under);
    expect(_summary(spent: 10000).mood(50000), MascotMood.happy);
    expect(_summary(spent: 40000).budgetState(50000), BudgetState.near);
    expect(_summary(spent: 40000).mood(50000), MascotMood.idle);
    expect(_summary(spent: 50001).budgetState(50000), BudgetState.over);
    expect(_summary(spent: 50001).mood(50000), MascotMood.worried);
    expect(_summary(spent: 120000, income: 100000).mood(0), MascotMood.worried);
  });
}
