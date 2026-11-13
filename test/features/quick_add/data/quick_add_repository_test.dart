import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/quick_add/data/quick_add_repository.dart';
import 'package:auditor_monkey/features/quick_add/domain/quick_add_hints.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures.dart';
import '../../../support/test_env.dart';

const String today = '2026-11-12';

void main() {
  late TestEnv env;
  late QuickAddRepository repo;
  late Account a1;
  late Account a2;
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = TestEnv();
    repo = QuickAddRepository(env.ctx);
    a1 = await env.account('A1');
    a2 = await env.account('A2');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<TransactionEntry> add(TransactionDraft d) async {
    env.clock.advance();
    return env.transactions.create(d);
  }

  test('empty database gives empty hints', () async {
    final QuickAddHints h = await repo.loadHints(today: today);
    expect(h.lastUsed, isEmpty);
    expect(h.recent, isEmpty);
    expect(h.usage[TransactionType.expense], isEmpty);
  });

  test('last used is the newest by entry time, even when back-dated', () async {
    await add(expenseDraft(accountId: a1.id, categoryId: groceries));
    // Made last, but dated earlier: still the last used.
    await add(
      expenseDraft(accountId: a2.id, categoryId: fuel, date: '2026-10-01'),
    );
    final QuickAddHints h = await repo.loadHints(today: today);
    expect(h.lastUsed[TransactionType.expense]!.accountId, a2.id);
    expect(h.lastUsed[TransactionType.expense]!.categoryId, fuel);
    expect(h.lastUsed.containsKey(TransactionType.income), isFalse);
  });

  test('transfer last used keeps both accounts, no category', () async {
    await add(transferDraft(from: a1.id, to: a2.id));
    final QuickAddHints h = await repo.loadHints(today: today);
    final LastUsedPick p = h.lastUsed[TransactionType.transfer]!;
    expect(p.accountId, a1.id);
    expect(p.toAccountId, a2.id);
    expect(p.categoryId, isNull);
  });

  test('deleted, loan-linked and out-of-window rows are left out', () async {
    final TransactionEntry deleted = await add(
      expenseDraft(accountId: a2.id, categoryId: fuel),
    );
    await env.transactions.softDelete(deleted.id);
    final Loan loan = await env.loans.create(loanDraft());
    await add(
      expenseDraft(accountId: a2.id, categoryId: fuel, loanId: loan.id),
    );
    // 90 days before 2026-11-12 is 2026-08-14; one day older is out.
    await add(
      expenseDraft(accountId: a2.id, categoryId: fuel, date: '2026-08-13'),
    );
    await add(expenseDraft(accountId: a1.id, categoryId: groceries));
    final QuickAddHints h = await repo.loadHints(today: today);
    expect(h.recent, hasLength(1));
    expect(h.recent.single.categoryId, groceries);
    expect(h.usage[TransactionType.expense], hasLength(1));
    expect(h.lastUsed[TransactionType.expense]!.accountId, a1.id);
  });

  test('window edge day is included, future dates are included', () async {
    await add(
      expenseDraft(accountId: a1.id, categoryId: fuel, date: '2026-08-14'),
    );
    await add(
      expenseDraft(accountId: a1.id, categoryId: groceries, date: '2026-12-01'),
    );
    final QuickAddHints h = await repo.loadHints(today: today);
    expect(h.recent, hasLength(2));
  });

  test('usage counts and last use per category, per type', () async {
    await add(expenseDraft(accountId: a1.id, categoryId: groceries));
    await add(expenseDraft(accountId: a1.id, categoryId: groceries));
    final int lastGroceries = env.clock.now;
    await add(expenseDraft(accountId: a1.id, categoryId: fuel));
    await add(incomeDraft(accountId: a1.id, categoryId: salary));
    final QuickAddHints h = await repo.loadHints(today: today);
    final Map<String, CategoryUsage> byId = <String, CategoryUsage>{
      for (final CategoryUsage u in h.usage[TransactionType.expense]!)
        u.categoryId: u,
    };
    expect(byId[groceries]!.uses, 2);
    expect(byId[groceries]!.lastUsed, lastGroceries);
    expect(byId[fuel]!.uses, 1);
    expect(h.usage[TransactionType.income]!.single.categoryId, salary);
  });

  test('recent: newest first, all types, at most 50', () async {
    for (int i = 0; i < 55; i++) {
      await add(
        expenseDraft(accountId: a1.id, categoryId: groceries, amount: 100 + i),
      );
    }
    final QuickAddHints h = await repo.loadHints(today: today);
    expect(h.recent, hasLength(50));
    expect(h.recent.first.amount, 154);
    expect(h.recent.last.amount, 105);
  });

  test('same entry time: id breaks the tie, newest id last wins', () async {
    // Same created_at for both (clock not advanced).
    final TransactionEntry x = await env.transactions.create(
      expenseDraft(accountId: a1.id, categoryId: groceries, amount: 1),
    );
    final TransactionEntry y = await env.transactions.create(
      expenseDraft(accountId: a2.id, categoryId: fuel, amount: 2),
    );
    final QuickAddHints h = await repo.loadHints(today: today);
    final String bigger = x.id.compareTo(y.id) > 0 ? x.id : y.id;
    expect(h.recent.first.id, bigger);
  });

  test('bad date is refused', () async {
    expect(repo.loadHints(today: 'nope'), throwsA(anything));
  });

  test('logs counts and timing only', () async {
    await add(
      expenseDraft(accountId: a1.id, categoryId: groceries, amount: 777),
    );
    env.sink.records.clear();
    await repo.loadHints(today: today);
    final String text = env.sink.allText;
    expect(text, contains('loadHints ok'));
    expect(text, contains('1 recent'));
    expect(text, isNot(contains('777')));
    expect(text, isNot(contains(today)));
  });
}
