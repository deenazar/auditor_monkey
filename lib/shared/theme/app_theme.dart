import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// The one app theme. Light only in Phase 1.
abstract final class AppTheme {
  /// The theme, built once. Some sub-themes hold `WidgetStateProperty`
  /// closures that are not equal across builds, so a fresh `ThemeData` on
  /// every rebuild would make `AnimatedTheme` animate for nothing.
  static ThemeData light() => _light;

  static final ThemeData _light = _build();

  static ThemeData _build() {
    const ColorScheme scheme = ColorScheme.light(
      primary: AppColors.primary,
      // White on primary fails contrast (1.85:1), so text on mint is ink.
      onPrimary: AppColors.ink,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      tertiary: AppColors.sun,
      onTertiary: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.onDark,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.tile,
      surfaceContainer: AppColors.tile,
      surfaceContainerHigh: AppColors.canvas,
      surfaceContainerHighest: AppColors.canvas,
    );

    const TextTheme textTheme = TextTheme(
      displayLarge: AppTextStyles.displayAmount,
      displayMedium: AppTextStyles.displayTitle,
      headlineMedium: AppTextStyles.headline,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.bodyStrong,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.bodyStrong,
      labelMedium: AppTextStyles.caption,
      labelSmall: AppTextStyles.overline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        elevation: 16,
        modalElevation: 16,
        shadowColor: AppColors.shadowInk,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: _snackBar(),
      datePickerTheme: _datePicker(),
    );
  }

  /// Toast (DESIGN.md sec. 9): `primaryDeep` fill, `onDark` text, floating
  /// above the nav bar with `space6` margin. Material's own slide is kept;
  /// the Quick Add toast wraps its content for the fade.
  static SnackBarThemeData _snackBar() => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.primaryDeep,
    contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.onDark),
    actionTextColor: AppColors.onDark,
    disabledActionTextColor: AppColors.navIndicator,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
    // Flat: the toast content draws `shadowFloat` itself.
    elevation: 0,
    insetPadding: const EdgeInsets.all(AppSpacing.space6),
    showCloseIcon: false,
  );

  /// Date picker (DESIGN.md sec. 9): `primaryDeep` selected day with
  /// `onDark` text, `ink` text elsewhere, `radiusCard` corners.
  static DatePickerThemeData _datePicker() {
    Color? onSelected(Set<WidgetState> states, Color other) =>
        states.contains(WidgetState.selected) ? AppColors.onDark : other;
    return DatePickerThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      // Flat: Material's elevation shadow is not `shadowFloat`; the scrim
      // separates the dialog from the page.
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      headerBackgroundColor: AppColors.background,
      headerForegroundColor: AppColors.ink,
      headerHeadlineStyle: AppTextStyles.title,
      headerHelpStyle: AppTextStyles.caption,
      weekdayStyle: AppTextStyles.caption.copyWith(color: AppColors.inkMuted),
      dayStyle: AppTextStyles.body,
      yearStyle: AppTextStyles.body,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) => s.contains(WidgetState.disabled)
            ? AppColors.iconInactive
            : onSelected(s, AppColors.ink),
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryDeep : null,
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) => onSelected(s, AppColors.primaryDeep),
      ),
      todayBackgroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryDeep : null,
      ),
      todayBorder: const BorderSide(color: AppColors.primaryDeep),
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) => onSelected(s, AppColors.ink),
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryDeep : null,
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        textStyle: AppTextStyles.bodyStrong,
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.inkMuted,
        textStyle: AppTextStyles.bodyStrong,
      ),
    );
  }
}
