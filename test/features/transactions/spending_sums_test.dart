import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;
  late Account b;
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A');
    b = await env.account('B');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<int> expenseNov() =>
      env.transactions.expenseTotal(from: '2026-11-01', to: '2026-11-30');
  Future<int> incomeNov() =>
      env.transactions.incomeTotal(from: '2026-11-01', to: '2026-11-30');

  test('transfers are absent from expense and income sums', () async {
    await env.transactions.create(transferDraft(from: a.id, to: b.id));
    expect(await expenseNov(), 0);
    expect(await incomeNov(), 0);
    expect(
      await env.transactions.expenseByCategory(
        from: '2026-11-01',
        to: '2026-11-30',
      ),
      isEmpty,
    );
  });

  test('sums only count the chosen dates (inclusive)', () async {
    for (final String d in <String>[
      '2026-10-31',
      '2026-11-01',
      '2026-11-30',
      '2026-12-01',
    ]) {
      await env.transactions.create(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 100,
          date: d,
        ),
      );
    }
    expect(await expenseNov(), 200);
  });

  test('deleted entries are left out and restore adds them back', () async {
    final t = await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: groceries, amount: 500),
    );
    expect(await expenseNov(), 500);
    await env.transactions.softDelete(t.id);
    expect(await expenseNov(), 0);
    await env.transactions.restore(t.id);
    expect(await expenseNov(), 500);
  });

  test(
    'loan-linked entries are left out of spending and top categories',
    () async {
      final Loan lent = await env.loans.create(loanDraft());
      final String loanGiven = await env.seededCategoryId(
        'Loan Given',
        'expense',
      );
      final String loanBack = await env.seededCategoryId(
        'Loan Repayment Received',
        'income',
      );
      await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 300),
      );
      await env.transactions.create(
        expenseDraft(
          accountId: a.id,
          categoryId: loanGiven,
          amount: 90000,
          loanId: lent.id,
        ),
      );
      await env.transactions.create(
        incomeDraft(
          accountId: a.id,
          categoryId: loanBack,
          amount: 40000,
          loanId: lent.id,
        ),
      );
      await env.transactions.create(
        incomeDraft(accountId: a.id, categoryId: salary, amount: 700),
      );
      expect(await expenseNov(), 300);
      expect(await incomeNov(), 700);
      final List<CategoryTotal> top = await env.transactions.expenseByCategory(
        from: '2026-11-01',
        to: '2026-11-30',
      );
      expect(top.single.categoryId, groceries);
      expect(top.single.total, 300);
    },
  );

  test('top categories are sorted, limited and exclude income', () async {
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: groceries, amount: 100),
    );
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: fuel, amount: 900),
    );
    await env.transactions.create(
      expenseDraft(accountId: b.id, categoryId: fuel, amount: 100),
    );
    await env.transactions.create(
      incomeDraft(accountId: a.id, categoryId: salary, amount: 99999),
    );
    final List<CategoryTotal> all = await env.transactions.expenseByCategory(
      from: '2026-11-01',
      to: '2026-11-30',
    );
    expect(
      all.map((CategoryTotal t) => (t.categoryId, t.total)),
      <(String, int)>[(fuel, 1000), (groceries, 100)],
    );
    final List<CategoryTotal> one = await env.transactions.expenseByCategory(
      from: '2026-11-01',
      to: '2026-11-30',
      limit: 1,
    );
    expect(one.single.categoryId, fuel);
  });

  test('the total stream updates when an entry is added', () async {
    final List<int> seen = <int>[];
    final sub = env.transactions
        .watchExpenseTotal(from: '2026-11-01', to: '2026-11-30')
        .listen(seen.add);
    await pumpEventQueue();
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: groceries, amount: 250),
    );
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 250);
  });

  test('a bad date range is a validation failure', () async {
    await expectLater(
      env.transactions.expenseTotal(from: '2026-11-30', to: '2026-11-01'),
      throwsA(anything),
    );
    await expectLater(
      env.transactions.expenseTotal(from: 'x', to: '2026-11-01'),
      throwsA(anything),
    );
  });
}
