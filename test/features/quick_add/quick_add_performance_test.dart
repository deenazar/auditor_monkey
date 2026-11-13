@Tags(<String>['perf'])
library;

// Quick Add speed on 20,000 rows. The owner's "done when": an entry saves in
// under 100 ms. The target is 100 ms; the test FAILS ONLY when the median
// (p50) is above 250 ms, so a slow CI machine cannot make it flaky. The real
// p50 and p95 are always printed (record them in the PR).
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/provider_env.dart';
import '../../support/quick_add_env.dart';
import '../../support/test_env.dart';

/// Target and hard gate of the median, in milliseconds.
const int targetMs = 100;
const int gateMs = 250;

int percentile(List<int> sortedMicros, double p) =>
    sortedMicros[((sortedMicros.length - 1) * p).round()];

String report(String name, List<int> micros) {
  final List<int> sorted = List<int>.of(micros)..sort();
  final double p50 = percentile(sorted, 0.5) / 1000;
  final double p95 = percentile(sorted, 0.95) / 1000;
  return 'PERF $name on 20,000 rows: p50 ${p50.toStringAsFixed(1)} ms, '
      'p95 ${p95.toStringAsFixed(1)} ms (target $targetMs ms, '
      'gate p50 <= $gateMs ms, ${sorted.length} runs)';
}

void main() {
  late TestEnv env;
  late List<Account> acc;
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = quickAddTestEnv();
    acc = await threeAccounts(env);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
    // 20,000 mixed rows over the last 120 days (about 75% are inside the
    // 90-day Quick Add window): the realistic worst case for the queries.
    await env.rawSql(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < 20000) '
      'INSERT INTO transactions (id, created_at, updated_at, sync_status, '
      'type, amount, date, account_id, to_account_id, category_id) '
      "SELECT printf('%036d', i), 1000 + i, 1000 + i, 'pending', "
      "CASE i % 4 WHEN 0 THEN 'income' WHEN 3 THEN 'transfer' "
      "ELSE 'expense' END, 100 + (i % 500), "
      "date('2026-11-12', '-' || (i % 120) || ' days'), "
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

  test(
    'save through the notifier (validate + write): p50 gate 250 ms',
    () async {
      final List<int> micros = <int>[];
      for (int i = 0; i < 20; i++) {
        final QuickAddHarness h = QuickAddHarness(env);
        await h.loaded();
        h.type('${250 + i}');
        final Stopwatch watch = Stopwatch()..start();
        await h.notifier.save();
        watch.stop();
        expect(h.state.status, SaveStatus.done);
        micros.add(watch.elapsedMicroseconds);
        h.dispose();
        env.clock.advance();
      }
      expect(await env.count('transactions'), 20020);
      // ignore: avoid_print
      print(report('save', micros));
      final List<int> sorted = List<int>.of(micros)..sort();
      expect(
        percentile(sorted, 0.5) / 1000,
        lessThanOrEqualTo(gateMs),
        reason: 'median save time is above the $gateMs ms gate',
      );
    },
  );

  test('open data (accounts, categories, hints): p50 gate 250 ms', () async {
    final List<int> micros = <int>[];
    for (int i = 0; i < 10; i++) {
      final ProviderContainer c = containerFor(env);
      c.listen(quickAddDataProvider, (_, _) {});
      final Stopwatch watch = Stopwatch()..start();
      final QuickAddData data = await c.read(quickAddDataProvider.future);
      watch.stop();
      expect(data.accounts, hasLength(3));
      expect(data.recent, isNotEmpty);
      expect(data.expenseCategories.suggested, isNotEmpty);
      micros.add(watch.elapsedMicroseconds);
      c.dispose();
    }
    // ignore: avoid_print
    print(report('open data', micros));
    final List<int> sorted = List<int>.of(micros)..sort();
    expect(
      percentile(sorted, 0.5) / 1000,
      lessThanOrEqualTo(gateMs),
      reason: 'median open-data time is above the $gateMs ms gate',
    );
  });
}
