import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;
  late Account b;
  late String groceries;
  late String salary;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A', opening: 100000);
    b = await env.account('B', opening: 50000);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<void> expense(Account acc, int amount, String date) async {
    env.clock.advance();
    await env.transactions.create(
      expenseDraft(
        accountId: acc.id,
        categoryId: groceries,
        amount: amount,
        date: date,
      ),
    );
  }

  Future<void> income(Account acc, int amount, String date) async {
    env.clock.advance();
    await env.transactions.create(
      incomeDraft(
        accountId: acc.id,
        categoryId: salary,
        amount: amount,
        date: date,
      ),
    );
  }

  Future<void> transfer(
    Account from,
    Account to,
    int amount,
    String date,
  ) async {
    env.clock.advance();
    await env.transactions.create(
      transferDraft(from: from.id, to: to.id, amount: amount, date: date),
    );
  }

  test(
    'running balance with expense, income and transfers on both sides',
    () async {
      await expense(a, 2500, '2026-11-01'); // 97500
      await income(a, 10000, '2026-11-02'); // 107500
      await transfer(a, b, 7500, '2026-11-03'); // A 100000, B +7500
      await transfer(b, a, 1000, '2026-11-04'); // A 101000

      final StatementPage pageA = await env.transactions.statementPage(a.id);
      expect(pageA.hasMore, isFalse);
      expect(pageA.lines.map((StatementLine l) => l.entry.date), <String>[
        '2026-11-04',
        '2026-11-03',
        '2026-11-02',
        '2026-11-01',
      ]);
      expect(pageA.lines.map((StatementLine l) => l.effect), <int>[
        1000,
        -7500,
        10000,
        -2500,
      ]);
      expect(pageA.lines.map((StatementLine l) => l.balanceAfter), <int>[
        101000,
        100000,
        107500,
        97500,
      ]);
      // Newest line equals the balance query.
      expect(
        pageA.lines.first.balanceAfter,
        (await env.accounts.getBalance(a.id))!.balance,
      );
      // Opening balance = oldest balanceAfter minus its effect.
      expect(pageA.lines.last.balanceAfter - pageA.lines.last.effect, 100000);

      final StatementPage pageB = await env.transactions.statementPage(b.id);
      expect(pageB.lines.map((StatementLine l) => l.effect), <int>[
        -1000,
        7500,
      ]);
      expect(pageB.lines.map((StatementLine l) => l.balanceAfter), <int>[
        56500,
        57500,
      ]);
    },
  );

  test('transfer lines carry the other account name and direction', () async {
    await transfer(a, b, 100, '2026-11-03');
    final StatementLine fromA = (await env.transactions.statementPage(a.id))
        .lines
        .single;
    final StatementLine toB = (await env.transactions.statementPage(b.id))
        .lines
        .single;
    expect(fromA.isTransfer, isTrue);
    expect(fromA.isOutgoing, isTrue);
    expect(fromA.counterpartName, 'B');
    expect(fromA.categoryName, isNull);
    expect(toB.isOutgoing, isFalse);
    expect(toB.counterpartName, 'A');
  });

  test('expense lines carry the category name and icon', () async {
    await expense(a, 100, '2026-11-03');
    final StatementLine line = (await env.transactions.statementPage(a.id))
        .lines
        .single;
    expect(line.categoryName, 'Groceries');
    expect(line.categoryIcon, 'shopping-cart');
    expect(line.counterpartName, isNull);
  });

  test('same-day entries are ordered by created time, then id', () async {
    await expense(a, 100, '2026-11-05'); // first
    await expense(a, 200, '2026-11-05'); // second
    await expense(a, 300, '2026-11-05'); // third
    final List<StatementLine> lines = (await env.transactions.statementPage(
      a.id,
    )).lines;
    expect(lines.map((StatementLine l) => l.effect), <int>[-300, -200, -100]);
    expect(lines.map((StatementLine l) => l.balanceAfter), <int>[
      99400,
      99700,
      99900,
    ]);
  });

  test(
    'same date and same created time: id breaks the tie both ways',
    () async {
      // Two rows with the exact same date and created_at.
      for (final String id in <String>[
        '00000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000002',
      ]) {
        await env.rawSql(
          'INSERT INTO transactions (id, created_at, updated_at, type, amount, '
          "date, account_id, category_id) VALUES (?, 5, 5, 'expense', 100, "
          "'2026-11-05', ?, ?)",
          <Object?>[id, a.id, groceries],
        );
      }
      final StatementPage p = await env.transactions.statementPage(
        a.id,
        limit: 1,
      );
      expect(p.lines.single.entry.id.endsWith('2'), isTrue);
      expect(p.lines.single.balanceAfter, 99800);
      final StatementPage next = await env.transactions.statementPage(
        a.id,
        limit: 1,
        after: p.nextCursor,
      );
      expect(next.lines.single.entry.id.endsWith('1'), isTrue);
      expect(next.lines.single.balanceAfter, 99900);
    },
  );

  test('deleted entries are ignored, also in the running balance', () async {
    await expense(a, 100, '2026-11-01');
    env.clock.advance();
    final TransactionEntry gone = await env.transactions.create(
      expenseDraft(
        accountId: a.id,
        categoryId: groceries,
        amount: 5000,
        date: '2026-11-02',
      ),
    );
    await expense(a, 300, '2026-11-03');
    await env.transactions.softDelete(gone.id);
    final List<StatementLine> lines = (await env.transactions.statementPage(
      a.id,
    )).lines;
    expect(lines, hasLength(2));
    expect(lines.map((StatementLine l) => l.balanceAfter), <int>[99600, 99900]);
  });

  test('other accounts are ignored', () async {
    await expense(b, 999, '2026-11-01');
    expect((await env.transactions.statementPage(a.id)).lines, isEmpty);
  });

  test('no entries gives an empty page', () async {
    final StatementPage p = await env.transactions.statementPage(a.id);
    expect(p.lines, isEmpty);
    expect(p.hasMore, isFalse);
    expect(p.nextCursor, isNull);
  });

  group('paging boundaries', () {
    Future<void> seed(int n) async {
      for (int i = 0; i < n; i++) {
        await expense(
          a,
          10,
          '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
        );
      }
    }

    for (final (int rows, int pages, bool lastMore) in <(int, int, bool)>[
      (49, 1, false),
      (50, 1, false),
      (51, 2, false),
    ]) {
      test('$rows rows with page size 50', () async {
        await seed(rows);
        final List<StatementLine> all = <StatementLine>[];
        StatementPage page = await env.transactions.statementPage(a.id);
        int pageCount = 1;
        all.addAll(page.lines);
        while (page.hasMore) {
          page = await env.transactions.statementPage(
            a.id,
            after: page.nextCursor,
          );
          all.addAll(page.lines);
          pageCount++;
        }
        expect(pageCount, pages);
        expect(page.hasMore, lastMore);
        expect(all, hasLength(rows));
        expect(
          all.map((StatementLine l) => l.entry.id).toSet(),
          hasLength(rows),
        );
        // Balances are continuous across pages.
        expect(all.first.balanceAfter, 100000 - 10 * rows);
        expect(all.last.balanceAfter, 100000 - 10);
        for (int i = 0; i < all.length - 1; i++) {
          expect(all[i].balanceAfter - all[i].effect, all[i + 1].balanceAfter);
        }
      });
    }

    test('statementThrough reads several pages in one call', () async {
      await seed(120);
      final StatementPage p = await env.transactions.statementThrough(
        a.id,
        count: 100,
      );
      expect(p.lines, hasLength(100));
      expect(p.hasMore, isTrue);
      final StatementPage all = await env.transactions.statementThrough(
        a.id,
        count: 5000,
      );
      expect(all.lines, hasLength(120));
      expect(all.hasMore, isFalse);
    });

    test('page size must be 1..500', () async {
      for (final int bad in <int>[0, -1, 501]) {
        await expectLater(
          env.transactions.statementPage(a.id, limit: bad),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(
        (await env.transactions.statementPage(a.id, limit: 500)).lines,
        isEmpty,
      );
    });
  });

  group('not found', () {
    test('malformed, unknown and deleted ids', () async {
      for (final String id in <String>[
        '',
        'not-a-uuid',
        "x' OR 1=1 --",
        '00000000-0000-4000-8000-00000000ffff',
      ]) {
        await expectLater(
          env.transactions.statementPage(id),
          throwsA(isA<NotFoundFailure>()),
          reason: id,
        );
      }
      await env.accounts.softDelete(b.id);
      await expectLater(
        env.transactions.statementPage(b.id),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('overflow', () {
    Future<void> bulk(int rows, int amount) => env.rawSql(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < $rows) '
      'INSERT INTO transactions (id, created_at, updated_at, type, amount, '
      'date, account_id, category_id) '
      "SELECT printf('%036d', i), i, i, 'income', $amount, '2026-11-12', ?, ? "
      'FROM n',
      <Object?>[a.id, salary],
    );

    test('a running sum past 64 bits is an OverflowFailure', () async {
      await bulk(100000, maxPaise);
      await expectLater(
        env.transactions.statementPage(a.id),
        throwsA(isA<OverflowFailure>()),
      );
    });

    test('opening balance plus a near-limit sum that overflows', () async {
      await env.accounts.update(
        a.id,
        const AccountDraft(
          name: 'A',
          type: AccountType.bank,
          colour: 'accountSbi',
          openingBalance: maxPaise,
        ),
      );
      await bulk(92233, maxPaise);
      await expectLater(
        env.transactions.statementPage(a.id),
        throwsA(isA<OverflowFailure>()),
      );
    });
  });

  test('a statement load writes no names or amounts to the log', () async {
    await env.accounts.editAccount(
      a.id,
      const AccountDetails(
        name: 'Very Private',
        type: AccountType.bank,
        colour: 'sun',
        openingBalance: 7654321,
      ),
    );
    await expense(a, 123457, '2026-11-01');
    env.sink.records.clear();
    await env.transactions.statementPage(a.id);
    await env.transactions.statementThrough(a.id);
    await env.transactions.monthlyTotalsForAccount(
      a.id,
      fromMonth: '2026-06',
      toMonth: '2026-11',
    );
    expect(env.sink.allText, isNot(contains('Private')));
    expect(env.sink.allText, isNot(contains('7654321')));
    expect(env.sink.allText, isNot(contains('123457')));
    expect(env.sink.allText, isNot(contains('Groceries')));
  });

  test('watchStatementSignal fires on a new entry', () async {
    int ticks = 0;
    final sub = env.transactions.watchStatementSignal().listen((_) => ticks++);
    await pumpEventQueue();
    final int before = ticks;
    await expense(a, 100, '2026-11-01');
    await pumpEventQueue();
    await sub.cancel();
    expect(ticks, greaterThan(before));
  });

  group('monthly totals', () {
    Future<List<MonthlyTotal>> totals({
      String from = '2026-06',
      String to = '2026-11',
      Account? acc,
    }) => env.transactions.monthlyTotalsForAccount(
      (acc ?? a).id,
      fromMonth: from,
      toMonth: to,
    );

    test('empty months are 0 and the list covers every month', () async {
      final List<MonthlyTotal> t = await totals();
      expect(t.map((MonthlyTotal m) => m.month), <String>[
        '2026-06',
        '2026-07',
        '2026-08',
        '2026-09',
        '2026-10',
        '2026-11',
      ]);
      expect(
        t.every((MonthlyTotal m) => m.income == 0 && m.expense == 0),
        isTrue,
      );
    });

    test('sums income and expense per month; month edges', () async {
      await expense(a, 100, '2026-10-31');
      await expense(a, 200, '2026-11-01');
      await expense(a, 50, '2026-11-30');
      await income(a, 1000, '2026-10-01');
      await income(a, 3000, '2026-11-15');
      await expense(a, 999, '2026-05-31'); // before the range
      final List<MonthlyTotal> t = await totals();
      MonthlyTotal m(String month) =>
          t.firstWhere((MonthlyTotal x) => x.month == month);
      expect(
        m('2026-10'),
        const MonthlyTotal(month: '2026-10', income: 1000, expense: 100),
      );
      expect(
        m('2026-11'),
        const MonthlyTotal(month: '2026-11', income: 3000, expense: 250),
      );
      expect(m('2026-06').expense, 0);
    });

    test(
      'transfers, loan rows, deleted rows and other accounts are left out',
      () async {
        await transfer(a, b, 5000, '2026-11-02');
        await transfer(b, a, 7000, '2026-11-03');
        env.clock.advance();
        final loan = await env.loans.create(loanDraft());
        await env.transactions.create(
          expenseDraft(
            accountId: a.id,
            categoryId: groceries,
            amount: 4000,
            date: '2026-11-04',
            loanId: loan.id,
          ),
        );
        env.clock.advance();
        final TransactionEntry gone = await env.transactions.create(
          incomeDraft(
            accountId: a.id,
            categoryId: salary,
            amount: 8000,
            date: '2026-11-05',
          ),
        );
        await env.transactions.softDelete(gone.id);
        await expense(b, 600, '2026-11-06');
        await expense(a, 10, '2026-11-07');
        final MonthlyTotal nov = (await totals()).last;
        expect(nov.income, 0);
        expect(nov.expense, 10);
      },
    );

    test('the watched version updates and matches', () async {
      final Stream<List<MonthlyTotal>> s = env.transactions
          .watchMonthlyTotalsForAccount(
            a.id,
            fromMonth: '2026-11',
            toMonth: '2026-11',
          );
      final List<List<MonthlyTotal>> seen = <List<MonthlyTotal>>[];
      final sub = s.listen(seen.add);
      await pumpEventQueue();
      await expense(a, 150, '2026-11-02');
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first.single.expense, 0);
      expect(seen.last.single.expense, 150);
    });

    test('bad input is rejected', () async {
      await expectLater(
        env.transactions.monthlyTotalsForAccount(
          'nope',
          fromMonth: '2026-06',
          toMonth: '2026-11',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      for (final (String, String) r in <(String, String)>[
        ('2026-13', '2026-11'),
        ('2026-11', '2026-10'),
        ('2020-01', '2026-11'),
        ('abc', '2026-11'),
      ]) {
        await expectLater(
          totals(from: r.$1, to: r.$2),
          throwsA(isA<ValidationFailure>()),
          reason: '$r',
        );
      }
    });
  });
}
