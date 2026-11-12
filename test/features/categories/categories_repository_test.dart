import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  group('create, update, read', () {
    test('creates a custom category after the seeded ones', () async {
      final Category c = await env.categories.create(
        categoryDraft(name: '  Pets ').copyWithSort(100),
      );
      expect(c.name, 'Pets');
      expect(c.kind, CategoryKind.expense);
      final List<Category> all = await env.categories.watchAll().first;
      expect(all, hasLength(35));
      expect(all.last.id, c.id);
    });

    test('watchAll can filter by kind', () async {
      final List<Category> income = await env.categories
          .watchAll(kind: CategoryKind.income)
          .first;
      final List<Category> expense = await env.categories
          .watchAll(kind: CategoryKind.expense)
          .first;
      expect(income, hasLength(8));
      expect(expense, hasLength(26));
    });

    test('update changes fields and bumps updated_at', () async {
      final Category c = await env.categories.create(categoryDraft());
      env.clock.advance(2000);
      final Category u = await env.categories.update(
        c.id,
        const CategoryDraft(
          name: 'Pet food',
          kind: CategoryKind.expense,
          colourGroup: CategoryColourGroup.food,
          icon: 'bone',
          archived: true,
        ),
      );
      expect(u.name, 'Pet food');
      expect(u.colourGroup, CategoryColourGroup.food);
      expect(u.archived, isTrue);
      expect(u.updatedAt, c.updatedAt + 2000);
    });

    test('kind cannot change while entries use the category', () async {
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      final Account a = await env.account('A');
      await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: cat),
      );
      await expectLater(
        env.categories.update(
          cat,
          const CategoryDraft(
            name: 'Groceries',
            kind: CategoryKind.income,
            colourGroup: CategoryColourGroup.income,
            icon: 'shopping-cart',
          ),
        ),
        throwsA(isA<InUseFailure>()),
      );
    });
  });

  group('validation', () {
    test('rejects blank name, long name, long icon', () async {
      for (final CategoryDraft d in <CategoryDraft>[
        categoryDraft(name: ' '),
        categoryDraft(name: 'x' * 41),
        const CategoryDraft(
          name: 'Ok',
          kind: CategoryKind.expense,
          colourGroup: CategoryColourGroup.other,
          icon: '',
        ),
        CategoryDraft(
          name: 'Ok',
          kind: CategoryKind.expense,
          colourGroup: CategoryColourGroup.other,
          icon: 'i' * 41,
        ),
      ]) {
        await expectLater(
          env.categories.create(d),
          throwsA(isA<ValidationFailure>()),
        );
      }
    });

    test(
      'same name is allowed in the other kind, not in the same kind',
      () async {
        await env.categories.create(categoryDraft(name: 'Misc'));
        await env.categories.create(
          categoryDraft(name: 'Misc', kind: CategoryKind.income),
        );
        await expectLater(
          env.categories.create(categoryDraft(name: 'MISC')),
          throwsA(isA<DuplicateFailure>()),
        );
      },
    );

    test('a seeded name is already taken', () async {
      await expectLater(
        env.categories.create(categoryDraft(name: 'groceries')),
        throwsA(isA<DuplicateFailure>()),
      );
    });
  });

  group('soft delete', () {
    test('is refused while live transactions use the category', () async {
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      final Account a = await env.account('A');
      final tx = await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: cat),
      );
      await expectLater(
        env.categories.softDelete(cat),
        throwsA(isA<InUseFailure>()),
      );
      await env.transactions.softDelete(tx.id);
      await env.categories.softDelete(cat);
      expect(await env.categories.getById(cat), isNull);
    });

    test(
      'also soft deletes its live budgets; restore keeps them deleted',
      () async {
        final Category c = await env.categories.create(categoryDraft());
        final Budget b1 = await env.budgets.create(
          budgetDraft(categoryId: c.id, month: '2026-10'),
        );
        final Budget b2 = await env.budgets.create(
          budgetDraft(categoryId: c.id, month: '2026-11'),
        );
        env.clock.advance();
        await env.categories.softDelete(c.id);
        expect(await env.budgets.getById(b1.id), isNull);
        expect(await env.budgets.getById(b2.id), isNull);
        final Budget gone = (await env.budgets.getById(
          b1.id,
          includeDeleted: true,
        ))!;
        expect(gone.deletedAt, env.clock.now);
        expect(gone.syncStatus.name, 'pending');

        await env.categories.restore(c.id);
        expect(await env.budgets.getById(b1.id), isNull);
      },
    );

    test('a deleted category frees its name', () async {
      final Category c = await env.categories.create(categoryDraft());
      await env.categories.softDelete(c.id);
      await env.categories.create(categoryDraft());
    });

    test('missing id is a NotFoundFailure', () async {
      await expectLater(
        env.categories.softDelete('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        env.categories.restore('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}

extension on CategoryDraft {
  CategoryDraft copyWithSort(int sortOrder) => CategoryDraft(
    name: name,
    kind: kind,
    colourGroup: colourGroup,
    icon: icon,
    sortOrder: sortOrder,
  );
}
