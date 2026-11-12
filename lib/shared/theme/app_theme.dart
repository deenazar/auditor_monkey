import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// The one app theme. Light only in Phase 1.
abstract final class AppTheme {
  static ThemeData light() {
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
    );
  }
}
