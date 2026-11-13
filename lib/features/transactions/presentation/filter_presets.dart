import '../../../core/utils/date_keys.dart';
import '../domain/transaction_filter.dart';

/// The date choices of the filter sheet.
enum DatePreset {
  thisMonth('This month'),
  lastMonth('Last month'),
  last30Days('Last 30 days'),
  thisYear('This year'),
  custom('Custom');

  const DatePreset(this.label);

  final String label;
}

/// An inclusive date range as `YYYY-MM-DD` text.
typedef DateSpan = ({String from, String to});

/// The range of a preset for [today] (`YYYY-MM-DD`). `null` for
/// [DatePreset.custom], which the user picks.
DateSpan? presetRange(DatePreset preset, String today) {
  return switch (preset) {
    DatePreset.thisMonth => _month(today.substring(0, 7)),
    DatePreset.lastMonth => _month(addMonths(today.substring(0, 7), -1)),
    DatePreset.last30Days => (from: addDays(today, -29), to: today),
    DatePreset.thisYear => (
      from: '${today.substring(0, 4)}-01-01',
      to: '${today.substring(0, 4)}-12-31',
    ),
    DatePreset.custom => null,
  };
}

DateSpan _month(String month) {
  final ({String start, String end}) r = monthRange(month);
  return (from: r.start, to: r.end);
}

/// Which choice the filter's dates match, or `null` when it has no date
/// range. A range that matches no preset is [DatePreset.custom].
DatePreset? matchPreset(TransactionFilter filter, String today) {
  if (!filter.hasDateRange) return null;
  for (final DatePreset p in DatePreset.values) {
    final DateSpan? span = presetRange(p, today);
    if (span != null && span.from == filter.from && span.to == filter.to) {
      return p;
    }
  }
  return DatePreset.custom;
}
