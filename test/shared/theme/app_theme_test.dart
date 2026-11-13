import 'package:auditor_monkey/core/utils/date_keys.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_radius.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ThemeData theme = AppTheme.light();

  test('toast style: primaryDeep, onDark text, floating, radiusCard', () {
    final SnackBarThemeData s = theme.snackBarTheme;
    expect(s.backgroundColor, AppColors.primaryDeep);
    expect(s.contentTextStyle!.color, AppColors.onDark);
    expect(s.actionTextColor, AppColors.onDark);
    expect(s.behavior, SnackBarBehavior.floating);
    expect((s.shape! as RoundedRectangleBorder).borderRadius, AppRadius.card);
  });

  test('date picker: primaryDeep selected day with onDark, ink text', () {
    final DatePickerThemeData d = theme.datePickerTheme;
    final Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
    expect(d.dayBackgroundColor!.resolve(selected), AppColors.primaryDeep);
    expect(d.dayForegroundColor!.resolve(selected), AppColors.onDark);
    expect(d.dayForegroundColor!.resolve(<WidgetState>{}), AppColors.ink);
    expect((d.shape! as RoundedRectangleBorder).borderRadius, AppRadius.card);
  });

  test('addDays moves across months, years and leap days', () {
    expect(addDays('2026-11-12', 31), '2026-12-13');
    expect(addDays('2026-11-12', -90), '2026-08-14');
    expect(addDays('2027-12-31', 1), '2028-01-01');
    expect(addDays('2028-02-28', 1), '2028-02-29');
    expect(addDays('2026-03-01', -1), '2026-02-28');
  });
}
