import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

/// Inserts [rows] valid income rows of [amount] paise in one SQL statement.
String _bulkIncome(int rows, int amount) =>
    'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
    'WHERE i < $rows) '
    'INSERT INTO transactions (id, created_at, updated_at, sync_status, '
    'type, amount, date, account_id, category_id) '
    "SELECT printf('%036d', i), 1000, 1000, 'pending', 'income', $amount, "
    "'2026-11-12', ?, ? FROM n";

void main() {
  late TestEnv env;
  late Account a;
  late String groceries;
  late String salary;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  test('10,000 entries of 1 paisa sum to exactly 10,000 paise', () async {
    await env.rawSql(_bulkIncome(10000, 1), <Object?>[a.id, salary]);
    expect(await env.count('transactions'), 10000);
    expect((await env.accounts.getBalances()).single.balance, 10000);
    expect(
      await env.transactions.incomeTotal(from: '2026-11-01', to: '2026-11-30'),
      10000,
    );
    // Same through the repository: add 1 paisa as an expense.
    await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: groceries, amount: 1),
    );
    expect((await env.accounts.getBalances()).single.balance, 9999);
  });

  test('entries of maxPaise sum exactly', () async {
    for (int i = 0; i < 3; i++) {
      await env.transactions.create(
        incomeDraft(accountId: a.id, categoryId: salary, amount: maxPaise),
      );
    }
    expect((await env.accounts.getBalances()).single.balance, 3 * maxPaise);
    expect(
      await env.transactions.incomeTotal(from: '2026-11-01', to: '2026-11-30'),
      3 * maxPaise,
    );
    expect(await env.accounts.watchNetWorth().first, 3 * maxPaise);
  });

  test('a stored amount is always an integer', () async {
    await env.transactions.create(
      incomeDraft(accountId: a.id, categoryId: salary, amount: 12345),
    );
    final rows = await env.db
        .customSelect(
          "SELECT COUNT(*) AS c FROM transactions WHERE typeof(amount) <> 'integer'",
        )
        .getSingle();
    expect(rows.read<int>('c'), 0);
  });

  test('raw SQL cannot store 1.5 paise (or 1.0 as text)', () async {
    for (final Object amount in <Object>[1.5, '1.5', '12abc']) {
      Object? error;
      try {
        await env.rawSql(
          'INSERT INTO transactions (id, created_at, updated_at, '
          'sync_status, type, amount, date, account_id, category_id) '
          "VALUES (?, 1000, 1000, 'pending', 'income', ?, '2026-11-12', ?, ?)",
          <Object?>['9' * 36, amount, a.id, salary],
        );
      } on Object catch (e) {
        error = e;
      }
      expect(error, isNotNull, reason: '$amount');
    }
    expect(await env.count('transactions'), 0);
  });

  group('overflow', () {
    test(
      'a total past 64 bits is an OverflowFailure, not a wrong number',
      () async {
        // 100,000 valid rows of 1e14 paise = 1e19 > 9.22e18.
        await env.rawSql(_bulkIncome(100000, maxPaise), <Object?>[
          a.id,
          salary,
        ]);
        await expectLater(
          env.accounts.getBalances(),
          throwsA(isA<OverflowFailure>()),
        );
        await expectLater(
          env.transactions.incomeTotal(from: '2026-11-01', to: '2026-11-30'),
          throwsA(isA<OverflowFailure>()),
        );
        await expectLater(
          env.accounts.watchBalances().first,
          throwsA(isA<OverflowFailure>()),
        );
        await expectLater(
          env.accounts.watchNetWorth().first,
          throwsA(isA<OverflowFailure>()),
        );
      },
    );

    test('the overflow is logged as an error without amounts', () async {
      await env.rawSql(_bulkIncome(100000, maxPaise), <Object?>[a.id, salary]);
      await expectLater(
        env.accounts.getBalances(),
        throwsA(isA<OverflowFailure>()),
      );
      final String text = env.sink.allText;
      expect(text, contains('getBalances failed: overflow'));
      expect(text, isNot(contains('100000000000000')));
    });

    test(
      'opening balance plus a big sum that overflows is caught too',
      () async {
        await env.accounts.update(
          a.id,
          accountDraft(name: 'A', opening: maxPaise),
        );
        // 92,233 x 1e14 fits, but adding the opening balance does not.
        await env.rawSql(_bulkIncome(92233, maxPaise), <Object?>[a.id, salary]);
        await expectLater(
          env.accounts.getBalances(),
          throwsA(isA<OverflowFailure>()),
        );
        await expectLater(
          env.accounts.watchNetWorth().first,
          throwsA(isA<OverflowFailure>()),
        );
      },
    );

    test('totals just under the limit still work', () async {
      await env.rawSql(_bulkIncome(92233, maxPaise), <Object?>[a.id, salary]);
      expect(
        (await env.accounts.getBalances()).single.balance,
        92233 * maxPaise,
      );
    });
  });
}
