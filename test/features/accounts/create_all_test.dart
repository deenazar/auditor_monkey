import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  group('createAll', () {
    test('saves every draft in order with sort order 0..n', () async {
      final List<Account> saved = await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'Hand', type: AccountType.cash),
        accountDraft(name: 'SBI', opening: 500000),
        accountDraft(name: 'Card', type: AccountType.card, opening: -12000),
      ]);
      expect(saved.map((Account a) => a.name), <String>['Hand', 'SBI', 'Card']);
      expect(saved.map((Account a) => a.sortOrder), <int>[0, 1, 2]);
      final List<AccountBalance> balances = await env.accounts.getBalances();
      expect(balances.map((AccountBalance b) => b.balance), <int>[
        0,
        500000,
        -12000,
      ]);
      expect((await env.accounts.getBalances()).first.account.name, 'Hand');
    });

    test('new accounts go after existing ones', () async {
      await env.account('Old');
      final List<Account> saved = await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'A'),
        accountDraft(name: 'B'),
      ]);
      expect(saved.map((Account a) => a.sortOrder), <int>[1, 2]);
    });

    test('rows are marked pending with metadata', () async {
      final List<Account> saved = await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'A'),
      ]);
      final Map<String, Object?> raw = await env.rawRow(
        'accounts',
        saved.single.id,
      );
      expect(raw['sync_status'], 'pending');
      expect(raw['created_at'], env.clock.now);
    });

    test('one bad draft saves nothing', () async {
      await expectLater(
        env.accounts.createAll(<AccountDraft>[
          accountDraft(name: 'Good'),
          accountDraft(name: ''),
        ]),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await env.count('accounts'), 0);
    });

    test('bank negative is refused, card negative is fine', () async {
      await expectLater(
        env.accounts.createAll(<AccountDraft>[
          accountDraft(name: 'Bank', opening: -1),
        ]),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await env.count('accounts'), 0);
      await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'Card', type: AccountType.card, opening: -1),
      ]);
      expect(await env.count('accounts'), 1);
    });

    test('names repeated in the list (even by case) save nothing', () async {
      await expectLater(
        env.accounts.createAll(<AccountDraft>[
          accountDraft(name: 'SBI'),
          accountDraft(name: 'Axis'),
          accountDraft(name: ' sbi '),
        ]),
        throwsA(isA<DuplicateFailure>()),
      );
      expect(await env.count('accounts'), 0);
    });

    test('a name that already exists rolls everything back', () async {
      await env.account('Axis');
      await expectLater(
        env.accounts.createAll(<AccountDraft>[
          accountDraft(name: 'SBI'),
          accountDraft(name: 'AXIS'),
        ]),
        throwsA(isA<DuplicateFailure>()),
      );
      expect(await env.count('accounts'), 1);
    });

    test('empty and oversized lists are refused', () async {
      await expectLater(
        env.accounts.createAll(<AccountDraft>[]),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        env.accounts.createAll(<AccountDraft>[
          for (int i = 0; i < 51; i++) accountDraft(name: 'A$i'),
        ]),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('fixed ids are used, others are random', () async {
      final List<Account> saved = await env.accounts.createAll(
        <AccountDraft>[accountDraft(name: 'A'), accountDraft(name: 'B')],
        fixedIds: <String?>[accountPresets.first.id, null],
      );
      expect(saved.first.id, accountPresets.first.id);
      expect(saved.last.id, isNot(accountPresets.first.id));
      expect(saved.last.id, hasLength(36));
    });

    test('bad, repeated or miscounted fixed ids save nothing', () async {
      for (final List<String?> ids in <List<String?>>[
        <String?>['not-a-uuid', null],
        <String?>[accountPresets.first.id, accountPresets.first.id],
        <String?>[accountPresets.first.id],
      ]) {
        await expectLater(
          env.accounts.createAll(<AccountDraft>[
            accountDraft(name: 'A'),
            accountDraft(name: 'B'),
          ], fixedIds: ids),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(await env.count('accounts'), 0);
    });

    test('the log has a count and no names or amounts', () async {
      await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'Secret Bank', opening: 123456789),
      ]);
      expect(env.sink.allText, contains('createAll'));
      expect(env.sink.allText, isNot(contains('Secret')));
      expect(env.sink.allText, isNot(contains('123456789')));
    });
  });

  group('addAccount', () {
    test('goes last and uses a random id', () async {
      await env.accounts.createAll(<AccountDraft>[
        accountDraft(name: 'A'),
        accountDraft(name: 'B'),
      ]);
      final Account added = await env.accounts.addAccount(
        const AccountDetails(
          name: 'Wallet',
          type: AccountType.wallet,
          colour: 'lime',
          openingBalance: 4200,
        ),
      );
      expect(added.sortOrder, 2);
      expect(added.openingBalance, 4200);
      expect(added.colour, 'lime');
      expect((await env.accounts.getBalances()).last.balance, 4200);
    });

    test('same checks as the wizard', () async {
      await env.account('SBI');
      for (final AccountDetails d in <AccountDetails>[
        const AccountDetails(
          name: 'sbi',
          type: AccountType.bank,
          colour: 'sun',
        ),
        const AccountDetails(name: '', type: AccountType.bank, colour: 'sun'),
        const AccountDetails(name: 'X', type: AccountType.bank, colour: 'pink'),
        const AccountDetails(
          name: 'X',
          type: AccountType.cash,
          colour: 'sun',
          openingBalance: -5,
        ),
      ]) {
        await expectLater(
          env.accounts.addAccount(d),
          throwsA(isA<DataFailure>()),
        );
      }
      expect(await env.count('accounts'), 1);
    });
  });

  group('editAccount', () {
    test('changes the four fields and keeps order and archive state', () async {
      final Account a = await env.account('A');
      await env.account('B');
      await env.accounts.update(
        a.id,
        const AccountDraft(
          name: 'A',
          type: AccountType.bank,
          colour: 'accountSbi',
          sortOrder: 7,
          archived: true,
        ),
      );
      env.clock.advance();
      final Account edited = await env.accounts.editAccount(
        a.id,
        const AccountDetails(
          name: '  Renamed ',
          type: AccountType.card,
          colour: 'sun',
          openingBalance: -9900,
        ),
      );
      expect(edited.name, 'Renamed');
      expect(edited.type, AccountType.card);
      expect(edited.colour, 'sun');
      expect(edited.openingBalance, -9900);
      expect(edited.sortOrder, 7);
      expect(edited.archived, isTrue);
      expect(edited.syncStatus.name, 'pending');
    });

    test('the balance follows the new opening balance', () async {
      final Account a = await env.account('A', opening: 1000);
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: cat, amount: 300),
      );
      await env.accounts.editAccount(
        a.id,
        const AccountDetails(
          name: 'A',
          type: AccountType.bank,
          colour: 'accountSbi',
          openingBalance: 5000,
        ),
      );
      expect((await env.accounts.getBalance(a.id))!.balance, 4700);
    });

    test('duplicate name is refused, own name is fine', () async {
      final Account a = await env.account('A');
      await env.account('B');
      const AccountDetails own = AccountDetails(
        name: 'a',
        type: AccountType.bank,
        colour: 'sun',
      );
      await env.accounts.editAccount(a.id, own);
      await expectLater(
        env.accounts.editAccount(
          a.id,
          const AccountDetails(
            name: 'b',
            type: AccountType.bank,
            colour: 'sun',
          ),
        ),
        throwsA(isA<DuplicateFailure>()),
      );
    });

    test('negative opening only for card; type change is checked', () async {
      final Account card = await env.account(
        'Card',
        type: AccountType.card,
        opening: -500,
      );
      await expectLater(
        env.accounts.editAccount(
          card.id,
          const AccountDetails(
            name: 'Card',
            type: AccountType.bank,
            colour: 'sun',
            openingBalance: -500,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await env.accounts.getById(card.id))!.type, AccountType.card);
    });

    test('unknown or deleted account is NotFound', () async {
      await expectLater(
        env.accounts.editAccount(
          accountPresets.first.id,
          const AccountDetails(
            name: 'X',
            type: AccountType.bank,
            colour: 'sun',
          ),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('the log has no names or amounts', () async {
      final Account a = await env.account('A');
      await env.accounts.editAccount(
        a.id,
        const AccountDetails(
          name: 'Hidden Name',
          type: AccountType.bank,
          colour: 'sun',
          openingBalance: 987654321,
        ),
      );
      expect(env.sink.allText, isNot(contains('Hidden')));
      expect(env.sink.allText, isNot(contains('987654321')));
    });
  });

  group('setup done rule', () {
    test('watchHasAccounts follows live accounts (archived count)', () async {
      final List<bool> seen = <bool>[];
      final sub = env.accounts.watchHasAccounts().listen(seen.add);
      await pumpEventQueue();
      final Account a = await env.account('A');
      await pumpEventQueue();
      await env.accounts.update(
        a.id,
        const AccountDraft(
          name: 'A',
          type: AccountType.bank,
          colour: 'sun',
          archived: true,
        ),
      );
      await pumpEventQueue();
      await env.accounts.softDelete(a.id);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isFalse);
      expect(seen, contains(true));
      expect(seen.last, isFalse);
    });
  });
}
