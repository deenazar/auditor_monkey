// Every edit and delete case of an entry must leave both account balances,
// the month sums and the statement running balance correct.
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

const int openA = 100000;
const int openB = 50000;
const int openC = 20000;

void main() {
  late TestEnv env;
  late TransactionsListRepository list;
  late Account a;
  late Account b;
  late Account c;
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = TestEnv();
    list = TransactionsListRepository(env.ctx);
    a = await env.account('A', opening: openA);
    b = await env.account('B', opening: openB);
    c = await env.account('C', opening: openC);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<TransactionEntry> add(TransactionDraft d) async {
    env.clock.advance();
    return env.transactions.create(d);
  }

  Future<int> balanceOf(Account acc) async =>
      (await env.accounts.getBalance(acc.id))!.balance;

  /// Checks balances, month sums (plain sums AND the list's month summary)
  /// and that the newest statement line's running balance equals the live
  /// balance, for every account.
  Future<void> verify({
    required int balA,
    required int balB,
    int? balC,
    int spentNov = 0,
    int incomeNov = 0,
    int spentOct = 0,
  }) async {
    expect(await balanceOf(a), balA, reason: 'balance A');
    expect(await balanceOf(b), balB, reason: 'balance B');
    expect(await balanceOf(c), balC ?? openC, reason: 'balance C');
    expect(
      await env.transactions.expenseTotal(from: '2026-11-01', to: '2026-11-30'),
      spentNov,
      reason: 'spent Nov',
    );
    expect(
      await env.transactions.incomeTotal(from: '2026-11-01', to: '2026-11-30'),
      incomeNov,
      reason: 'income Nov',
    );
    expect(
      await env.transactions.expenseTotal(from: '2026-10-01', to: '2026-10-31'),
      spentOct,
      reason: 'spent Oct',
    );
    final MonthSummary nov = await list.monthSummary(
      TransactionFilter.none,
      '2026-11',
    );
    expect(nov.spent, spentNov, reason: 'list month spent');
    expect(nov.income, incomeNov, reason: 'list month income');
    for (final (Account acc, int bal) in <(Account, int)>[
      (a, balA),
      (b, balB),
      (c, balC ?? openC),
    ]) {
      final StatementPage page = await env.transactions.statementPage(acc.id);
      final int running = page.lines.isEmpty
          ? acc.openingBalance
          : page.lines.first.balanceAfter;
      expect(running, bal, reason: 'statement running balance ${acc.name}');
    }
  }

  Future<void> edit(TransactionEntry e, TransactionDraft d) =>
      env.transactions.update(e.id, d);

  group('edit expense', () {
    test('amount up and down', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await verify(balA: 98000, balB: openB, spentNov: 2000);
      await edit(
        e,
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 5000),
      );
      await verify(balA: 95000, balB: openB, spentNov: 5000);
      await edit(
        e,
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 500),
      );
      await verify(balA: 99500, balB: openB, spentNov: 500);
    });

    test('move to another account', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await edit(
        e,
        expenseDraft(accountId: b.id, categoryId: groceries, amount: 2000),
      );
      await verify(balA: openA, balB: 48000, spentNov: 2000);
    });

    test('date moves across months', () async {
      final TransactionEntry e = await add(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 2000,
          date: '2026-10-30',
        ),
      );
      await verify(balA: 98000, balB: openB, spentOct: 2000);
      await edit(
        e,
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 2000,
          date: '2026-11-02',
        ),
      );
      await verify(balA: 98000, balB: openB, spentNov: 2000);
    });

    test('becomes income', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await edit(
        e,
        incomeDraft(accountId: a.id, categoryId: salary, amount: 2000),
      );
      await verify(balA: 102000, balB: openB, incomeNov: 2000);
    });

    test('becomes a transfer', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await edit(e, transferDraft(from: a.id, to: b.id, amount: 2000));
      await verify(balA: 98000, balB: 52000);
    });

    test('category change does not touch money', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await edit(
        e,
        expenseDraft(accountId: a.id, categoryId: fuel, amount: 2000),
      );
      await verify(balA: 98000, balB: openB, spentNov: 2000);
    });
  });

  group('edit transfer', () {
    late TransactionEntry t;
    setUp(() async {
      t = await add(transferDraft(from: a.id, to: b.id, amount: 3000));
    });

    test('starts right', () => verify(balA: 97000, balB: 53000));

    test('becomes an expense', () async {
      await edit(
        t,
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 3000),
      );
      await verify(balA: 97000, balB: openB, spentNov: 3000);
    });

    test('amount change', () async {
      await edit(t, transferDraft(from: a.id, to: b.id, amount: 8000));
      await verify(balA: 92000, balB: 58000);
    });

    test('swap From and To', () async {
      await edit(t, transferDraft(from: b.id, to: a.id, amount: 3000));
      await verify(balA: 103000, balB: 47000);
    });

    test('change To account', () async {
      await edit(t, transferDraft(from: a.id, to: c.id, amount: 3000));
      await verify(balA: 97000, balB: openB, balC: 23000);
    });

    test('change From account', () async {
      await edit(t, transferDraft(from: c.id, to: b.id, amount: 3000));
      await verify(balA: openA, balB: 53000, balC: 17000);
    });
  });

  group('delete and undo', () {
    Future<void> deleteUndo(
      TransactionDraft d, {
      required int afterA,
      required int afterB,
      required int doneA,
      required int doneB,
      int spent = 0,
      int income = 0,
    }) async {
      final TransactionEntry e = await add(d);
      await verify(
        balA: afterA,
        balB: afterB,
        spentNov: spent,
        incomeNov: income,
      );
      await env.transactions.softDelete(e.id);
      await verify(balA: openA, balB: openB);
      env.clock.advance();
      await env.transactions.restore(e.id);
      await verify(
        balA: doneA,
        balB: doneB,
        spentNov: spent,
        incomeNov: income,
      );
    }

    test('expense', () async {
      await deleteUndo(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
        afterA: 98000,
        afterB: openB,
        doneA: 98000,
        doneB: openB,
        spent: 2000,
      );
    });

    test('income', () async {
      await deleteUndo(
        incomeDraft(accountId: a.id, categoryId: salary, amount: 2000),
        afterA: 102000,
        afterB: openB,
        doneA: 102000,
        doneB: openB,
        income: 2000,
      );
    });

    test('transfer', () async {
      await deleteUndo(
        transferDraft(from: a.id, to: b.id, amount: 2000),
        afterA: 98000,
        afterB: 52000,
        doneA: 98000,
        doneB: 52000,
      );
    });

    test('double delete is safe, double undo is idempotent', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await env.transactions.softDelete(e.id);
      await expectLater(
        env.transactions.softDelete(e.id),
        throwsA(isA<NotFoundFailure>()),
      );
      await verify(balA: openA, balB: openB);
      await env.transactions.restore(e.id);
      await env.transactions.restore(e.id); // already live: no change
      await verify(balA: 98000, balB: openB, spentNov: 2000);
      expect(await env.count('transactions', liveOnly: true), 1);
    });

    test('undo works when the account was archived meanwhile', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await env.transactions.softDelete(e.id);
      await env.accounts.update(
        a.id,
        const AccountDraft(
          name: 'A',
          type: AccountType.bank,
          colour: 'accountSbi',
          openingBalance: openA,
          archived: true,
        ),
      );
      // Archived is not removed: the entry comes back (and counts in the
      // archived account's balance again).
      await env.transactions.restore(e.id);
      await verify(balA: 98000, balB: openB, spentNov: 2000);
    });

    test('undo is refused when the account was removed meanwhile', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 2000),
      );
      await env.transactions.softDelete(e.id);
      await env.accounts.softDelete(a.id);
      await expectLater(
        env.transactions.restore(e.id),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await env.transactions.getById(e.id), isNull);
    });
  });

  group('loan-linked entries', () {
    test('edit keeps loanId and importSource', () async {
      final loan = await env.loans.create(loanDraft());
      final TransactionEntry e = await add(
        TransactionDraft(
          type: TransactionType.expense,
          amount: 2000,
          date: day,
          accountId: a.id,
          categoryId: groceries,
          loanId: loan.id,
          importSource: 'sheet row 4',
        ),
      );
      final TransactionEntry edited = await env.transactions.update(
        e.id,
        TransactionDraft(
          type: TransactionType.expense,
          amount: 3000,
          date: day,
          accountId: b.id,
          categoryId: fuel,
          loanId: e.loanId,
          importSource: e.importSource,
        ),
      );
      expect(edited.loanId, loan.id);
      expect(edited.importSource, 'sheet row 4');
      // Balance counts it; spending sums leave loan entries out.
      await verify(balA: openA, balB: 47000);
    });
  });

  test('undo of a delete linked to a CLOSED loan is refused (DATABASE.md rule)', () async {
    final loan = await env.loans.create(loanDraft());
    final TransactionEntry e = await add(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 2000,
        date: day,
        accountId: a.id,
        categoryId: groceries,
        loanId: loan.id,
      ),
    );
    await env.transactions.softDelete(e.id);
    await env.loans.update(
      loan.id,
      const LoanDraft(
        direction: LoanDirection.lent,
        person: 'Ravi',
        principal: 100000,
        startDate: '2026-10-01',
        closed: true,
      ),
    );
    await expectLater(
      env.transactions.restore(e.id),
      throwsA(isA<ValidationFailure>()),
    );
    // Still deleted: the balance does not include it.
    expect(await env.transactions.getById(e.id), isNull);
    await verify(balA: openA, balB: openB);
  });

  group('deleted entries vanish from the list views', () {
    test('list, day totals and month summary', () async {
      final TransactionEntry keep = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 1000),
      );
      final TransactionEntry gone = await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 4000),
      );
      ListPage page = await list.page(TransactionFilter.none);
      expect(page.items, hasLength(2));
      expect(page.dayTotals[day]!.expense, 5000);

      await env.transactions.softDelete(gone.id);
      page = await list.page(TransactionFilter.none);
      expect(page.items.map((TransactionListItem i) => i.entry.id), <String>[
        keep.id,
      ]);
      expect(page.dayTotals[day]!.expense, 1000);
      expect(
        (await list.monthSummary(TransactionFilter.none, '2026-11')).spent,
        1000,
      );
      expect(await list.detail(gone.id), isNull);

      await env.transactions.restore(gone.id);
      page = await list.page(TransactionFilter.none);
      expect(page.items, hasLength(2));
      expect(page.dayTotals[day]!.expense, 5000);
    });
  });
}
