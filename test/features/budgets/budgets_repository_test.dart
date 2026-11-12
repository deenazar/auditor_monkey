import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late String groceries;
  late String salary;

  setUp(() async {
    env = TestEnv();
    groceries = await env.seededCategoryId('Groceries', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  test('creates, reads, updates a budget', () async {
    final Budget b = await env.budgets.create(
      budgetDraft(categoryId: groceries, amount: 300000),
    );
    expect(b.month, '2026-11');
    expect(b.amount, 300000);
    env.clock.advance();
    final Budget u = await env.budgets.update(
      b.id,
      budgetDraft(categoryId: groceries, amount: 350000, month: '2026-12'),
    );
    expect(u.amount, 350000);
    expect(u.month, '2026-12');
    expect(u.updatedAt, b.updatedAt + 1000);
    expect((await env.budgets.watchForMonth('2026-12').first).single.id, b.id);
    expect(await env.budgets.watchForMonth('2026-11').first, isEmpty);
  });

  test('amount must be above zero and within the limit', () async {
    for (final int bad in <int>[0, -5, maxPaise + 1]) {
      await expectLater(
        env.budgets.create(budgetDraft(categoryId: groceries, amount: bad)),
        throwsA(isA<ValidationFailure>()),
      );
    }
    expect(
      (await env.budgets.create(
        budgetDraft(categoryId: groceries, amount: maxPaise),
      )).amount,
      maxPaise,
    );
  });

  test('bad months are rejected', () async {
    for (final String bad in <String>[
      '',
      '2026-13',
      '2026-00',
      '2026-1',
      '2026-11-01',
      '202611',
      'abcd-ef',
    ]) {
      await expectLater(
        env.budgets.create(budgetDraft(categoryId: groceries, month: bad)),
        throwsA(isA<ValidationFailure>()),
        reason: bad,
      );
    }
  });

  test('only expense categories can have a budget', () async {
    await expectLater(
      env.budgets.create(budgetDraft(categoryId: salary)),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.code,
          'code',
          FailureCode.kindMismatch,
        ),
      ),
    );
    await expectLater(
      env.budgets.create(budgetDraft(categoryId: 'nope')),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.code,
          'code',
          FailureCode.referenceMissing,
        ),
      ),
    );
  });

  test('one live budget per category and month', () async {
    final Budget first = await env.budgets.create(
      budgetDraft(categoryId: groceries),
    );
    await expectLater(
      env.budgets.create(budgetDraft(categoryId: groceries, amount: 5)),
      throwsA(isA<DuplicateFailure>()),
    );
    // Another month and another category are fine.
    await env.budgets.create(
      budgetDraft(categoryId: groceries, month: '2026-12'),
    );
    final String fuel = await env.seededCategoryId('Fuel', 'expense');
    await env.budgets.create(budgetDraft(categoryId: fuel));
    // Deleting frees the slot; restoring the old one then conflicts.
    await env.budgets.softDelete(first.id);
    final Budget second = await env.budgets.create(
      budgetDraft(categoryId: groceries),
    );
    await expectLater(
      env.budgets.restore(first.id),
      throwsA(isA<DuplicateFailure>()),
    );
    await env.budgets.softDelete(second.id);
    expect((await env.budgets.restore(first.id)).isDeleted, isFalse);
  });

  test('a budget cannot be restored while its category is deleted', () async {
    final Category c = await env.categories.create(categoryDraft());
    final Budget b = await env.budgets.create(budgetDraft(categoryId: c.id));
    await env.categories.softDelete(c.id);
    await expectLater(
      env.budgets.restore(b.id),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('watchForMonth rejects a bad month and lists only live rows', () async {
    expect(
      () => env.budgets.watchForMonth('2026-99'),
      throwsA(isA<ValidationFailure>()),
    );
    final Budget b = await env.budgets.create(
      budgetDraft(categoryId: groceries),
    );
    await env.budgets.softDelete(b.id);
    expect(await env.budgets.watchForMonth('2026-11').first, isEmpty);
  });
}
