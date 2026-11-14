@Tags(<String>['perf'])
library;

// Dashboard load speed on 20,000 rows (plan section 6). Target: under
// 300 ms. The test FAILS ONLY when the median (p50) is above 300 ms; the
// real p50 and p95 are always printed (record them in the PR).
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/home/data/dashboard_repository.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const int gateMs = 300;
const int runs = 30;

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    final Account a = await env.account('A', opening: 100000);
    final Account b = await env.account('B', opening: 100000);
    final String groceries = await env.seededCategoryId('Groceries', 'expense');
    final String fuel = await env.seededCategoryId('Fuel', 'expense');
    final String rent = await env.seededCategoryId('Rent', 'expense');
    final String salary = await env.seededCategoryId('Salary', 'income');
    await env.rawSql(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < 20000) '
      'INSERT INTO transactions (id, created_at, updated_at, sync_status, '
      'type, amount, date, account_id, to_account_id, category_id) '
      "SELECT printf('%036d', i), 1000 + i, 1000 + i, 'pending', "
      "CASE i % 4 WHEN 0 THEN 'income' WHEN 3 THEN 'transfer' "
      "ELSE 'expense' END, 100 + (i % 500), "
      "date('2026-11-12', '-' || (i % 365) || ' days'), "
      "CASE i % 2 WHEN 0 THEN '${a.id}' ELSE '${b.id}' END, "
      "CASE WHEN i % 4 = 3 THEN "
      "CASE i % 2 WHEN 0 THEN '${b.id}' ELSE '${a.id}' END END, "
      "CASE i % 4 WHEN 3 THEN NULL WHEN 0 THEN '$salary' "
      "WHEN 1 THEN '$groceries' ELSE CASE WHEN i % 8 = 2 THEN '$rent' "
      "ELSE '$fuel' END END FROM n",
    );
    expect(await env.count('transactions'), 20000);
  });
  tearDown(() => env.close());

  test(
    'Dashboard load: p50 gate 300 ms, only the recent rows in memory',
    () async {
      final DashboardRepository repo = DashboardRepository(env.ctx);
      DashboardSummary last = await repo.load(today: '2026-11-12'); // warm up
      final List<int> micros = <int>[];
      for (int i = 0; i < runs; i++) {
        final Stopwatch w = Stopwatch()..start();
        last = await repo.load(today: '2026-11-12');
        w.stop();
        micros.add(w.elapsedMicroseconds);
      }
      micros.sort();
      final double p50 = micros[((runs - 1) * 0.5).round()] / 1000;
      final double p95 = micros[((runs - 1) * 0.95).round()] / 1000;
      // ignore: avoid_print
      print(
        'PERF dashboard load on 20,000 rows: p50 ${p50.toStringAsFixed(1)} ms, '
        'p95 ${p95.toStringAsFixed(1)} ms (gate p50 <= $gateMs ms, $runs runs)',
      );

      // Sanity: the numbers are real, not an empty month.
      expect(last.spent, greaterThan(0));
      expect(last.topCategories, hasLength(3));
      // Memory: only the 5 recent rows are entities; the rest is SQL sums.
      expect(last.recent, hasLength(5));
      final LogRecord log = env.sink.records.lastWhere(
        (LogRecord r) => r.tag == 'dashboard',
      );
      final int rows = int.parse(
        RegExp(r'rows=(\d+)').firstMatch(log.message)![1]!,
      );
      // 3 top categories + 5 recent + at most 9 strip days.
      expect(rows, lessThanOrEqualTo(3 + 5 + 9));

      expect(p50, lessThanOrEqualTo(gateMs.toDouble()));
    },
  );
}
