@Tags(<String>['perf'])
library;

// Transactions list speed on 20,000 rows: first page, day totals and month
// summary. Target 100 ms; the test fails only when the median is above
// 250 ms (so a slow CI machine cannot make it flaky). The real p50 / p95 are
// printed. Query plans must use the date index (no schema change).
import 'package:auditor_monkey/core/database/daos/transactions_list_queries.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/quick_add_env.dart';
import '../../support/test_env.dart';

const int gateMs = 250;
const int targetMs = 100;

void main() {
  late TestEnv env;
  late TransactionsListRepository list;
  late List<Account> acc;
  late String groceries;

  setUp(() async {
    env = quickAddTestEnv();
    list = TransactionsListRepository(env.ctx);
    acc = await threeAccounts(env);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    final String fuel = await env.seededCategoryId('Fuel', 'expense');
    final String salary = await env.seededCategoryId('Salary', 'income');
    await env.rawSql(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < 20000) '
      'INSERT INTO transactions (id, created_at, updated_at, sync_status, '
      'type, amount, date, account_id, to_account_id, category_id) '
      "SELECT printf('%036d', i), 1000 + i, 1000 + i, 'pending', "
      "CASE i % 4 WHEN 0 THEN 'income' WHEN 3 THEN 'transfer' "
      "ELSE 'expense' END, 100 + (i % 500), "
      "date('2026-11-12', '-' || (i % 400) || ' days'), "
      "CASE i % 3 WHEN 0 THEN '${acc[0].id}' WHEN 1 THEN '${acc[1].id}' "
      "ELSE '${acc[2].id}' END, "
      "CASE WHEN i % 4 = 3 THEN "
      "CASE i % 3 WHEN 0 THEN '${acc[1].id}' ELSE '${acc[0].id}' END END, "
      "CASE i % 4 WHEN 3 THEN NULL WHEN 0 THEN '$salary' "
      "WHEN 1 THEN '$groceries' ELSE '$fuel' END FROM n",
    );
    expect(await env.count('transactions'), 20000);
  });
  tearDown(() => env.close());

  Future<String> plan(String sql, List<Variable<Object>> vars) async {
    final rows = await env.db
        .customSelect('EXPLAIN QUERY PLAN $sql', variables: vars)
        .get();
    return rows.map((r) => r.read<String>('detail')).join('\n');
  }

  test('unfiltered page uses ix_tx_date, with and without a cursor', () async {
    const ListFilterSpec none = ListFilterSpec();
    final ListWhere w = listWhere(none);
    final String first = await plan(
      listPageSql(w, hasCursor: false),
      <Variable<Object>>[const Variable<int>(51)],
    );
    expect(first, contains('ix_tx_date'));
    final String next = await plan(
      listPageSql(w, hasCursor: true),
      <Variable<Object>>[
        const Variable<String>('2026-10-01'),
        const Variable<int>(5000),
        const Variable<String>('x'),
        const Variable<int>(51),
      ],
    );
    expect(next, contains('ix_tx_date'));
    // The big table is never scanned in full.
    expect(first, isNot(contains('SCAN t\n')));
  });

  test('day totals and month summary use ix_tx_date', () async {
    const ListFilterSpec none = ListFilterSpec();
    final ListWhere w = listWhere(none);
    final List<Variable<Object>> range = <Variable<Object>>[
      const Variable<String>('2026-11-01'),
      const Variable<String>('2026-11-30'),
    ];
    expect(await plan(dayTotalsSql(w), range), contains('ix_tx_date'));
    expect(await plan(monthSummarySql(w), range), contains('ix_tx_date'));
  });

  Future<void> measure(String name, Future<void> Function() body) async {
    final List<int> micros = <int>[];
    for (int i = 0; i < 15; i++) {
      final Stopwatch w = Stopwatch()..start();
      await body();
      w.stop();
      micros.add(w.elapsedMicroseconds);
    }
    micros.sort();
    final double p50 = micros[(micros.length - 1) ~/ 2] / 1000;
    final double p95 = micros[((micros.length - 1) * 0.95).round()] / 1000;
    // ignore: avoid_print
    print(
      'PERF list $name on 20,000 rows: p50 ${p50.toStringAsFixed(1)} ms, '
      'p95 ${p95.toStringAsFixed(1)} ms (target $targetMs ms, '
      'gate p50 <= $gateMs ms)',
    );
    expect(p50, lessThanOrEqualTo(gateMs), reason: '$name median too slow');
  }

  test('first page (with day totals): p50 gate 250 ms', () async {
    await measure('first page', () async {
      final ListPage p = await list.page(TransactionFilter.none);
      expect(p.items, hasLength(50));
      expect(p.dayTotals, isNotEmpty);
    });
  });

  test('first page with filters: p50 gate 250 ms', () async {
    final TransactionFilter f = TransactionFilter(
      query: 'groc',
      accountIds: <String>{acc[0].id, acc[1].id},
      types: const <TransactionType>{TransactionType.expense},
    );
    await measure('filtered page', () async {
      final ListPage p = await list.page(f);
      expect(p.items, isNotEmpty);
    });
  });

  test('deep page (cursor): p50 gate 250 ms', () async {
    final ListPage p1 = await list.page(TransactionFilter.none, limit: 500);
    final TransactionCursor cursor = TransactionCursor.after(
      p1.items.last.entry,
    );
    await measure('deep page', () async {
      final ListPage p = await list.page(TransactionFilter.none, after: cursor);
      expect(p.items, hasLength(50));
    });
  });

  test('month summary: p50 gate 250 ms', () async {
    await measure('month summary', () async {
      final MonthSummary m = await list.monthSummary(
        TransactionFilter.none,
        '2026-11',
      );
      expect(m.spent, greaterThan(0));
    });
  });

  test('day totals for 50 days: p50 gate 250 ms', () async {
    final List<String> days = <String>[
      for (int i = 0; i < 50; i++)
        '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
    ];
    await measure('day totals', () async {
      final Map<String, DayTotal> t = await list.dayTotals(
        TransactionFilter.none,
        days,
      );
      expect(t, isNotEmpty);
    });
  });
}
