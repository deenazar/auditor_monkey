// Performance checks: the hot queries must use indexes, and balances on a
// 20,000-row table must stay fast. Timings are only printed (recorded), never
// asserted, so slow CI machines cannot make the test flaky.
import 'package:auditor_monkey/core/database/daos/accounts_dao.dart';
import 'package:auditor_monkey/core/database/daos/loans_dao.dart';
import 'package:auditor_monkey/core/database/daos/transactions_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const String _a1 = '00000000-0000-4000-8000-0000000000a1';
const String _a2 = '00000000-0000-4000-8000-0000000000a2';
const String _a3 = '00000000-0000-4000-8000-0000000000a3';

void main() {
  late TestEnv env;
  late String expenseCat;
  late String incomeCat;

  setUp(() async {
    env = TestEnv();
    expenseCat = await env.seededCategoryId('Groceries', 'expense');
    incomeCat = await env.seededCategoryId('Salary', 'income');
    for (final (String id, String name) in <(String, String)>[
      (_a1, 'A1'),
      (_a2, 'A2'),
      (_a3, 'A3'),
    ]) {
      await env.rawSql(
        'INSERT INTO accounts (id, created_at, updated_at, name, type, '
        "colour, opening_balance) VALUES (?, 1, 1, ?, 'bank', 'primary', 1000)",
        <Object?>[id, name],
      );
    }
  });
  tearDown(() => env.close());

  Future<String> plan(
    String sql, [
    List<Variable<Object>> vars = const [],
  ]) async {
    final rows = await env.db
        .customSelect('EXPLAIN QUERY PLAN $sql', variables: vars)
        .get();
    return rows.map((r) => r.read<String>('detail')).join('\n');
  }

  Future<void> seed(int rows) => env.rawSql(
    'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
    'WHERE i < $rows) '
    'INSERT INTO transactions (id, created_at, updated_at, sync_status, type, '
    'amount, date, account_id, to_account_id, category_id) '
    "SELECT printf('%036d', i), 1000 + i, 1000 + i, 'pending', "
    "CASE i % 4 WHEN 0 THEN 'income' WHEN 3 THEN 'transfer' ELSE 'expense' END, "
    '100 + (i % 500), '
    "'2026-' || printf('%02d', 1 + (i % 12)) || '-' || printf('%02d', 1 + (i % 28)), "
    "CASE i % 3 WHEN 0 THEN '$_a1' WHEN 1 THEN '$_a2' ELSE '$_a3' END, "
    "CASE WHEN i % 4 = 3 THEN CASE i % 3 WHEN 0 THEN '$_a2' ELSE '$_a1' END END, "
    "CASE i % 4 WHEN 3 THEN NULL WHEN 0 THEN '$incomeCat' ELSE '$expenseCat' END "
    'FROM n',
  );

  test('balance query uses the account indexes', () async {
    await seed(50);
    final String p = await plan(balancesSql);
    expect(p, contains('ix_tx_account'));
    expect(p, contains('ix_tx_to_account'));
  });

  test('date paging uses the date index, with and without a cursor', () async {
    await seed(50);
    final String first = await plan(
      transactionPageSql(hasCursor: false),
      <Variable<Object>>[const Variable<int>(50)],
    );
    expect(first, contains('ix_tx_date'));
    final String next = await plan(
      transactionPageSql(hasCursor: true),
      <Variable<Object>>[
        const Variable<String>('2026-06-01'),
        const Variable<int>(5000),
        const Variable<String>('x'),
        const Variable<int>(50),
      ],
    );
    expect(next, contains('ix_tx_date'));
  });

  test('spending sums and loan lookups use indexes', () async {
    await seed(50);
    final String sums = await plan(expenseByCategorySql, <Variable<Object>>[
      const Variable<String>('2026-11-01'),
      const Variable<String>('2026-11-30'),
    ]);
    expect(
      sums,
      anyOf(contains('ix_tx_date'), contains('ix_tx_category_date')),
    );
    final String total = await plan(transactionTotalSql, <Variable<Object>>[
      const Variable<String>('expense'),
      const Variable<String>('2026-11-01'),
      const Variable<String>('2026-11-30'),
    ]);
    expect(
      total,
      anyOf(contains('ix_tx_date'), contains('ix_tx_category_date')),
    );
    expect(await plan(loanOutstandingSql), contains('ix_tx_loan'));
  });

  test('gold holdings by account use their index', () async {
    expect(
      await plan(
        'SELECT * FROM gold_holdings WHERE account_id = ?',
        <Variable<Object>>[const Variable<String>(_a1)],
      ),
      contains('ix_gold_holdings_account'),
    );
  });

  test('balances and paging on 20,000 rows (timings recorded)', () async {
    await seed(20000);
    expect(await env.count('transactions'), 20000);

    final Stopwatch balances = Stopwatch()..start();
    final result = await env.accounts.getBalances();
    balances.stop();
    expect(result, hasLength(3));

    final Stopwatch page = Stopwatch()..start();
    final rows = await env.transactions.page(limit: 50);
    page.stop();
    expect(rows, hasLength(50));

    final Stopwatch sums = Stopwatch()..start();
    await env.transactions.expenseTotal(from: '2026-01-01', to: '2026-12-31');
    sums.stop();

    // ignore: avoid_print
    print(
      'PERF 20,000 rows: balances ${balances.elapsedMilliseconds} ms, '
      'first page ${page.elapsedMilliseconds} ms, '
      'year expense total ${sums.elapsedMilliseconds} ms',
    );
  });
}
