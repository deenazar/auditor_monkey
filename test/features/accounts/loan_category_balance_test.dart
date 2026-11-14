// A loan-category row without a loan link still moves the account balance
// and net worth (balances use every live row), while the account's statement
// chart sums leave it out (Q1).
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  test('statement lists the row and its balance; chart sums skip it', () async {
    final TestEnv env = TestEnv();
    addTearDown(env.close);
    final Account a = await env.account('A', opening: 100000);
    final String loanCat = await env.seededCategoryId('Loan Given', 'expense');
    final String salary = await env.seededCategoryId('Salary', 'income');
    final String repaid = await env.seededCategoryId(
      'Loan Repayment Received',
      'income',
    );
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: loanCat, amount: 30000),
    );
    await env.transactions.create(
      incomeDraft(accountId: a.id, categoryId: repaid, amount: 4000),
    );
    await env.transactions.create(
      incomeDraft(accountId: a.id, categoryId: salary, amount: 9000),
    );

    final StatementPage page = await env.transactions.statementPage(a.id);
    expect(page.lines, hasLength(3));
    expect(page.lines.first.balanceAfter, 100000 - 30000 + 4000 + 9000);
    expect(
      page.lines.any(
        (StatementLine l) => l.entry.type == TransactionType.expense,
      ),
      isTrue,
    );

    final totals = await env.transactions.monthlyTotalsForAccount(
      a.id,
      fromMonth: '2026-11',
      toMonth: '2026-11',
    );
    expect(totals.single.expense, 0);
    expect(totals.single.income, 9000);
    expect(await env.accounts.watchNetWorth().first, 83000);
  });
}
