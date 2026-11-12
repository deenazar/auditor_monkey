import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  group('create and read', () {
    test('saves an account with a trimmed name and defaults', () async {
      final Account a = await env.accounts.create(
        accountDraft(name: '  SBI Savings  ', opening: 150000),
      );
      expect(a.name, 'SBI Savings');
      expect(a.type, AccountType.bank);
      expect(a.openingBalance, 150000);
      expect(a.archived, isFalse);
      expect((await env.accounts.getById(a.id))!.name, 'SBI Savings');
    });

    test('getById returns null for an unknown id', () async {
      expect(await env.accounts.getById('missing'), isNull);
    });

    test('lists live accounts by sort order then name', () async {
      await env.accounts.create(
        const AccountDraft(
          name: 'Zed',
          type: AccountType.cash,
          colour: 'primary',
          sortOrder: 1,
        ),
      );
      await env.accounts.create(accountDraft(name: 'beta'));
      await env.accounts.create(accountDraft(name: 'Alpha'));
      final List<Account> list = await env.accounts.watchAll().first;
      expect(list.map((Account a) => a.name), <String>['Alpha', 'beta', 'Zed']);
    });

    test('update changes the fields and bumps updated_at', () async {
      final Account a = await env.accounts.create(accountDraft());
      env.clock.advance(5000);
      final Account b = await env.accounts.update(
        a.id,
        const AccountDraft(
          name: 'Axis',
          type: AccountType.card,
          colour: 'accountAxis',
          openingBalance: -5000,
          archived: true,
        ),
      );
      expect(b.name, 'Axis');
      expect(b.type, AccountType.card);
      expect(b.openingBalance, -5000);
      expect(b.archived, isTrue);
      expect(b.createdAt, a.createdAt);
      expect(b.updatedAt, a.updatedAt + 5000);
    });

    test('update of a missing account is a NotFoundFailure', () async {
      await expectLater(
        env.accounts.update('missing', accountDraft()),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('validation', () {
    Future<void> expectInvalid(
      Future<Object?> call,
      String field,
      FailureCode code,
    ) async {
      await expectLater(
        call,
        throwsA(
          isA<ValidationFailure>()
              .having((ValidationFailure f) => f.field, 'field', field)
              .having((ValidationFailure f) => f.code, 'code', code),
        ),
      );
    }

    test('rejects an empty or blank name', () async {
      await expectInvalid(
        env.accounts.create(accountDraft(name: '   ')),
        'name',
        FailureCode.required,
      );
    });

    test('rejects a name over 40 characters, accepts exactly 40', () async {
      await expectInvalid(
        env.accounts.create(accountDraft(name: 'a' * 41)),
        'name',
        FailureCode.tooLong,
      );
      expect(
        (await env.accounts.create(accountDraft(name: 'a' * 40))).name,
        hasLength(40),
      );
    });

    test('rejects control characters in the name', () async {
      await expectInvalid(
        env.accounts.create(accountDraft(name: 'a\u0000b')),
        'name',
        FailureCode.invalidCharacters,
      );
    });

    test('rejects an unknown colour', () async {
      await expectInvalid(
        env.accounts.create(
          const AccountDraft(
            name: 'X',
            type: AccountType.cash,
            colour: '#ff0000',
          ),
        ),
        'colour',
        FailureCode.invalidChoice,
      );
    });

    test('negative opening balance only for card accounts', () async {
      for (final AccountType type in AccountType.values) {
        final Future<Account> call = env.accounts.create(
          accountDraft(name: type.name, type: type, opening: -100),
        );
        if (type == AccountType.card) {
          expect((await call).openingBalance, -100);
        } else {
          await expectInvalid(call, 'openingBalance', FailureCode.outOfRange);
        }
      }
    });

    test('opening balance limit is plus or minus maxPaise', () async {
      expect(
        (await env.accounts.create(
          accountDraft(name: 'Max', opening: maxPaise),
        )).openingBalance,
        maxPaise,
      );
      await expectInvalid(
        env.accounts.create(accountDraft(name: 'Over', opening: maxPaise + 1)),
        'openingBalance',
        FailureCode.outOfRange,
      );
      await expectInvalid(
        env.accounts.create(
          accountDraft(
            name: 'Under',
            type: AccountType.card,
            opening: -maxPaise - 1,
          ),
        ),
        'openingBalance',
        FailureCode.outOfRange,
      );
    });

    test(
      'update also validates (card to bank with negative balance)',
      () async {
        final Account card = await env.accounts.create(
          accountDraft(name: 'Card', type: AccountType.card, opening: -500),
        );
        await expectInvalid(
          env.accounts.update(
            card.id,
            accountDraft(name: 'Card', type: AccountType.bank, opening: -500),
          ),
          'openingBalance',
          FailureCode.outOfRange,
        );
      },
    );
  });

  group('unique name', () {
    test('rejects the same name ignoring case', () async {
      await env.accounts.create(accountDraft(name: 'SBI'));
      await expectLater(
        env.accounts.create(accountDraft(name: 'sbi')),
        throwsA(isA<DuplicateFailure>()),
      );
    });

    test('rejects renaming onto another account name', () async {
      await env.accounts.create(accountDraft(name: 'SBI'));
      final Account b = await env.accounts.create(accountDraft(name: 'Axis'));
      await expectLater(
        env.accounts.update(b.id, accountDraft(name: 'Sbi')),
        throwsA(isA<DuplicateFailure>()),
      );
    });

    test('a deleted account frees its name; restore then conflicts', () async {
      final Account a = await env.accounts.create(accountDraft(name: 'SBI'));
      await env.accounts.softDelete(a.id);
      final Account b = await env.accounts.create(accountDraft(name: 'SBI'));
      await expectLater(
        env.accounts.restore(a.id),
        throwsA(isA<DuplicateFailure>()),
      );
      await env.accounts.softDelete(b.id);
      expect((await env.accounts.restore(a.id)).isDeleted, isFalse);
    });
  });

  group('soft delete', () {
    test(
      'hides the account from lists and getById, restore brings it back',
      () async {
        final Account a = await env.accounts.create(accountDraft());
        env.clock.advance();
        await env.accounts.softDelete(a.id);
        expect(await env.accounts.watchAll().first, isEmpty);
        expect(await env.accounts.getById(a.id), isNull);
        final Account deleted = (await env.accounts.getById(
          a.id,
          includeDeleted: true,
        ))!;
        expect(deleted.deletedAt, env.clock.now);

        env.clock.advance();
        final Account back = await env.accounts.restore(a.id);
        expect(back.deletedAt, isNull);
        expect(await env.accounts.watchAll().first, hasLength(1));
      },
    );

    test('deleting a missing account is a NotFoundFailure', () async {
      await expectLater(
        env.accounts.softDelete('missing'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('is refused while live transactions use the account', () async {
      final Account a = await env.accounts.create(accountDraft());
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      final tx = await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: cat),
      );
      await expectLater(
        env.accounts.softDelete(a.id),
        throwsA(isA<InUseFailure>()),
      );
      await env.transactions.softDelete(tx.id);
      await env.accounts.softDelete(a.id);
    });

    test('is refused while the account is the target of a transfer', () async {
      final Account a = await env.accounts.create(accountDraft(name: 'A'));
      final Account b = await env.accounts.create(accountDraft(name: 'B'));
      await env.transactions.create(transferDraft(from: a.id, to: b.id));
      await expectLater(
        env.accounts.softDelete(b.id),
        throwsA(isA<InUseFailure>()),
      );
    });

    test('is refused while a live gold holding uses the account', () async {
      final Account a = await env.accounts.create(accountDraft());
      final h = await env.gold.createHolding(goldHoldingDraft(accountId: a.id));
      await expectLater(
        env.accounts.softDelete(a.id),
        throwsA(isA<InUseFailure>()),
      );
      await env.gold.softDeleteHolding(h.id);
      await env.accounts.softDelete(a.id);
    });
  });
}
