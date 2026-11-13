import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/core/utils/date_keys.dart';
import 'package:auditor_monkey/core/utils/today_provider.dart';
import 'package:auditor_monkey/core/utils/validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  test('dateKey and monthKeyOf pad to fixed width', () {
    expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(monthKeyOf(DateTime(2026, 11, 30)), '2026-11');
  });

  test('addMonths crosses year edges both ways', () {
    expect(addMonths('2026-11', 1), '2026-12');
    expect(addMonths('2026-12', 1), '2027-01');
    expect(addMonths('2026-01', -1), '2025-12');
    expect(addMonths('2026-11', -5), '2026-06');
    expect(addMonths('2026-03', -14), '2025-01');
    expect(addMonths('2026-11', 0), '2026-11');
  });

  test('monthsBetween lists every month, oldest first', () {
    expect(monthsBetween('2025-11', '2026-02'), <String>[
      '2025-11',
      '2025-12',
      '2026-01',
      '2026-02',
    ]);
    expect(monthsBetween('2026-11', '2026-11'), <String>['2026-11']);
    expect(monthsBetween('2026-11', '2026-10'), isEmpty);
  });

  test('shortMonthName', () {
    expect(shortMonthName('2026-01'), 'Jan');
    expect(shortMonthName('2026-12'), 'Dec');
  });

  test('isUuidShape accepts UUIDs and refuses everything else', () {
    expect(isUuidShape('118ca4e7-af5f-414a-9332-19254608cd87'), isTrue);
    expect(isUuidShape('118CA4E7-AF5F-414A-9332-19254608CD87'), isTrue);
    for (final String? bad in <String?>[
      null,
      '',
      'abc',
      '118ca4e7af5f414a933219254608cd87',
      '118ca4e7-af5f-414a-9332-19254608cd8',
      '118ca4e7-af5f-414a-9332-19254608cd87 ',
      "118ca4e7-af5f-414a-9332-19254608cd8'",
      '../../etc/passwd',
    ]) {
      expect(isUuidShape(bad), isFalse, reason: '$bad');
    }
  });

  test('todayProvider is the local date of the clock', () {
    final FakeClock clock = FakeClock(
      DateTime(2026, 11, 12, 12).millisecondsSinceEpoch,
    );
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[clockProvider.overrideWithValue(clock)],
    );
    addTearDown(c.dispose);
    expect(c.read(todayProvider), '2026-11-12');
    expect(c.read(currentMonthProvider), '2026-11');
  });
}
