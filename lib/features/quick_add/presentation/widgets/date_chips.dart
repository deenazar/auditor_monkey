import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/date_keys.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import 'choice_pill.dart';

/// Date row: "Today", "Yesterday" and a calendar pill.
///
/// The calendar pill shows the picked date (for example "3 Nov") when it is
/// neither today nor yesterday. Tapping it opens the Material date picker
/// between [firstDate] and [lastDate]. Dates are day-only (no time).
class DateChips extends StatelessWidget {
  const DateChips({
    required this.selected,
    required this.today,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    super.key,
  });

  final DateTime selected;

  /// The current day (from the clock, never `DateTime.now()` in tests).
  final DateTime today;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// `3 Nov` for a day.
  static String shortLabel(DateTime d) =>
      '${d.day} ${shortMonthName(dateKey(d))}';

  @override
  Widget build(BuildContext context) {
    final DateTime todayDay = dayOnly(today);
    final DateTime yesterday = DateTime(
      todayDay.year,
      todayDay.month,
      todayDay.day - 1,
    );
    final DateTime chosen = dayOnly(selected);
    final bool isToday = sameDay(chosen, todayDay);
    final bool isYesterday = sameDay(chosen, yesterday);
    final bool isOther = !isToday && !isYesterday;

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: <Widget>[
        ChoicePill(
          selected: isToday,
          onTap: () => onChanged(todayDay),
          child: const Text('Today'),
        ),
        ChoicePill(
          selected: isYesterday,
          onTap: () => onChanged(yesterday),
          child: const Text('Yesterday'),
        ),
        ChoicePill(
          selected: isOther,
          semanticsLabel: isOther
              ? 'Pick another date, now ${shortLabel(chosen)}'
              : 'Pick another date',
          onTap: () => _pick(context, chosen),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                LucideIcons.calendar,
                size: AppSizes.iconChip,
                color: isOther ? AppColors.onDark : AppColors.ink,
              ),
              if (isOther) ...<Widget>[
                const SizedBox(width: AppSpacing.space2),
                Text(shortLabel(chosen)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, DateTime chosen) async {
    final DateTime first = dayOnly(firstDate);
    final DateTime last = dayOnly(lastDate);
    final DateTime initial = chosen.isBefore(first)
        ? first
        : chosen.isAfter(last)
        ? last
        : chosen;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(dayOnly(picked));
  }
}
