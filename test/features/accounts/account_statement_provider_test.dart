import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/application/account_statement_provider.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/provider_env.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late ProviderContainer container;
  late Account a;
  late Account b;
  late String groceries;

  setUp(() async {
    env = TestEnv();
    container = containerFor(env);
    a = await env.account('A', opening: 100000);
    b = await env.account('B', opening: 0);
    groceries = await env.seededCategoryId('Groceries', 'expense');
  });
  tearDown(() async {
    container.dispose();
    await env.close();
  });

  Future<void> spend(Account acc, int amount, {String date = '2026-11-01'}) {
    env.clock.advance();
    return env.transactions.create(
      expenseDraft(
        accountId: acc.id,
        categoryId: groceries,
        amount: amount,
        date: date,
      ),
    );
  }

  /// Keeps the provider alive and waits until [ok] is true.
  Future<AccountStatementState> until(
    String id,
    bool Function(AccountStatementState) ok,
  ) async {
    container.listen(accountStatementProvider(id), (_, _) {});
    for (int i = 0; i < 200; i++) {
      final AccountStatementState? s = container
          .read(accountStatementProvider(id))
          .value;
      if (s != null && ok(s)) return s;
      await pumpEventQueue(times: 5);
    }
    fail('statement did not reach the expected state');
  }

  test('loads the first page with account, balance and lines', () async {
    await spend(a, 2500);
    final AccountStatementState s = await container.read(
      accountStatementProvider(a.id).future,
    );
    expect(s.account.name, 'A');
    expect(s.balance, 97500);
    expect(s.lines.single.balanceAfter, 97500);
    expect(s.hasMore, isFalse);
    expect(s.showOpeningRow, isTrue);
    expect(s.account.openingBalance, 100000);
  });

  test('an empty account has no lines and shows the opening row', () async {
    final AccountStatementState s = await container.read(
      accountStatementProvider(a.id).future,
    );
    expect(s.lines, isEmpty);
    expect(s.balance, 100000);
    expect(s.showOpeningRow, isTrue);
  });

  test('malformed and unknown ids end in NotFoundFailure', () async {
    for (final String id in <String>[
      'not-a-uuid',
      '',
      '00000000-0000-4000-8000-00000000ffff',
    ]) {
      container.listen(accountStatementProvider(id), (_, _) {});
      await expectLater(
        container.read(accountStatementProvider(id).future),
        throwsA(isA<NotFoundFailure>()),
        reason: id,
      );
    }
  });

  test('a malformed id never reaches the database', () async {
    env.sink.records.clear();
    container.listen(accountStatementProvider('not-a-uuid'), (_, _) {});
    await container
        .read(accountStatementProvider('not-a-uuid').future)
        .then<void>((_) {}, onError: (_) {});
    expect(env.sink.allText, isNot(contains('statementPage')));
    expect(env.sink.allText, isNot(contains('getBalance')));
  });

  test('paging: loadMore appends the next page, in order', () async {
    for (int i = 0; i < 120; i++) {
      await spend(
        a,
        10,
        date: '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
      );
    }
    container.listen(accountStatementProvider(a.id), (_, _) {});
    AccountStatementState s = await container.read(
      accountStatementProvider(a.id).future,
    );
    expect(s.lines, hasLength(50));
    expect(s.hasMore, isTrue);
    expect(s.showOpeningRow, isFalse);

    final notifier = container.read(accountStatementProvider(a.id).notifier);
    await notifier.loadMore();
    s = container.read(accountStatementProvider(a.id)).requireValue;
    expect(s.lines, hasLength(100));
    await notifier.loadMore();
    s = container.read(accountStatementProvider(a.id)).requireValue;
    expect(s.lines, hasLength(120));
    expect(s.hasMore, isFalse);
    expect(
      s.lines.map((StatementLine l) => l.entry.id).toSet(),
      hasLength(120),
    );
    expect(s.lines.first.balanceAfter, s.balance);
    // Nothing more: harmless.
    await notifier.loadMore();
    expect(
      container.read(accountStatementProvider(a.id)).requireValue.lines,
      hasLength(120),
    );
  });

  test('a new entry shows live and loaded pages are kept', () async {
    for (int i = 0; i < 60; i++) {
      await spend(
        a,
        10,
        date: '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
      );
    }
    container.listen(accountStatementProvider(a.id), (_, _) {});
    await container.read(accountStatementProvider(a.id).future);
    await container.read(accountStatementProvider(a.id).notifier).loadMore();
    expect(
      container.read(accountStatementProvider(a.id)).requireValue.lines,
      hasLength(60),
    );

    await spend(a, 5000, date: '2026-11-10');
    final AccountStatementState s = await until(
      a.id,
      (AccountStatementState x) => x.lines.length == 61,
    );
    expect(s.lines.first.effect, -5000);
    expect(s.balance, 100000 - 600 - 5000);
    expect(s.lines.first.balanceAfter, s.balance);
  });

  test('editing the opening balance refreshes the running balances', () async {
    await spend(a, 1000);
    await container.read(accountStatementProvider(a.id).future);
    await env.accounts.editAccount(
      a.id,
      const AccountDetails(
        name: 'A Renamed',
        type: AccountType.bank,
        colour: 'sun',
        openingBalance: 500000,
      ),
    );
    final AccountStatementState s = await until(
      a.id,
      (AccountStatementState x) => x.account.name == 'A Renamed',
    );
    expect(s.balance, 499000);
    expect(s.lines.single.balanceAfter, 499000);
    expect(s.account.colour, 'sun');
  });

  test('a transfer from another account shows on this statement', () async {
    await container.read(accountStatementProvider(a.id).future);
    env.clock.advance();
    await env.transactions.create(
      transferDraft(from: b.id, to: a.id, amount: 700),
    );
    final AccountStatementState s = await until(
      a.id,
      (AccountStatementState x) => x.lines.length == 1,
    );
    expect(s.lines.single.counterpartName, 'B');
    expect(s.balance, 100700);
  });

  test('a deleted account turns into NotFound', () async {
    container.listen(accountStatementProvider(b.id), (_, _) {});
    await container.read(accountStatementProvider(b.id).future);
    await env.accounts.softDelete(b.id);
    for (int i = 0; i < 100; i++) {
      if (container.read(accountStatementProvider(b.id)).hasError) break;
      await pumpEventQueue(times: 5);
    }
    expect(
      container.read(accountStatementProvider(b.id)).error,
      isA<NotFoundFailure>(),
    );
  });

  test('provider is dropped when nobody listens (no leaked streams)', () async {
    final ProviderSubscription<AsyncValue<AccountStatementState>> sub =
        container.listen(accountStatementProvider(a.id), (_, _) {});
    await container.read(accountStatementProvider(a.id).future);
    sub.close();
    await pumpEventQueue();
    // A change after dispose must not throw.
    await spend(a, 100);
    await pumpEventQueue();
  });

  test('balances and net worth follow an account edit live', () async {
    container.listen(accountBalancesProvider, (_, _) {});
    container.listen(netWorthProvider, (_, _) {});
    List<AccountBalance> balances = await container.read(
      accountBalancesProvider.future,
    );
    expect(balances.first.balance, 100000);
    await env.accounts.editAccount(
      a.id,
      const AccountDetails(
        name: 'A',
        type: AccountType.bank,
        colour: 'sun',
        openingBalance: 250000,
      ),
    );
    for (int i = 0; i < 100; i++) {
      balances = container.read(accountBalancesProvider).requireValue;
      if (balances.first.balance == 250000) break;
      await pumpEventQueue(times: 5);
    }
    expect(balances.first.balance, 250000);
    expect(container.read(netWorthProvider).requireValue, 250000);
  });

  group('monthly totals provider', () {
    test('six months, this month last, from the fake clock', () async {
      env.clock.now = DateTime(2026, 11, 12, 12).millisecondsSinceEpoch;
      await spend(a, 300, date: '2026-11-02');
      await spend(a, 100, date: '2026-06-30');
      await spend(a, 999, date: '2026-05-31');
      container.listen(accountMonthlyTotalsProvider(a.id), (_, _) {});
      final List<MonthlyTotal> t = await container.read(
        accountMonthlyTotalsProvider(a.id).future,
      );
      expect(t.map((MonthlyTotal m) => m.month), <String>[
        '2026-06',
        '2026-07',
        '2026-08',
        '2026-09',
        '2026-10',
        '2026-11',
      ]);
      expect(t.first.expense, 100);
      expect(t.last.expense, 300);
    });
  });
}
