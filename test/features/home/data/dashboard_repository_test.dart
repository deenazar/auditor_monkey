import 'package:auditor_monkey/core/database/daos/transactions_dao.dart';
import 'package:auditor_monkey/core/database/daos/transactions_dashboard_queries.dart';
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:auditor_monkey/features/home/data/dashboard_repository.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures.dart';
import '../../../support/test_env.dart';

BudgetDraft _budget(String categoryId, String month, int amount) =>
    BudgetDraft(categoryId: categoryId, month: month, amount: amount);

void main() {
  late TestEnv env;
  late DashboardRepository repo;
  late Account hand;
  late String groceries;
  late String rent;
  late String salary;
  late String loanGiven;
  late String loanRepaid;

  setUp(() async {
    env = TestEnv();
    repo = DashboardRepository(env.ctx);
    hand = await env.account('Hand', opening: 100000);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    rent = await env.seededCategoryId('Rent', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
    loanGiven = await env.seededCategoryId('Loan Given', 'expense');
    loanRepaid = await env.seededCategoryId(
      'Loan Repayment Received',
      'income',
    );
  });
  tearDown(() => env.close());

  Future<void> exp(String date, int paise, [String? cat]) =>
      env.transactions.create(
        expenseDraft(
          accountId: hand.id,
          categoryId: cat ?? groceries,
          amount: paise,
          date: date,
        ),
      );

  test('empty database: zeros, 9 strip days, no budget', () async {
    final DashboardSummary s = await repo.load(today: '2026-10-31');
    expect(s.spent, 0);
    expect(s.income, 0);
    expect(s.budgetTotal, 0);
    expect(s.remaining, isNull);
    expect(s.topCategories, isEmpty);
    expect(s.recent, isEmpty);
    expect(s.days, hasLength(9));
    expect(s.days.first.date, '2026-10-23');
    expect(s.days.last.date, '2026-10-31');
    expect(s.month, '2026-10');
  });

  test('month sums, loan rows and loan categories left out (Q1)', () async {
    final Loan loan = await env.loans.create(loanDraft());
    await exp('2026-09-30', 150000); // before
    await exp('2026-10-01', 1500000, rent); // first day
    await exp('2026-10-03', 245050);
    await exp('2026-10-31', 154925); // last day
    await exp('2026-11-01', 80000); // after
    await exp('2026-10-12', 1000000, loanGiven); // loan category, no link
    await env.transactions.create(
      expenseDraft(
        accountId: hand.id,
        categoryId: loanGiven,
        amount: 777700,
        date: '2026-10-13',
        loanId: loan.id,
      ),
    );
    await env.transactions.create(
      incomeDraft(
        accountId: hand.id,
        categoryId: salary,
        amount: 6000000,
        date: '2026-10-01',
      ),
    );
    await env.transactions.create(
      incomeDraft(
        accountId: hand.id,
        categoryId: loanRepaid,
        amount: 400000,
        date: '2026-10-20',
      ),
    );
    final Account other = await env.account('Other');
    await env.transactions.create(transferDraft(from: hand.id, to: other.id));

    final DashboardSummary s = await repo.load(today: '2026-10-31');
    expect(s.spent, 1500000 + 245050 + 154925);
    expect(s.income, 6000000);
    expect(s.topCategories.map((t) => t.categoryId), <String>[rent, groceries]);
    expect(s.topCategories.first.percent, 79); // 1500000 / 1899975
    expect(s.topCategories.last.total, 245050 + 154925);
  });

  test(
    'Dashboard Spent and Income equal the Transactions month summary',
    () async {
      await exp('2026-10-02', 12345);
      await exp('2026-10-09', 1000000, loanGiven);
      await env.transactions.create(
        incomeDraft(
          accountId: hand.id,
          categoryId: loanRepaid,
          amount: 5000,
          date: '2026-10-09',
        ),
      );
      await env.transactions.create(
        incomeDraft(
          accountId: hand.id,
          categoryId: salary,
          amount: 99900,
          date: '2026-10-30',
        ),
      );
      final MonthSummary m = await TransactionsListRepository(env.ctx)
          .monthSummary(TransactionFilter.none, '2026-10');
      final DashboardSummary s = await repo.load(today: '2026-10-31');
      expect(s.spent, m.spent);
      expect(s.income, m.income);
      expect(s.spent, 12345);
      expect(s.income, 99900);
    },
  );

  test('Q2: the whole month counts, also when today is 15 Oct', () async {
    await exp('2026-10-10', 1000);
    await exp('2026-10-20', 2000); // future of 15 Oct
    final DashboardSummary s = await repo.load(today: '2026-10-15');
    expect(s.spent, 3000);
    expect(s.recent.first.date, '2026-10-20'); // Q6: future rows shown
  });

  test('budget total: this month, live only', () async {
    await env.budgets.create(_budget(groceries, '2026-10', 600000));
    await env.budgets.create(_budget(rent, '2026-10', 1000000));
    await env.budgets.create(_budget(groceries, '2026-09', 9999900));
    final deleted = await env.budgets.create(
      _budget(await env.seededCategoryId('Fuel', 'expense'), '2026-10', 300000),
    );
    await env.budgets.softDelete(deleted.id);
    await exp('2026-10-02', 1000);
    final DashboardSummary s = await repo.load(today: '2026-10-31');
    expect(s.budgetTotal, 1600000);
    expect(s.remaining, 1600000 - 1000);
  });

  test('strip: per-day spending, 9 days, loan rows left out', () async {
    await exp('2026-10-26', 70000);
    await exp('2026-10-26', 100);
    await exp('2026-10-28', 120000);
    await exp('2026-10-29', 5000, loanGiven);
    await exp('2026-10-22', 999); // 10 days back: outside
    final DashboardSummary s = await repo.load(today: '2026-10-31');
    expect(s.days.map((d) => d.spent), <int>[
      0,
      0,
      0,
      70100,
      0,
      120000,
      0,
      0,
      0,
    ]);
  });

  test('recent: newest first, limited', () async {
    for (int d = 1; d <= 7; d++) {
      await exp('2026-10-0$d', d * 100);
    }
    final DashboardSummary s = await repo.load(today: '2026-10-31');
    expect(s.recent, hasLength(5));
    expect(s.recent.first.date, '2026-10-07');
    final DashboardSummary two = await repo.load(
      today: '2026-10-31',
      recentLimit: 2,
    );
    expect(two.recent, hasLength(2));
  });

  test('inputs are checked', () async {
    for (final String bad in <String>[
      '',
      '2026-13-01',
      '2026-10',
      'x',
      '2026-02-30',
    ]) {
      await expectLater(
        repo.load(today: bad),
        throwsA(isA<ValidationFailure>()),
        reason: bad,
      );
    }
    for (final int bad in <int>[0, -1, 501]) {
      await expectLater(
        repo.load(today: '2026-10-31', recentLimit: bad),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        repo.load(today: '2026-10-31', topLimit: bad),
        throwsA(isA<ValidationFailure>()),
      );
    }
    await repo.load(today: '2026-10-31', recentLimit: 500, topLimit: 1);
  });

  test('logs "load ok ms=.. rows=.." and never amounts or names', () async {
    await exp('2026-10-02', 123456789);
    await repo.load(today: '2026-10-31');
    final LogRecord r = env.sink.records.lastWhere(
      (LogRecord x) => x.tag == 'dashboard',
    );
    expect(r.message, matches(RegExp(r'^load ok ms=\d+ rows=\d+$')));
    expect(env.sink.allText, isNot(contains('123456789')));
    expect(env.sink.allText, isNot(contains('Groceries')));
  });

  test('a change in budgets fires the signal', () async {
    final Stream<void> signal = repo.watchSignal();
    int ticks = 0;
    final sub = signal.listen((_) => ticks++);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final int before = ticks;
    await env.budgets.create(_budget(groceries, '2026-10', 1000));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ticks, greaterThan(before));
    await sub.cancel();
  });

  group('query plan', () {
    const String a1 = '00000000-0000-4000-8000-0000000000a1';

    Future<String> plan(String sql, List<Variable<Object>> vars) async {
      final rows = await env.db
          .customSelect('EXPLAIN QUERY PLAN $sql', variables: vars)
          .get();
      return rows.map((r) => r.read<String>('detail')).join('\n');
    }

    setUp(() async {
      await env.rawSql(
        'INSERT INTO accounts (id, created_at, updated_at, name, type, '
        "colour, opening_balance) VALUES (?, 1, 1, 'P', 'bank', 'primary', 0)",
        <Object?>[a1],
      );
      await env.rawSql(
        'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
        'WHERE i < 20000) '
        'INSERT INTO transactions (id, created_at, updated_at, sync_status, '
        'type, amount, date, account_id, category_id) '
        "SELECT printf('%036d', i), 1000 + i, 1000 + i, 'pending', "
        "CASE i % 4 WHEN 0 THEN 'income' ELSE 'expense' END, 100 + (i % 500), "
        "'2026-' || printf('%02d', 1 + (i % 12)) || '-' || "
        "printf('%02d', 1 + (i % 28)), '$a1', '$groceries' FROM n",
      );
      await env.rawSql('ANALYZE');
    });

    test(
      'month sums and day strip use ix_tx_date; top categories a date index',
      () async {
        final vars2 = <Variable<Object>>[
          const Variable<String>('2026-10-01'),
          const Variable<String>('2026-10-31'),
        ];
        expect(
          await plan(transactionTotalSql, <Variable<Object>>[
            const Variable<String>('expense'),
            ...vars2,
          ]),
          contains('ix_tx_date'),
        );
        // Grouping by category may walk the (category, date) index; the date
        // range still bounds it, so either date index is fine here.
        expect(
          await plan(expenseByCategorySql, vars2),
          anyOf(contains('ix_tx_date'), contains('ix_tx_category_date')),
        );
        expect(await plan(dashboardDaySpendSql, vars2), contains('ix_tx_date'));
      },
    );
  });
}
