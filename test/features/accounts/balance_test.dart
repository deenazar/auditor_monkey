import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account hand;
  late Account sbi;
  late Account card;
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = TestEnv();
    hand = await env.account('Hand', type: AccountType.cash, opening: 100000);
    sbi = await env.account('SBI', opening: 5000000);
    card = await env.account('Card', type: AccountType.card, opening: -20000);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<Map<String, int>> balances() async {
    final List<AccountBalance> list = await env.accounts.getBalances();
    return <String, int>{
      for (final AccountBalance b in list) b.account.name: b.balance,
    };
  }

  test('with no entries the balance is the opening balance', () async {
    expect(await balances(), <String, int>{
      'Hand': 100000,
      'SBI': 5000000,
      'Card': -20000,
    });
  });

  test('opening + income - expense - transfers out + transfers in', () async {
    await env.transactions.create(
      incomeDraft(accountId: sbi.id, categoryId: salary, amount: 8000000),
    );
    await env.transactions.create(
      expenseDraft(accountId: sbi.id, categoryId: groceries, amount: 250050),
    );
    await env.transactions.create(
      expenseDraft(accountId: hand.id, categoryId: fuel, amount: 30000),
    );
    await env.transactions.create(
      transferDraft(from: sbi.id, to: hand.id, amount: 1000000),
    );
    await env.transactions.create(
      transferDraft(from: sbi.id, to: card.id, amount: 20000),
    );
    await env.transactions.create(
      expenseDraft(accountId: card.id, categoryId: groceries, amount: 7500),
    );

    expect(await balances(), <String, int>{
      // 100000 - 30000 + 1000000
      'Hand': 1070000,
      // 5000000 + 8000000 - 250050 - 1000000 - 20000
      'SBI': 11729950,
      // -20000 + 20000 - 7500
      'Card': -7500,
    });
  });

  test(
    'a transfer changes both balances and leaves net worth unchanged',
    () async {
      final int before = await env.accounts.watchNetWorth().first;
      expect(before, 100000 + 5000000 - 20000);
      await env.transactions.create(
        transferDraft(from: sbi.id, to: hand.id, amount: 123456),
      );
      final Map<String, int> after = await balances();
      expect(after['SBI'], 5000000 - 123456);
      expect(after['Hand'], 100000 + 123456);
      expect(await env.accounts.watchNetWorth().first, before);
    },
  );

  test('net worth moves with income and expense', () async {
    final int before = await env.accounts.watchNetWorth().first;
    await env.transactions.create(
      incomeDraft(accountId: hand.id, categoryId: salary, amount: 700),
    );
    await env.transactions.create(
      expenseDraft(accountId: hand.id, categoryId: fuel, amount: 200),
    );
    expect(await env.accounts.watchNetWorth().first, before + 500);
  });

  test('deleted entries and deleted accounts are left out', () async {
    final TransactionEntry t = await env.transactions.create(
      expenseDraft(accountId: hand.id, categoryId: fuel, amount: 40000),
    );
    expect((await balances())['Hand'], 60000);
    await env.transactions.softDelete(t.id);
    expect((await balances())['Hand'], 100000);
    await env.transactions.restore(t.id);
    expect((await balances())['Hand'], 60000);

    await env.transactions.softDelete(t.id);
    await env.accounts.softDelete(card.id);
    expect((await balances()).keys, <String>['Hand', 'SBI']);
    expect(await env.accounts.watchNetWorth().first, 5100000);
  });

  test('editing an entry changes the balance', () async {
    final TransactionEntry t = await env.transactions.create(
      expenseDraft(accountId: hand.id, categoryId: fuel, amount: 40000),
    );
    await env.transactions.update(
      t.id,
      expenseDraft(accountId: sbi.id, categoryId: fuel, amount: 1000),
    );
    final Map<String, int> b = await balances();
    expect(b['Hand'], 100000);
    expect(b['SBI'], 5000000 - 1000);
  });

  test('the balance stream updates after every change', () async {
    final List<List<AccountBalance>> seen = <List<AccountBalance>>[];
    final sub = env.accounts.watchBalances().listen(seen.add);
    await pumpEventQueue();
    await env.transactions.create(
      incomeDraft(accountId: hand.id, categoryId: salary, amount: 900),
    );
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.length, greaterThanOrEqualTo(2));
    int handOf(List<AccountBalance> l) =>
        l.firstWhere((AccountBalance b) => b.account.name == 'Hand').balance;
    expect(handOf(seen.first), 100000);
    expect(handOf(seen.last), 100900);
  });

  test('loan-linked entries still count in balances', () async {
    final loan = await env.loans.create(loanDraft());
    final String loanGiven = await env.seededCategoryId(
      'Loan Given',
      'expense',
    );
    await env.transactions.create(
      expenseDraft(
        accountId: hand.id,
        categoryId: loanGiven,
        amount: 50000,
        loanId: loan.id,
      ),
    );
    expect((await balances())['Hand'], 50000);
  });
}
