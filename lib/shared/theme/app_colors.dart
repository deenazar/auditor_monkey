import 'package:flutter/painting.dart';

/// Design tokens: colors. The only file in the app that contains hex values.
/// Names and values match DESIGN.md. Change DESIGN.md first.
abstract final class AppColors {
  // Base
  static const Color background = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF5F5F5);
  static const Color tile = Color(0xFFF7F7F7);
  static const Color divider = Color(0xFFECEFEE);

  // Brand
  static const Color primary = Color(0xFF70D0B2);
  static const Color primaryLight = Color(0xFF8CD6A6);
  static const Color primaryDeep = Color(0xFF476E61);
  static const Color accentText = Color(0xFF2A8466);
  static const Color lime = Color(0xFFE4E782);
  static const Color sun = Color(0xFFFDD85C);
  static const Color notifDot = Color(0xFFDCE91D);

  // Text and icons
  static const Color ink = Color(0xFF1E3B31);
  static const Color inkMuted = Color(0xFF5F7670);
  static const Color iconInactive = Color(0xFF868E8B);
  static const Color navIndicator = Color(0xFFDDF4EC);
  static const Color onDark = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF3FA37F);
  static const Color warning = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFC2453A);

  // Accounts
  static const Color accountAxis = Color(0xFFFDD85C);
  static const Color accountSbi = Color(0xFFC2457F);
  static const Color accountScb = Color(0xFF4CB58E);
  static const Color accountHand = Color(0xFFF59E5B);
  static const Color accountFoodCard = Color(0xFFC9D86A);
  static const Color accountOutside = Color(0xFF6BB8E0);
  static const Color accountPf = Color(0xFF476E61);

  /// Chart series order: primary, lime, sun, then account colors.
  static const List<Color> chartSeries = <Color>[
    primary,
    lime,
    sun,
    accountAxis,
    accountSbi,
    accountScb,
    accountHand,
    accountFoodCard,
    accountOutside,
    accountPf,
  ];

  /// Shadow color for [AppShadows.shadowFloat]: ink at 12% opacity.
  static const Color shadowInk = Color(0x1F1E3B31);
}
