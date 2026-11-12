import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidDate', () {
    test('accepts real calendar dates', () {
      for (final String d in <String>[
        '2026-11-12',
        '2024-02-29',
        '2000-02-29',
        '2026-01-31',
        '2026-12-31',
        '1900-01-01',
        '2100-12-31',
      ]) {
        expect(isValidDate(d), isTrue, reason: d);
      }
    });

    test('rejects everything else', () {
      for (final String? d in <String?>[
        null,
        '',
        '2026-02-29',
        '1900-02-29',
        '2026-04-31',
        '2026-00-10',
        '2026-10-00',
        '2026-13-01',
        '2026-1-01',
        '2026-01-1',
        ' 2026-01-01',
        '2026-01-01 ',
        '2026-01-01T00:00:00',
        '20260101',
        '2026/01/01',
        '١٤٤٧-٠١-٠١',
        '1899-12-31',
        '2101-01-01',
      ]) {
        expect(isValidDate(d), isFalse, reason: '$d');
      }
    });
  });

  group('isValidMonth', () {
    test('accepts YYYY-MM only', () {
      expect(isValidMonth('2026-11'), isTrue);
      expect(isValidMonth('2026-12'), isTrue);
      for (final String? m in <String?>[
        null,
        '',
        '2026-00',
        '2026-13',
        '2026-1',
        '2026-11-01',
        '26-11',
      ]) {
        expect(isValidMonth(m), isFalse, reason: '$m');
      }
    });
  });

  group('validateName', () {
    test('trims and returns the text', () {
      expect(validateName('name', '  Hi  ', max: 5), 'Hi');
    });

    test('rejects empty, too long and control characters', () {
      expect(
        () => validateName('name', null, max: 5),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => validateName('name', '   ', max: 5),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => validateName('name', '123456', max: 5),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => validateName('name', 'a\nb', max: 5),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('keeps emoji and non-English text', () {
      expect(validateName('name', 'चाय ☕', max: 10), 'चाय ☕');
    });

    test('script-like text is stored as plain text, not rejected', () {
      // Values are always sent as SQL parameters, never joined into SQL.
      expect(
        validateName('name', "Robert'); DROP TABLE accounts;--", max: 60),
        "Robert'); DROP TABLE accounts;--",
      );
    });
  });

  group('validateOptionalText', () {
    test('empty becomes null, newline allowed, NUL rejected', () {
      expect(validateOptionalText('note', '  ', max: 5), isNull);
      expect(validateOptionalText('note', null, max: 5), isNull);
      expect(validateOptionalText('note', 'a\nb', max: 5), 'a\nb');
      expect(
        () => validateOptionalText('note', 'a\u0000', max: 5),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => validateOptionalText('note', '123456', max: 5),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('validatePaise and validateIntRange', () {
    test('paise bounds', () {
      validatePaise('amount', 1);
      validatePaise('amount', maxPaise);
      validatePaise('amount', 0, min: 0);
      for (final int bad in <int>[0, -1, maxPaise + 1]) {
        expect(
          () => validatePaise('amount', bad),
          throwsA(isA<ValidationFailure>()),
        );
      }
    });

    test('int range bounds', () {
      validateIntRange('w', 1, min: 1, max: 3);
      validateIntRange('w', 3, min: 1, max: 3);
      expect(
        () => validateIntRange('w', 4, min: 1, max: 3),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => validateIntRange('w', 0, min: 1, max: 3),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
