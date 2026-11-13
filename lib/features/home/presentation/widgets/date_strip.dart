import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass.dart';
import '../../domain/home_format.dart';
import '../../domain/home_summary.dart';

/// mini_checklist `.days`: nine day chips. Today's number is coral; the
/// picked day is an ink chip; a dot marks days with spending (sun) and
/// days over the daily average (red).
class DateStrip extends StatelessWidget {
  const DateStrip({
    required this.days,
    required this.today,
    required this.selected,
    required this.onPick,
    super.key,
  });

  final List<DaySpend> days;
  final String today;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final int spendDays = days.where((DaySpend d) => d.spent > 0).length;
    final int average = spendDays == 0
        ? 0
        : days.fold<int>(0, (int s, DaySpend d) => s + d.spent) ~/ spendDays;
    return Semantics(
      container: true,
      label: 'Pick a day',
      child: Row(
        children: <Widget>[
          for (int i = 0; i < days.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 3),
            Expanded(child: _chip(context, days[i], average)),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, DaySpend day, int average) {
    final bool isSel = day.date == selected;
    final bool isToday = day.date == today;
    final Color dot = day.spent == 0
        ? const Color(0x00000000)
        : day.spent > average * 1.5
        ? AppColors.danger
        : AppColors.sun;
    return PressScale(
      selected: isSel,
      semanticLabel:
          '${weekdayLong(day.date)} ${dayNumber(day.date)}'
          '${isToday ? ', today' : ''}: '
          '${day.spent == 0 ? 'nothing spent' : formatPaise(day.spent)}',
      onTap: () => onPick(day.date),
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.durationPress),
          curve: AppMotion.curveEnter,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 7),
          decoration: BoxDecoration(
            color: isSel ? AppColors.ink : const Color(0x00000000),
            borderRadius: AppRadius.field,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                weekdayShort(day.date).toUpperCase(),
                maxLines: 1,
                style: AppTextStyles.overline.copyWith(
                  fontSize: 9.5,
                  color: isSel ? AppColors.panel : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dayNumber(day.date),
                  maxLines: 1,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 15,
                    height: 1.1,
                    color: isSel
                        ? AppColors.panel
                        : isToday
                        ? AppColors.coral
                        : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
