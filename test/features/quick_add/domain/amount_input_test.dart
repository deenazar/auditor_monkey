import 'dart:io';

import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/features/quick_add/domain/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// Types [keys] ('.' is the dot) and returns the last edit.
AmountEdit type(String keys, [AmountInput start = const AmountInput()]) {
  AmountEdit edit = AmountEdit(start);
  for (final String k in keys.split('')) {
    edit = k == '.' ? edit.input.pressDot() : edit.input.pressDigit(k);
  }
  return edit;
}

void main() {
  group('paise from typed text (exact ints)', () {
    const Map<String, int> cases = <String, int>{
      '12.3': 1230,
      '12.30': 1230,
      '0.01': 1,
      '.5': 50,
      '12.': 1200,
      '1250.5': 125050,
      '1000000000000': maxPaise,
      '1000000000000.00': maxPaise,
      '99999999999.99': 9999999999999,
    };
    cases.forEach((String keys, int paise) {
      test('"$keys" -> $paise', () {
        final AmountEdit e = type(keys);
        expect(e.refusal, isNull);
        expect(e.input.paise, paise);
      });
    });

    test('empty, zero and 0.00 are not savable', () {
      for (final String keys in <String>['', '0', '0.', '0.0', '0.00', '.0']) {
        final AmountInput input = type(keys).input;
        expect(input.paise, isNull, reason: keys);
        expect(input.isSavable, isFalse, reason: keys);
      }
    });
  });

  group('refused input never rounds', () {
    test('third decimal is refused and the buffer stays', () {
      final AmountEdit ok = type('12.34');
      final AmountEdit e = ok.input.pressDigit('5');
      expect(e.refusal, AmountRefusal.tooManyDecimals);
      expect(e.input.text, '12.34');
    });

    test('over the maximum is refused', () {
      expect(
        type('1000000000000.0').input.pressDigit('1').refusal,
        AmountRefusal.tooLarge,
      );
      expect(
        type('1000000000000').input.pressDigit('0').refusal,
        AmountRefusal.tooLarge,
      );
      expect(type('1000000000000.0').input.pressDigit('0').refusal, isNull);
    });

    test('14th integer digit is refused', () {
      final AmountInput thirteen = type('1000000000000').input;
      expect(thirteen.paise, maxPaise);
      final AmountEdit e = thirteen.pressDigit('0');
      expect(e.refusal, AmountRefusal.tooLarge);
      expect(e.input.text, '1000000000000');
    });
  });

  group('keys', () {
    test('leading zero is replaced', () {
      expect(type('05').input.text, '5');
      expect(type('00').input.text, '0');
      expect(type('0.5').input.text, '0.5');
    });

    test('dot on empty gives 0. and a second dot is ignored', () {
      expect(const AmountInput().pressDot().input.text, '0.');
      final AmountEdit twice = type('1.2').input.pressDot();
      expect(twice.input.text, '1.2');
      expect(twice.refusal, isNull);
    });

    test('backspace and clear', () {
      final AmountInput a = type('12.5').input;
      expect(a.backspace().text, '12.');
      expect(a.backspace().backspace().text, '12');
      expect(const AmountInput().backspace().text, '');
      expect(a.clear().text, '');
    });

    test('non digit keys are ignored', () {
      expect(const AmountInput('1').pressDigit('a').input.text, '1');
      expect(const AmountInput('1').pressDigit('12').input.text, '1');
    });
  });

  group('paste', () {
    const Map<String, int> good = <String, int>{
      '1,23,456.50': 12345650,
      '123,456.5': 12345650,
      '₹500': 50000,
      '007.50': 750,
      ' 250 ': 25000,
    };
    good.forEach((String clip, int paise) {
      test('"$clip" -> $paise', () {
        final AmountEdit e = const AmountInput('9').paste(clip);
        expect(e.refusal, isNull);
        expect(e.input.paise, paise);
      });
    });

    test('buffer is the plain form', () {
      expect(const AmountInput().paste('1,23,456.5').input.text, '123456.5');
      expect(const AmountInput().paste('1,23,456.50').input.text, '123456.5');
      expect(const AmountInput().paste('₹500').input.text, '500');
      expect(const AmountInput().paste('1.05').input.text, '1.05');
    });

    test('bad text is refused and the buffer stays', () {
      for (final String bad in <String>[
        '1,2,3',
        '-5',
        'abc',
        '1.234',
        '0,123',
        '',
        '1000000000000.01',
      ]) {
        final AmountEdit e = const AmountInput('42').paste(bad);
        expect(e.refusal, AmountRefusal.invalidPaste, reason: bad);
        expect(e.input.text, '42', reason: bad);
      }
      expect(
        const AmountInput('42').paste(null).refusal,
        AmountRefusal.invalidPaste,
      );
    });
  });

  group('display', () {
    test('Indian grouping, decimals as typed', () {
      expect(const AmountInput('1250.5').display, '1,250.5');
      expect(const AmountInput('12345678').display, '1,23,45,678');
      expect(const AmountInput('12.').display, '12.');
      expect(const AmountInput('0.').display, '0.');
      expect(const AmountInput('').display, '');
      expect(const AmountInput('999').display, '999');
    });
  });

  test('fromPaise round trips', () {
    for (final int paise in <int>[1, 5, 10, 99, 100, 125050, maxPaise]) {
      expect(AmountInput.fromPaise(paise).paise, paise);
    }
    expect(AmountInput.fromPaise(0).text, '');
  });

  test('no double in Quick Add domain and application code', () {
    final RegExp word = RegExp(r'\bdouble\b');
    for (final String dir in <String>[
      'lib/features/quick_add/domain',
      'lib/features/quick_add/application',
      'lib/features/quick_add/data',
    ]) {
      for (final FileSystemEntity f in Directory(dir).listSync()) {
        if (f is File && f.path.endsWith('.dart')) {
          expect(word.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
        }
      }
    }
  });

  test('Quick Add domain has no Flutter imports', () {
    for (final FileSystemEntity f in Directory(
      'lib/features/quick_add/domain',
    ).listSync()) {
      if (f is File) {
        expect(f.readAsStringSync(), isNot(contains('package:flutter')));
      }
    }
  });
}
