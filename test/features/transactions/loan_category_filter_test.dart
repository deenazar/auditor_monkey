// Regression for Q1: a row in a loan category but WITHOUT a loan link is
// loan money. Every spending / income sum leaves it out (one shared rule,
// notLoanMoneySql); lists and balances still show and count it.
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;
  late Account b;
  late String loanCat;
  late String groceries;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A', opening: 100000);
    b = await env.account('B', opening: 50000);
    loanCat = await env.seededCategoryId('Loan Given', 'expense');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
    );
    // Loan category, no loan_id.
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: loanCat, amount: 30000),
    );
    await env.transactions.create(
      transferDraft(from: a.id, to: b.id, amount: 5000),
    );
  });
  tearDown(() => env.close());

  test('day totals leave the loan-category row out', () async {
    final Map<String, DayTotal> t = await TransactionsListRepository(env.ctx)
        .dayTotals(TransactionFilter.none, <String>[day]);
    expect(t[day]!.expense, 2000);
    expect(t[day]!.income, 0);
  });

  test('month summary leaves it out too', () async {
    final MonthSummary m = await TransactionsListRepository(env.ctx)
        .monthSummary(TransactionFilter.none, '2026-11');
    expect(m.spent, 2000);
  });

  test('the list still shows the loan-category row and the transfer', () async {
    final ListPage p = await TransactionsListRepository(env.ctx)
        .page(TransactionFilter.none);
    expect(p.items, hasLength(3));
    expect(
      p.items.map((TransactionListItem i) => i.entry.type).toSet(),
      containsAll(<TransactionType>[
        TransactionType.expense,
        TransactionType.transfer,
      ]),
    );
    expect(
      p.items.any((TransactionListItem i) => i.entry.categoryId == loanCat),
      isTrue,
    );
    final entries = await env.transactions.page();
    expect(entries, hasLength(3));
  });

  test(
    'the account chart sums leave it out; the transfer is not a sum',
    () async {
      final totals = await env.transactions.monthlyTotalsForAccount(
        a.id,
        fromMonth: '2026-11',
        toMonth: '2026-11',
      );
      expect(totals.single.expense, 2000);
      expect(totals.single.income, 0);
    },
  );

  test('balances and net worth still count it', () async {
    // A: 100000 - 2000 - 30000 - 5000 (transfer out) = 63000; B: 55000.
    final balances = await env.accounts.getBalances();
    final Map<String, int> byName = <String, int>{
      for (final b in balances) b.account.name: b.balance,
    };
    expect(byName['A'], 63000);
    expect(byName['B'], 55000);
    expect(await env.accounts.watchNetWorth().first, 118000);
    expect((await env.accounts.watchBalances().first).length, 2);
  });

  test('spending sums and top categories leave it out', () async {
    expect(
      await env.transactions.expenseTotal(from: '2026-11-01', to: '2026-11-30'),
      2000,
    );
    final cats = await env.transactions.expenseByCategory(
      from: '2026-11-01',
      to: '2026-11-30',
    );
    expect(cats.map((c) => c.categoryId), <String>[groceries]);
  });
}
