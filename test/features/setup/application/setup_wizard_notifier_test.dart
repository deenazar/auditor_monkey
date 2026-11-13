import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_notifier.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_state.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/provider_env.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late ProviderContainer container;

  setUp(() {
    env = TestEnv();
    container = containerFor(env);
    // autoDispose provider: keep it alive for the whole test.
    container.listen(setupWizardProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await env.close();
  });

  SetupWizardNotifier notifier() =>
      container.read(setupWizardProvider.notifier);
  SetupWizardState state() => container.read(setupWizardProvider);
  String key(String name) =>
      state().accounts.firstWhere((WizardAccount a) => a.name == name).key;

  test('starts on welcome with the 7 presets, all picked', () {
    expect(state().step, WizardStep.welcome);
    expect(state().accounts.map((WizardAccount a) => a.name), <String>[
      'Hand',
      'SBI',
      'Axis',
      'SCB',
      'Food Card',
      'Outside',
      'PF',
    ]);
    expect(state().selected, hasLength(7));
    expect(state().accounts.every((WizardAccount a) => a.isPreset), isTrue);
  });

  test('building the state does not touch the database', () async {
    notifier().next();
    notifier().toggle(key('SBI'));
    expect(await env.count('accounts'), 0);
  });

  group('steps', () {
    test('welcome -> pick -> balances -> review and back', () {
      expect(notifier().next(), isTrue);
      expect(state().step, WizardStep.pick);
      expect(notifier().next(), isTrue);
      expect(state().step, WizardStep.balances);
      expect(notifier().next(), isTrue);
      expect(state().step, WizardStep.review);
      expect(notifier().next(), isFalse);
      expect(notifier().back(), isTrue);
      expect(state().step, WizardStep.balances);
      expect(notifier().back(), isTrue);
      expect(notifier().back(), isTrue);
      expect(state().step, WizardStep.welcome);
      expect(notifier().back(), isFalse); // leave the app
    });

    test('Continue is blocked with nothing picked', () {
      notifier().next();
      for (final WizardAccount a in state().accounts) {
        notifier().toggle(a.key);
      }
      expect(state().selected, isEmpty);
      expect(state().canContinueFromPick, isFalse);
      expect(notifier().next(), isFalse);
      expect(state().step, WizardStep.pick);
      notifier().toggle(key('PF'));
      expect(state().canContinueFromPick, isTrue);
    });

    test('Continue is blocked by an invalid amount', () {
      notifier()
        ..next()
        ..next()
        ..setBalanceText(key('SBI'), 'abc');
      expect(notifier().next(), isFalse);
      expect(state().balanceError(state().accounts[1]), isNotNull);
      notifier().setBalanceText(key('SBI'), '1,000');
      expect(notifier().next(), isTrue);
    });

    test('going back keeps what was entered', () {
      notifier()
        ..next()
        ..toggle(key('Axis'))
        ..next()
        ..setBalanceText(key('SBI'), '500')
        ..next()
        ..back()
        ..back();
      expect(state().step, WizardStep.pick);
      expect(state().accounts[2].selected, isFalse);
      expect(state().accounts[1].balanceText, '500');
    });
  });

  group('add / edit', () {
    test('adds a custom account, picked, with a unique key', () {
      expect(
        notifier().addCustom(
          name: ' Wallet ',
          type: AccountType.wallet,
          colour: 'lime',
        ),
        isNull,
      );
      expect(
        notifier().addCustom(
          name: 'Other',
          type: AccountType.other,
          colour: 'sun',
        ),
        isNull,
      );
      final List<WizardAccount> accounts = state().accounts;
      expect(accounts, hasLength(9));
      expect(accounts[7].name, 'Wallet');
      expect(accounts[7].selected, isTrue);
      expect(accounts[7].isPreset, isFalse);
      expect(accounts[7].key, isNot(accounts[8].key));
    });

    test('refuses empty, long, repeated (any case) names and bad colours', () {
      String? add(String name, [String colour = 'sun']) => notifier().addCustom(
        name: name,
        type: AccountType.bank,
        colour: colour,
      );
      expect(add(''), isNotNull);
      expect(add('A' * 41), isNotNull);
      expect(add('sbi'), isNotNull);
      expect(add(' HAND '), isNotNull);
      expect(add('Fine', 'pink'), isNotNull);
      expect(state().accounts, hasLength(7));
    });

    test('rename a preset keeps its fixed id; duplicates refused', () {
      final String sbi = key('SBI');
      expect(
        notifier().editAccount(
          sbi,
          name: 'HDFC',
          type: AccountType.bank,
          colour: 'primary',
        ),
        isNull,
      );
      final WizardAccount a = state().accounts[1];
      expect(a.name, 'HDFC');
      expect(a.colour, 'primary');
      expect(a.presetId, accountPresets[1].id);
      expect(
        notifier().editAccount(
          sbi,
          name: 'axis',
          type: AccountType.bank,
          colour: 'primary',
        ),
        isNotNull,
      );
      expect(state().accounts[1].name, 'HDFC');
      // Keeping its own name is fine.
      expect(
        notifier().editAccount(
          sbi,
          name: 'hdfc',
          type: AccountType.bank,
          colour: 'primary',
        ),
        isNull,
      );
    });

    test('changing a card to another type clears "I owe"', () {
      notifier().addCustom(name: 'Card', type: AccountType.card, colour: 'sun');
      final String card = key('Card');
      notifier().setOwes(card, true);
      expect(state().accounts.last.owes, isTrue);
      notifier().editAccount(
        card,
        name: 'Card',
        type: AccountType.bank,
        colour: 'sun',
      );
      expect(state().accounts.last.owes, isFalse);
    });

    test('only custom accounts can be removed', () {
      notifier().addCustom(name: 'Tmp', type: AccountType.bank, colour: 'sun');
      notifier()
        ..removeCustom(key('SBI'))
        ..removeCustom(key('Tmp'));
      expect(state().accounts, hasLength(7));
    });

    test('unknown keys are ignored', () {
      notifier()
        ..toggle('nope')
        ..setBalanceText('nope', '5')
        ..setOwes('nope', true);
      expect(state().accounts, hasLength(7));
      expect(
        notifier().editAccount(
          'nope',
          name: 'X',
          type: AccountType.bank,
          colour: 'sun',
        ),
        isNotNull,
      );
    });
  });

  group('amounts', () {
    test('parse typed text; empty = 0; invalid has a message', () {
      final WizardAccount hand = state().accounts.first;
      expect(state().openingFor(hand).paise, 0);
      notifier().setBalanceText(hand.key, '1,23,456.50');
      expect(state().openingFor(state().accounts.first).paise, 12345650);
      for (final String bad in <String>['abc', '-5', '1e14', '1.234']) {
        notifier().setBalanceText(hand.key, bad);
        expect(
          state().balanceError(state().accounts.first),
          isNotNull,
          reason: bad,
        );
      }
      notifier().setBalanceText(hand.key, '10,00,00,00,00,001');
      expect(state().balanceError(state().accounts.first), contains('large'));
    });

    test('"I owe" works for card accounts only', () {
      notifier().addCustom(name: 'Card', type: AccountType.card, colour: 'sun');
      final String card = key('Card');
      notifier()
        ..setBalanceText(card, '2,000')
        ..setOwes(card, true)
        ..setOwes(key('SBI'), true);
      expect(state().openingFor(state().accounts.last).paise, -200000);
      expect(state().accounts[1].owes, isFalse);
    });

    test('total is integer paise of the picked accounts, null if invalid', () {
      notifier()
        ..setBalanceText(key('Hand'), '100.50')
        ..setBalanceText(key('SBI'), '1,000')
        ..toggle(key('Axis'))
        ..setBalanceText(key('Axis'), '999');
      expect(state().totalPaise, 10050 + 100000);
      notifier().setBalanceText(key('SBI'), 'x');
      expect(state().totalPaise, isNull);
    });
  });

  group('save', () {
    Future<void> ready() async {
      notifier()
        ..next()
        ..next()
        ..next();
    }

    test('creates the picked accounts with fixed ids and balances', () async {
      notifier()
        ..toggle(key('Outside'))
        ..toggle(key('PF'))
        ..setBalanceText(key('SBI'), '12,345.50')
        ..addCustom(name: 'Card', type: AccountType.card, colour: 'accountScb');
      final String card = key('Card');
      notifier()
        ..setBalanceText(card, '800')
        ..setOwes(card, true);
      await ready();
      expect(await notifier().save(), isTrue);
      expect(state().saveStatus, WizardSaveStatus.done);

      final List<AccountBalance> saved = await env.accounts.getBalances();
      expect(saved.map((AccountBalance b) => b.account.name), <String>[
        'Hand',
        'SBI',
        'Axis',
        'SCB',
        'Food Card',
        'Card',
      ]);
      expect(saved.map((AccountBalance b) => b.account.sortOrder), <int>[
        0,
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(saved[1].balance, 1234550);
      expect(saved.last.balance, -80000);
      expect(saved.first.account.id, accountPresets.first.id);
      expect(saved[1].account.id, accountPresets[1].id);
      expect(
        saved.last.account.id,
        isNot(anyOf(accountPresets.map((p) => p.id))),
      );
    });

    test('a renamed preset still has its fixed id', () async {
      notifier().editAccount(
        key('SBI'),
        name: 'HDFC',
        type: AccountType.bank,
        colour: 'primary',
      );
      await ready();
      await notifier().save();
      final AccountBalance b = (await env.accounts.getBalances()).firstWhere(
        (AccountBalance x) => x.account.name == 'HDFC',
      );
      expect(b.account.id, accountPresets[1].id);
    });

    test('a double tap saves once', () async {
      await ready();
      final Future<bool> first = notifier().save();
      expect(state().isSaving, isTrue);
      final Future<bool> second = notifier().save();
      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(await notifier().save(), isFalse);
      expect(await env.count('accounts'), 7);
    });

    test('back is swallowed while saving', () async {
      await ready();
      final Future<bool> saving = notifier().save();
      expect(notifier().back(), isTrue);
      expect(state().step, WizardStep.review);
      await saving;
    });

    test(
      'failure keeps every entry and shows a message; retry works',
      () async {
        await env.account('Axis'); // a name the wizard will clash with
        notifier().setBalanceText(key('SBI'), '777');
        await ready();
        expect(await notifier().save(), isFalse);
        expect(state().saveStatus, WizardSaveStatus.failed);
        expect(state().saveError, isNotEmpty);
        expect(state().step, WizardStep.review);
        expect(state().accounts[1].balanceText, '777');
        expect(await env.count('accounts'), 1); // all or nothing

        notifier().toggle(key('Axis'));
        expect(await notifier().save(), isTrue);
        expect(state().saveError, isNull);
        expect(await env.count('accounts'), 7);
      },
    );

    test('invalid state does not save', () async {
      notifier().setBalanceText(key('SBI'), 'abc');
      expect(await notifier().save(), isFalse);
      expect(await env.count('accounts'), 0);
      expect(state().saveStatus, WizardSaveStatus.idle);
    });

    test('logs have no names or amounts', () async {
      final String sbi = key('SBI');
      notifier()
        ..editAccount(
          sbi,
          name: 'Secret Bank',
          type: AccountType.bank,
          colour: 'primary',
        )
        ..setBalanceText(sbi, '98,76,543');
      await ready();
      await notifier().save();
      expect(env.sink.allText, contains('wizard'));
      expect(env.sink.allText, isNot(contains('Secret')));
      expect(env.sink.allText, isNot(contains('9876543')));
      expect(env.sink.allText, isNot(contains('98,76,543')));
    });
  });
}
