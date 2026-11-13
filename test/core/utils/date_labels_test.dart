import 'package:auditor_monkey/core/utils/date_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortDateLabel', () {
    test('same year: day and short month only', () {
      expect(shortDateLabel('2026-11-12', todayKey: '2026-11-12'), '12 Nov');
      expect(shortDateLabel('2026-01-05', todayKey: '2026-11-12'), '5 Jan');
    });

    test('other year: the year is added', () {
      expect(
        shortDateLabel('2025-12-30', todayKey: '2026-11-12'),
        '30 Dec 2025',
      );
    });

    test('leap day and month ends', () {
      expect(shortDateLabel('2028-02-29', todayKey: '2028-03-01'), '29 Feb');
      expect(shortDateLabel('2026-04-30', todayKey: '2026-11-12'), '30 Apr');
    });

    test('a malformed date is returned as it is', () {
      expect(
        shortDateLabel('12/11/2026', todayKey: '2026-11-12'),
        '12/11/2026',
      );
      expect(shortDateLabel('', todayKey: '2026-11-12'), '');
    });
  });
}
