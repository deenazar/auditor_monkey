import 'package:auditor_monkey/features/home/domain/home_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact rupees use k, lakh and crore', () {
    expect(compactRupees(0), '₹0');
    expect(compactRupees(84000), '₹840');
    expect(compactRupees(84049), '₹840');
    expect(compactRupees(120000), '₹1.2k');
    expect(compactRupees(100000), '₹1k');
    expect(compactRupees(1250000), '₹13k');
    expect(compactRupees(15000000), '₹1.5L');
    expect(compactRupees(2300000000), '₹2.3Cr');
    expect(compactRupees(-120000), '-₹1.2k');
  });

  test('day labels', () {
    expect(weekdayShort('2026-11-12'), 'Thu');
    expect(weekdayLong('2026-11-15'), 'Sunday');
    expect(dayNumber('2026-11-02'), '2');
    expect(monthYear('2026-11-12'), 'November 2026');
    expect(dayTitle('2026-11-12'), 'Thu 12 Nov');
  });
}
