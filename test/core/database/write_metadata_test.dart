// Every write (create, update, soft delete, restore) on every table must:
// give a UUID v4 id, store UTC epoch ms, set updated_at = now and mark the
// row pending.
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

class _Case {
  const _Case({
    required this.table,
    required this.create,
    required this.update,
    required this.delete,
    required this.restore,
  });

  final String table;
  final Future<String> Function(TestEnv env) create;
  final Future<void> Function(TestEnv env, String id) update;
  final Future<void> Function(TestEnv env, String id) delete;
  final Future<void> Function(TestEnv env, String id) restore;
}

final List<_Case> _cases = <_Case>[
  _Case(
    table: 'accounts',
    create: (TestEnv e) async => (await e.accounts.create(accountDraft())).id,
    update: (TestEnv e, String id) async {
      await e.accounts.update(id, accountDraft(name: 'Renamed'));
    },
    delete: (TestEnv e, String id) => e.accounts.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.accounts.restore(id);
    },
  ),
  _Case(
    table: 'categories',
    create: (TestEnv e) async =>
        (await e.categories.create(categoryDraft())).id,
    update: (TestEnv e, String id) async {
      await e.categories.update(id, categoryDraft(name: 'Renamed'));
    },
    delete: (TestEnv e, String id) => e.categories.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.categories.restore(id);
    },
  ),
  _Case(
    table: 'transactions',
    create: (TestEnv e) async {
      final Account a = await e.account('Tx');
      final String c = await e.seededCategoryId('Groceries', 'expense');
      return (await e.transactions.create(
        expenseDraft(accountId: a.id, categoryId: c),
      )).id;
    },
    update: (TestEnv e, String id) async {
      final t = (await e.transactions.getById(id))!;
      await e.transactions.update(
        id,
        expenseDraft(
          accountId: t.accountId,
          categoryId: t.categoryId!,
          amount: 777,
        ),
      );
    },
    delete: (TestEnv e, String id) => e.transactions.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.transactions.restore(id);
    },
  ),
  _Case(
    table: 'budgets',
    create: (TestEnv e) async {
      final String c = await e.seededCategoryId('Fuel', 'expense');
      return (await e.budgets.create(budgetDraft(categoryId: c))).id;
    },
    update: (TestEnv e, String id) async {
      final Budget b = (await e.budgets.getById(id))!;
      await e.budgets.update(
        id,
        budgetDraft(categoryId: b.categoryId, amount: 999),
      );
    },
    delete: (TestEnv e, String id) => e.budgets.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.budgets.restore(id);
    },
  ),
  _Case(
    table: 'loans',
    create: (TestEnv e) async => (await e.loans.create(loanDraft())).id,
    update: (TestEnv e, String id) async {
      await e.loans.update(id, loanDraft(person: 'Someone'));
    },
    delete: (TestEnv e, String id) => e.loans.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.loans.restore(id);
    },
  ),
  _Case(
    table: 'gold_holdings',
    create: (TestEnv e) async =>
        (await e.gold.createHolding(goldHoldingDraft())).id,
    update: (TestEnv e, String id) async {
      await e.gold.updateHolding(id, goldHoldingDraft(weightMg: 5));
    },
    delete: (TestEnv e, String id) => e.gold.softDeleteHolding(id),
    restore: (TestEnv e, String id) async {
      await e.gold.restoreHolding(id);
    },
  ),
  _Case(
    table: 'gold_rates',
    create: (TestEnv e) async => (await e.gold.createRate(goldRateDraft())).id,
    update: (TestEnv e, String id) async {
      await e.gold.updateRate(id, goldRateDraft(rate: 5));
    },
    delete: (TestEnv e, String id) => e.gold.softDeleteRate(id),
    restore: (TestEnv e, String id) async {
      await e.gold.restoreRate(id);
    },
  ),
  _Case(
    table: 'daily_activities',
    create: (TestEnv e) async =>
        (await e.activities.create(activityDraft())).id,
    update: (TestEnv e, String id) async {
      await e.activities.update(id, activityDraft(title: 'Changed'));
    },
    delete: (TestEnv e, String id) => e.activities.softDelete(id),
    restore: (TestEnv e, String id) async {
      await e.activities.restore(id);
    },
  ),
];

void main() {
  for (final _Case c in _cases) {
    group(c.table, () {
      late TestEnv env;

      setUp(() => env = TestEnv());
      tearDown(() => env.close());

      Future<void> markSynced(String id) => env.rawSql(
        "UPDATE ${c.table} SET sync_status = 'synced' WHERE id = ?",
        <Object?>[id],
      );

      test('create: UUID v4, UTC ms, pending, live', () async {
        final String id = await c.create(env);
        expect(_uuidV4.hasMatch(id), isTrue);
        final Map<String, Object?> row = await env.rawRow(c.table, id);
        expect(row['created_at'], env.clock.now);
        expect(row['updated_at'], env.clock.now);
        expect(row['created_at'], isA<int>());
        expect(row['deleted_at'], isNull);
        expect(row['sync_status'], 'pending');
      });

      test('ids are unique', () async {
        final String a = await c.create(env);
        expect(a, isNot(await _createSecond(c, env)));
      });

      test(
        'update: updated_at moves, created_at stays, pending again',
        () async {
          final String id = await c.create(env);
          await markSynced(id);
          final int created = env.clock.now;
          env.clock.advance(60000);
          await c.update(env, id);
          final Map<String, Object?> row = await env.rawRow(c.table, id);
          expect(row['created_at'], created);
          expect(row['updated_at'], created + 60000);
          expect(row['sync_status'], 'pending');
        },
      );

      test('soft delete: deleted_at set, updated_at moves, pending', () async {
        final String id = await c.create(env);
        await markSynced(id);
        env.clock.advance(70000);
        await c.delete(env, id);
        final Map<String, Object?> row = await env.rawRow(c.table, id);
        expect(row['deleted_at'], env.clock.now);
        expect(row['updated_at'], env.clock.now);
        expect(row['sync_status'], 'pending');
      });

      test('restore: deleted_at cleared, updated_at moves, pending', () async {
        final String id = await c.create(env);
        await c.delete(env, id);
        await markSynced(id);
        env.clock.advance(80000);
        await c.restore(env, id);
        final Map<String, Object?> row = await env.rawRow(c.table, id);
        expect(row['deleted_at'], isNull);
        expect(row['updated_at'], env.clock.now);
        expect(row['sync_status'], 'pending');
      });

      test(
        'a clock that moves back never breaks updated_at >= created_at',
        () async {
          final String id = await c.create(env);
          final int created = env.clock.now;
          env.clock.now = created - 5000;
          await c.update(env, id);
          final Map<String, Object?> row = await env.rawRow(c.table, id);
          expect(row['updated_at'], created);
        },
      );
    });
  }
}

/// A second row of the same table in the same environment.
Future<String> _createSecond(_Case c, TestEnv env) async {
  // Different names / months avoid the unique rules.
  switch (c.table) {
    case 'accounts':
      return (await env.accounts.create(accountDraft(name: 'Other'))).id;
    case 'categories':
      return (await env.categories.create(categoryDraft(name: 'Other'))).id;
    case 'budgets':
      final String cat = await env.seededCategoryId('Fuel', 'expense');
      return (await env.budgets.create(
        budgetDraft(categoryId: cat, month: '2026-12'),
      )).id;
    case 'gold_rates':
      return (await env.gold.createRate(goldRateDraft(date: '2026-11-13'))).id;
    case 'transactions':
      final Account a = await env.account('Tx2');
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      return (await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: cat),
      )).id;
    default:
      return c.create(env);
  }
}
