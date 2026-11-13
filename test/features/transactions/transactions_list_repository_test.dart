import 'package:auditor_monkey/core/database/daos/transactions_list_queries.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
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
    a = await env.account('A');
    b = await env.account('B');
    c = await env.account('C');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<TransactionEntry> add(TransactionDraft d) async {
    env.clock.advance();
    return env.transactions.create(d);
  }

  Future<List<String>> ids(TransactionFilter f) async => (await list.page(
    f,
    limit: 500,
  )).items.map((TransactionListItem i) => i.entry.id).toList();

  group('filters', () {
    late TransactionEntry exp1; // A groceries 12,000 11-10 note "Milk 100%"
    late TransactionEntry exp2; // B fuel 25,050 11-05
    late TransactionEntry inc; // A salary 90,000 10-31
    late TransactionEntry tr; // A -> C 5,000 11-12 note "a_b"

    setUp(() async {
      exp1 = await add(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 12000,
          date: '2026-11-10',
          note: 'Milk 100%',
        ),
      );
      exp2 = await add(
        expenseDraft(
          accountId: b.id,
          categoryId: fuel,
          amount: 25050,
          date: '2026-11-05',
        ),
      );
      inc = await add(
        incomeDraft(
          accountId: a.id,
          categoryId: salary,
          amount: 90000,
          date: '2026-10-31',
        ),
      );
      tr = await add(
        TransactionDraft(
          type: TransactionType.transfer,
          amount: 5000,
          date: '2026-11-12',
          accountId: a.id,
          toAccountId: c.id,
          note: 'a_b',
        ),
      );
    });

    test('no filter: all, newest first, with names', () async {
      final ListPage p = await list.page(TransactionFilter.none);
      expect(p.items.map((TransactionListItem i) => i.entry.id), <String>[
        tr.id,
        exp1.id,
        exp2.id,
        inc.id,
      ]);
      final TransactionListItem first = p.items.first;
      expect(first.accountName, 'A');
      expect(first.toAccountName, 'C');
      expect(first.categoryName, isNull);
      expect(p.items[1].categoryName, 'Groceries');
      expect(p.items[1].categoryColourGroup, isNotNull);
    });

    test('types', () async {
      expect(
        await ids(
          const TransactionFilter(
            types: <TransactionType>{TransactionType.income},
          ),
        ),
        <String>[inc.id],
      );
      expect(
        await ids(
          const TransactionFilter(
            types: <TransactionType>{
              TransactionType.expense,
              TransactionType.transfer,
            },
          ),
        ),
        <String>[tr.id, exp1.id, exp2.id],
      );
    });

    test('date range is inclusive, either end may be open', () async {
      expect(
        await ids(
          const TransactionFilter(from: '2026-11-05', to: '2026-11-10'),
        ),
        <String>[exp1.id, exp2.id],
      );
      expect(await ids(const TransactionFilter(to: '2026-10-31')), <String>[
        inc.id,
      ]);
      expect(await ids(const TransactionFilter(from: '2026-11-11')), <String>[
        tr.id,
      ]);
    });

    test('account matches the From and the To side', () async {
      expect(await ids(TransactionFilter(accountIds: <String>{c.id})), <String>[
        tr.id,
      ]);
      expect(
        await ids(TransactionFilter(accountIds: <String>{b.id, c.id})),
        <String>[tr.id, exp2.id],
      );
    });

    test('category filter never matches transfers', () async {
      expect(
        await ids(TransactionFilter(categoryIds: <String>{groceries, salary})),
        <String>[exp1.id, inc.id],
      );
    });

    test('facets combine with AND', () async {
      expect(
        await ids(
          TransactionFilter(
            accountIds: <String>{a.id},
            from: '2026-11-01',
            types: const <TransactionType>{TransactionType.expense},
          ),
        ),
        <String>[exp1.id],
      );
      expect(
        await ids(
          TransactionFilter(
            accountIds: <String>{b.id},
            categoryIds: <String>{groceries},
          ),
        ),
        isEmpty,
      );
    });

    test('search: note, category name (any case), amount', () async {
      expect(await ids(const TransactionFilter(query: 'milk')), <String>[
        exp1.id,
      ]);
      expect(await ids(const TransactionFilter(query: 'FUEL')), <String>[
        exp2.id,
      ]);
      expect(await ids(const TransactionFilter(query: 'groc')), <String>[
        exp1.id,
      ]);
      expect(await ids(const TransactionFilter(query: '250.50')), <String>[
        exp2.id,
      ]);
      expect(await ids(const TransactionFilter(query: '₹1,20,000')), isEmpty);
      expect(await ids(const TransactionFilter(query: '₹ 900')), <String>[
        inc.id,
      ]);
      expect(await ids(const TransactionFilter(query: '120')), <String>[
        exp1.id,
      ]);
    });

    test('search with a facet', () async {
      expect(
        await ids(
          const TransactionFilter(
            query: 'sal',
            types: <TransactionType>{TransactionType.income},
          ),
        ),
        <String>[inc.id],
      );
    });

    test('LIKE wildcards are matched literally', () async {
      expect(await ids(const TransactionFilter(query: '%')), <String>[exp1.id]);
      expect(await ids(const TransactionFilter(query: '_')), <String>[tr.id]);
      expect(await ids(const TransactionFilter(query: r'\')), isEmpty);
      expect(await ids(const TransactionFilter(query: '0%')), <String>[
        exp1.id,
      ]);
      expect(await ids(const TransactionFilter(query: 'a_b')), <String>[tr.id]);
      expect(await ids(const TransactionFilter(query: 'a%b')), isEmpty);
    });

    test('quotes in the search are data, not SQL', () async {
      expect(
        await ids(const TransactionFilter(query: "x' OR '1'='1")),
        isEmpty,
      );
      expect(await env.count('transactions'), 4);
    });

    test('a deleted entry never matches', () async {
      await env.transactions.softDelete(exp1.id);
      expect(await ids(const TransactionFilter(query: 'milk')), isEmpty);
    });
  });

  test('escapeLike and queryAsPaise', () {
    expect(escapeLike(r'50%_\'), r'50\%\_\\');
    expect(queryAsPaise('₹1,250.50'), 125050);
    expect(queryAsPaise(' 7 '), 700);
    expect(queryAsPaise('abc'), isNull);
    expect(queryAsPaise('1.234'), isNull);
    expect(queryAsPaise(''), isNull);
    expect(queryAsPaise('1 2'), isNull);
    expect(queryAsPaise('1,2,3'), isNull);
    expect(queryAsPaise('₹ 1,20,000'), 12000000);
    expect(queryAsPaise('1,000'), 100000);
    expect(queryAsPaise('₹₹5'), isNull);
  });

  group('paging', () {
    test('keyset paging over a filter: no duplicates, no gaps', () async {
      final List<String> expected = <String>[];
      for (int i = 0; i < 23; i++) {
        // Same day on purpose: the cursor must break ties on created_at/id.
        final TransactionEntry e = await add(
          i.isEven
              ? expenseDraft(
                  accountId: a.id,
                  categoryId: groceries,
                  amount: 100 + i,
                  date: i < 12 ? '2026-11-10' : '2026-11-09',
                )
              : expenseDraft(
                  accountId: b.id,
                  categoryId: fuel,
                  amount: 100 + i,
                  date: '2026-11-10',
                ),
        );
        if (i.isEven) expected.add(e.id);
      }
      final TransactionFilter f = TransactionFilter(accountIds: <String>{a.id});
      final List<String> got = <String>[];
      TransactionCursor? cursor;
      bool more = true;
      int pages = 0;
      while (more) {
        final ListPage p = await list.page(f, limit: 5, after: cursor);
        got.addAll(p.items.map((TransactionListItem i) => i.entry.id));
        more = p.hasMore;
        cursor = p.items.isEmpty
            ? null
            : TransactionCursor.after(p.items.last.entry);
        pages++;
        expect(pages, lessThan(10));
      }
      expect(got.toSet(), expected.toSet());
      expect(got, hasLength(expected.length));
      // Newest first: day desc, then entry time desc.
      final List<String> byDay = <String>[
        for (final String id in got) (await env.transactions.getById(id))!.date,
      ];
      expect(
        byDay,
        <String>[...byDay]..sort((String x, String y) => y.compareTo(x)),
      );
    });

    test('day totals cover days split across pages', () async {
      for (int i = 0; i < 7; i++) {
        await add(
          expenseDraft(
            accountId: a.id,
            categoryId: groceries,
            amount: 1000,
            date: '2026-11-10',
          ),
        );
      }
      await add(
        incomeDraft(
          accountId: a.id,
          categoryId: salary,
          amount: 5000,
          date: '2026-11-10',
        ),
      );
      await add(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 300,
          date: '2026-11-09',
        ),
      );
      final ListPage p1 = await list.page(TransactionFilter.none, limit: 3);
      expect(p1.hasMore, isTrue);
      expect(p1.items, hasLength(3));
      // Page 1 holds only part of 11-10, but the total is the whole day.
      expect(p1.dayTotals.keys, <String>['2026-11-10']);
      expect(
        p1.dayTotals['2026-11-10'],
        const DayTotal(date: '2026-11-10', expense: 7000, income: 5000),
      );
      final ListPage p2 = await list.page(
        TransactionFilter.none,
        limit: 10,
        after: TransactionCursor.after(p1.items.last.entry),
      );
      expect(p2.dayTotals['2026-11-10']!.expense, 7000);
      expect(p2.dayTotals['2026-11-09']!.expense, 300);
    });
  });

  group('sums', () {
    test('transfers and loan-linked entries never count', () async {
      final loan = await env.loans.create(loanDraft());
      await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 1000),
      );
      await add(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 7000,
          loanId: loan.id,
        ),
      );
      await add(transferDraft(from: a.id, to: b.id, amount: 9000));
      await add(incomeDraft(accountId: a.id, categoryId: salary, amount: 2000));
      final MonthSummary m = await list.monthSummary(
        TransactionFilter.none,
        '2026-11',
      );
      expect(m.spent, 1000);
      expect(m.income, 2000);
      expect(m.net, 1000);
      final Map<String, DayTotal> d = await list.dayTotals(
        TransactionFilter.none,
        <String>[day, '2026-11-01'],
      );
      expect(d[day], const DayTotal(date: day, expense: 1000, income: 2000));
      expect(d['2026-11-01'], const DayTotal(date: '2026-11-01'));
      // The list still shows the loan-linked row.
      expect((await list.page(TransactionFilter.none)).items, hasLength(4));
    });

    test('follow the filter', () async {
      await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 1000),
      );
      await add(expenseDraft(accountId: b.id, categoryId: fuel, amount: 4000));
      expect(
        (await list.monthSummary(
          TransactionFilter(accountIds: <String>{b.id}),
          '2026-11',
        )).spent,
        4000,
      );
      expect(
        (await list.monthSummary(
          const TransactionFilter(query: 'groc'),
          '2026-11',
        )).spent,
        1000,
      );
      expect(
        (await list.monthSummary(
          const TransactionFilter(from: '2026-11-13'),
          '2026-11',
        )).spent,
        0,
      );
    });

    test('watchMonthSummary re-emits after a change', () async {
      final Stream<MonthSummary> s = list.watchMonthSummary(
        TransactionFilter.none,
        '2026-11',
      );
      final List<int> seen = <int>[];
      final sub = s.listen((MonthSummary m) => seen.add(m.spent));
      await pumpEventQueue();
      await add(
        expenseDraft(accountId: a.id, categoryId: groceries, amount: 1000),
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, <int>[0, 1000]);
    });
  });

  group('detail', () {
    test('names, null when deleted or unknown or malformed', () async {
      final TransactionEntry e = await add(
        expenseDraft(accountId: a.id, categoryId: groceries),
      );
      final TransactionListItem? item = await list.detail(e.id);
      expect(item!.accountName, 'A');
      expect(item.categoryName, 'Groceries');
      await env.transactions.softDelete(e.id);
      expect(await list.detail(e.id), isNull);
      expect(await list.detail('00000000-0000-4000-8000-000000000000'), isNull);
      expect(await list.detail("x' OR 1=1"), isNull);
      expect(await list.watchDetail('nope').first, isNull);
    });
  });

  group('validation', () {
    Future<void> rejects(TransactionFilter f, FailureCode code) => expectLater(
      list.page(f),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure v) => v.code,
          'code',
          code,
        ),
      ),
    );

    test('bad filters are refused with plain messages', () async {
      await rejects(
        const TransactionFilter(from: '2026-13-01'),
        FailureCode.invalidDate,
      );
      await rejects(const TransactionFilter(to: 'x'), FailureCode.invalidDate);
      await rejects(
        const TransactionFilter(from: '2026-11-10', to: '2026-11-09'),
        FailureCode.rule,
      );
      await rejects(TransactionFilter(query: 'x' * 61), FailureCode.tooLong);
      await rejects(
        const TransactionFilter(query: 'a\u0000b'),
        FailureCode.invalidCharacters,
      );
      await rejects(
        const TransactionFilter(accountIds: <String>{'not-a-uuid'}),
        FailureCode.invalidFormat,
      );
      await rejects(
        TransactionFilter(
          categoryIds: <String>{
            for (int i = 0; i < 51; i++)
              '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          },
        ),
        FailureCode.outOfRange,
      );
      await expectLater(
        list.page(TransactionFilter.none, limit: 0),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        list.monthSummary(TransactionFilter.none, '2026-1'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('exactly 60 characters and 50 ids are fine', () async {
      await list.page(
        TransactionFilter(
          query: 'x' * 60,
          accountIds: <String>{
            for (int i = 0; i < 50; i++)
              '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          },
        ),
      );
    });

    test('logs the operation without values', () async {
      await add(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 123456,
          note: 'secret note',
        ),
      );
      env.sink.records.clear();
      await list.page(const TransactionFilter(query: 'secret'));
      expect(env.sink.allText, contains('page ok'));
      expect(env.sink.allText, isNot(contains('secret')));
      expect(env.sink.allText, isNot(contains('1234')));
    });
  });
}
