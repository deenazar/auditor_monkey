import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Design tokens: text styles. Names and values match DESIGN.md.
///
/// Three families, as in mini_checklist:
/// - [displayFamily] Unbounded: big numbers (date, totals) and headings.
/// - [fontFamily] DM Sans: all body text.
/// - [monoFamily] DM Mono: amounts in lists, chips and bars.
///
/// None of them has the ₹ glyph; the phone's system font draws it.
/// Amount styles use tabular figures so digits line up and do not jump.
abstract final class AppTextStyles {
  static const String displayFamily = 'Unbounded';
  static const String fontFamily = 'DM Sans';
  static const String monoFamily = 'DM Mono';

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Big amount (Unbounded 600, 34).
  static const TextStyle displayAmount = TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.05,
    letterSpacing: -1.2,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );

  /// Page title (Unbounded 600, 26).
  static const TextStyle displayTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );

  /// The home date number (Unbounded 700, 44, height .86).
  static const TextStyle dateNumber = TextStyle(
    fontFamily: displayFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 0.86,
    letterSpacing: -1.76,
    color: AppColors.glassInk,
    fontFeatures: _tabular,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );

  /// Sheet and section titles (Unbounded 600, 17).
  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// List headings (Unbounded 600, 14).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.14,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0,
    color: AppColors.inkMuted,
    fontFeatures: _tabular,
  );

  /// Use with upper-case text (DESIGN.md: all caps). DM Sans 700, 10.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.6,
    color: AppColors.inkMuted,
  );

  /// Small eyebrow above page titles (Unbounded 600, 12, caps).
  static const TextStyle pageEyebrow = TextStyle(
    fontFamily: displayFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.96,
    color: AppColors.accentText,
  );

  /// Amount in lists and chips (DM Mono 500, 15).
  static const TextStyle amount = TextStyle(
    fontFamily: monoFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.15,
    letterSpacing: 0,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );

  /// Small amount (DM Mono 500, 11.5): row meta, bar values.
  static const TextStyle amountSmall = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0,
    color: AppColors.inkMuted,
    fontFeatures: _tabular,
  );

  /// Button label (Unbounded 600, 13).
  static const TextStyle button = TextStyle(
    fontFamily: displayFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.26,
    color: AppColors.onDark,
  );

  /// Returns [base] with tabular figures (for any amount text).
  static TextStyle tabular(TextStyle base) =>
      base.copyWith(fontFeatures: _tabular);

  /// The ₹ sign: about 75% of the digit size, regular weight.
  static TextStyle rupeeSign(TextStyle amount) => amount.copyWith(
    fontSize: (amount.fontSize ?? 15) * 0.75,
    fontWeight: FontWeight.w400,
  );
}
