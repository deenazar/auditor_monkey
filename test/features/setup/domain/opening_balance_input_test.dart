import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/setup/domain/opening_balance_input.dart';
import 'package:flutter_test/flutter_test.dart';

OpeningBalanceInput _p(
  String text, {
  AccountType type = AccountType.bank,
  bool owes = false,
}) => parseOpeningBalance(text, type: type, owes: owes);

void main() {
  group('parseOpeningBalance', () {
    test('empty and spaces mean zero', () {
      expect(_p('').paise, 0);
      expect(_p('   ').paise, 0);
      expect(_p('').isValid, isTrue);
    });

    test('plain, Indian grouped, Western grouped and rupee sign', () {
      expect(_p('1,23,456.50').paise, 12345650);
      expect(_p('123456.5').paise, 12345650);
      expect(_p('123,456').paise, 12345600);
      expect(_p('₹1,500').paise, 150000);
      expect(_p('.5').paise, 50);
      expect(_p('0').paise, 0);
    });

    test('bad text gives a friendly error and no number', () {
      for (final String bad in <String>[
        'abc',
        '-5',
        '1.234',
        '1..2',
        '1,2,3',
        '12 34',
        '--',
        '5-',
      ]) {
        final OpeningBalanceInput r = _p(bad);
        expect(r.isValid, isFalse, reason: bad);
        expect(r.paise, isNull, reason: bad);
        expect(r.error, isNotEmpty, reason: bad);
      }
    });

    test('too large gets its own message; the limit itself is fine', () {
      expect(_p('10,00,00,00,00,000').paise, maxPaise);
      expect(_p('10,00,00,00,00,000.01').error, contains('too large'));
      expect(_p('1e14').error, isNot(contains('too large')));
      expect(_p('99999999999999999999').error, contains('too large'));
    });

    test('"I owe" makes a card amount negative, nothing else', () {
      expect(_p('1,500', type: AccountType.card, owes: true).paise, -150000);
      expect(_p('1,500', type: AccountType.card).paise, 150000);
      expect(_p('', type: AccountType.card, owes: true).paise, 0);
      expect(_p('1,500', type: AccountType.bank, owes: true).paise, 150000);
      expect(
        _p('10,00,00,00,00,000', type: AccountType.card, owes: true).paise,
        -maxPaise,
      );
    });
  });

  group('groupRupeeText', () {
    test('adds Indian grouping to the whole part', () {
      expect(groupRupeeText('123456.5'), '1,23,456.5');
      expect(groupRupeeText('1000'), '1,000');
      expect(groupRupeeText('999'), '999');
      expect(groupRupeeText('12345678'), '1,23,45,678');
      expect(groupRupeeText('1234.'), '1,234.');
      expect(groupRupeeText('.5'), '0.5');
    });

    test('regroups text that already has commas', () {
      expect(groupRupeeText('123,456'), '1,23,456');
    });

    test('leaves non-amounts alone', () {
      expect(groupRupeeText(''), '');
      expect(groupRupeeText('abc'), 'abc');
      expect(groupRupeeText('.'), '.');
      expect(groupRupeeText('1.234'), '1.234');
    });

    test('grouped text still parses to the same paise', () {
      for (final String t in <String>['123456.5', '7', '0.05', '1000000']) {
        expect(_p(groupRupeeText(t)).paise, _p(t).paise, reason: t);
      }
    });
  });

  group('paiseToInputText', () {
    test('no sign, grouped, decimals only when needed', () {
      expect(paiseToInputText(0), '');
      expect(paiseToInputText(12345650), '1,23,456.50');
      expect(paiseToInputText(12345600), '1,23,456');
      expect(paiseToInputText(-12345600), '1,23,456');
      expect(paiseToInputText(5), '0.05');
    });

    test('round trip with the parser', () {
      for (final int paise in <int>[1, 99, 100, 12345650, maxPaise]) {
        expect(_p(paiseToInputText(paise)).paise, paise);
      }
    });
  });
}
