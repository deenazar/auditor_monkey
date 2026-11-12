import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
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
    a = await env.account('A');
    b = await env.account('B');
    groceries = await env.seededCategoryId('Groceries', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  group('create, read, update, delete', () {
    test('expense, income and transfer are saved with all fields', () async {
      final TransactionEntry e = await env.transactions.create(
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 12345,
          note: ' milk ',
        ),
      );
      expect(e.type, TransactionType.expense);
      expect(e.amount, 12345);
      expect(e.note, 'milk');
      expect(e.date, day);

      final TransactionEntry i = await env.transactions.create(
        incomeDraft(accountId: a.id, categoryId: salary),
      );
      expect(i.type, TransactionType.income);

      final TransactionEntry t = await env.transactions.create(
        transferDraft(from: a.id, to: b.id),
      );
      expect(t.toAccountId, b.id);
      expect(t.categoryId, isNull);
      expect(t.loanId, isNull);
      expect((await env.transactions.getById(t.id))!.id, t.id);
    });

    test('update changes fields and keeps created_at', () async {
      final TransactionEntry e = await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: groceries),
      );
      env.clock.advance(3000);
      final TransactionEntry u = await env.transactions.update(
        e.id,
        expenseDraft(
          accountId: b.id,
          categoryId: groceries,
          amount: 99,
          date: '2026-11-13',
        ),
      );
      expect(u.accountId, b.id);
      expect(u.amount, 99);
      expect(u.date, '2026-11-13');
      expect(u.createdAt, e.createdAt);
      expect(u.updatedAt, e.updatedAt + 3000);
    });

    test('soft delete hides, restore shows again', () async {
      final TransactionEntry e = await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: groceries),
      );
      await env.transactions.softDelete(e.id);
      expect(await env.transactions.getById(e.id), isNull);
      expect(await env.transactions.page(), isEmpty);
      expect(
        (await env.transactions.getById(e.id, includeDeleted: true))!.isDeleted,
        isTrue,
      );
      await env.transactions.restore(e.id);
      expect(await env.transactions.page(), hasLength(1));
    });

    test('missing ids give NotFoundFailure', () async {
      await expectLater(
        env.transactions.softDelete('x'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        env.transactions.restore('x'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        env.transactions.update(
          'x',
          expenseDraft(accountId: a.id, categoryId: groceries),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('paging', () {
    test('newest first, keyset pages cover every row exactly once', () async {
      final List<String> expected = <String>[];
      for (int i = 0; i < 25; i++) {
        env.clock.advance(10);
        final TransactionEntry t = await env.transactions.create(
          expenseDraft(
            accountId: a.id,
            categoryId: groceries,
            amount: i + 1,
            date: '2026-11-${(i % 5 + 1).toString().padLeft(2, '0')}',
          ),
        );
        expected.add(t.id);
      }
      final List<TransactionEntry> collected = <TransactionEntry>[];
      TransactionCursor? cursor;
      while (true) {
        final List<TransactionEntry> page = await env.transactions.page(
          limit: 7,
          after: cursor,
        );
        if (page.isEmpty) break;
        collected.addAll(page);
        cursor = TransactionCursor.after(page.last);
      }
      expect(collected, hasLength(25));
      expect(
        collected.map((TransactionEntry t) => t.id).toSet(),
        expected.toSet(),
      );
      for (int i = 1; i < collected.length; i++) {
        final TransactionEntry prev = collected[i - 1];
        final TransactionEntry cur = collected[i];
        final int byDate = prev.date.compareTo(cur.date);
        expect(
          byDate > 0 || (byDate == 0 && prev.createdAt >= cur.createdAt),
          isTrue,
        );
      }
    });

    test('rows with the same date and time are not skipped', () async {
      for (int i = 0; i < 6; i++) {
        await env.transactions.create(
          expenseDraft(accountId: a.id, categoryId: groceries, amount: i + 1),
        );
      }
      final List<TransactionEntry> first = await env.transactions.page(
        limit: 4,
      );
      final List<TransactionEntry> second = await env.transactions.page(
        limit: 4,
        after: TransactionCursor.after(first.last),
      );
      expect(first.length + second.length, 6);
      expect(<String>{
        ...first.map((t) => t.id),
        ...second.map((t) => t.id),
      }, hasLength(6));
    });

    test('page size must be between 1 and 500', () async {
      await expectLater(
        env.transactions.page(limit: 0),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        env.transactions.page(limit: 501),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
