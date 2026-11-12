import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Design tokens: text styles (Outfit). Names and values match DESIGN.md.
///
/// Amount styles use tabular figures so digits line up and do not jump
/// when numbers change. Use [rupeeSign] for the smaller Light ₹ glyph.
abstract final class AppTextStyles {
  static const String fontFamily = 'Outfit';

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle displayAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w300,
    height: 1.1,
    letterSpacing: 0,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );

  static const TextStyle displayTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
    color: AppColors.inkMuted,
    fontFeatures: _tabular,
  );

  /// Use with upper-case text (DESIGN.md: all caps).
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 2.5,
    color: AppColors.inkMuted,
  );

  static const TextStyle pageEyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.accentText,
  );

  /// Returns [base] with tabular figures (for any amount text).
  static TextStyle tabular(TextStyle base) =>
      base.copyWith(fontFeatures: _tabular);

  /// The ₹ sign: about 75% of the digit size, Light 300.
  static TextStyle rupeeSign(TextStyle amount) => amount.copyWith(
    fontSize: (amount.fontSize ?? 15) * 0.75,
    fontWeight: FontWeight.w300,
  );
}
