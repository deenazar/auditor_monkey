import 'package:auditor_monkey/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPaise', () {
    test('formats the example from the spec', () {
      expect(formatPaise(12345600), '₹1,23,456.00');
    });

    test('zero and small values', () {
      expect(formatPaise(0), '₹0.00');
      expect(formatPaise(5), '₹0.05');
      expect(formatPaise(50), '₹0.50');
      expect(formatPaise(100), '₹1.00');
      expect(formatPaise(99), '₹0.99');
    });

    test('grouping edges', () {
      expect(formatPaise(99900), '₹999.00');
      expect(formatPaise(100000), '₹1,000.00');
      expect(formatPaise(9999900), '₹99,999.00');
      expect(formatPaise(10000000), '₹1,00,000.00');
      expect(formatPaise(100000000), '₹10,00,000.00');
    });

    test('crores', () {
      expect(formatPaise(1234567890), '₹1,23,45,678.90');
      expect(formatPaise(10000000000), '₹10,00,00,000.00');
    });

    test('negatives', () {
      expect(formatPaise(-12345600), '-₹1,23,456.00');
      expect(formatPaise(-5), '-₹0.05');
      expect(formatPaise(-100), '-₹1.00');
    });

    test('very large ints and int limits do not throw', () {
      expect(formatPaise(maxPaise), '₹10,00,00,00,00,000.00');
      expect(formatPaise(9223372036854775807), '₹92,23,37,20,36,85,47,758.07');
      expect(
        formatPaise(-9223372036854775808),
        '-₹92,23,37,20,36,85,47,758.08',
      );
    });
  });

  group('parseRupeesToPaise valid', () {
    test('Indian grouped', () {
      expect(parseRupeesToPaise('1,23,456.00'), 12345600);
      expect(parseRupeesToPaise('₹1,23,456'), 12345600);
      expect(parseRupeesToPaise('1,23,45,678.90'), 1234567890);
    });

    test('western grouped', () {
      expect(parseRupeesToPaise('123,456'), 12345600);
      expect(parseRupeesToPaise('1,234,567.5'), 123456750);
    });

    test('plain numbers and decimals', () {
      expect(parseRupeesToPaise('123456.5'), 12345650);
      expect(parseRupeesToPaise('0'), 0);
      expect(parseRupeesToPaise('0.05'), 5);
      expect(parseRupeesToPaise('.5'), 50);
      expect(parseRupeesToPaise('5'), 500);
      expect(parseRupeesToPaise('007'), 700);
      expect(parseRupeesToPaise('10.1'), 1010);
    });

    test('trims spaces and allows space after the rupee sign', () {
      expect(parseRupeesToPaise('  250  '), 25000);
      expect(parseRupeesToPaise('₹ 250.75'), 25075);
    });

    test('maximum amount is accepted', () {
      expect(parseRupeesToPaise('10,00,00,00,00,000'), maxPaise);
    });
  });

  group('parseRupeesToPaise invalid returns null', () {
    const List<String> bad = <String>[
      '',
      '   ',
      '₹',
      'abc',
      '12a',
      '1e5',
      '1.234',
      '1.2.3',
      '1..2',
      '12.',
      '.',
      '-5',
      '+5',
      '₹-5',
      '1 000',
      '1,2,3',
      '12,34',
      ',100',
      '100,',
      '1,,000',
      '1,000.5,0',
      '1.000,5',
      '١٢', // Arabic-Indic digits
      'NaN',
      'Infinity',
      '10,00,00,00,00,001',
      '99999999999999999999999',
    ];
    for (final String input in bad) {
      test('"$input"', () => expect(parseRupeesToPaise(input), isNull));
    }

    test('null input', () => expect(parseRupeesToPaise(null), isNull));

    test('over-long input', () {
      expect(parseRupeesToPaise('1' * 100), isNull);
    });
  });

  test('round trip: parse(format(x)) == x for non-negative values', () {
    for (final int v in <int>[0, 1, 99, 100, 12345600, 1234567890, maxPaise]) {
      expect(parseRupeesToPaise(formatPaise(v)), v);
    }
  });
}
