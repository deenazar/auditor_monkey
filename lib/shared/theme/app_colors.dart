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

  // ---- Motion & 3D layer (DESIGN.md "Motion & 3D"); base unchanged ----

  /// Layered shadow tones: ink at 6%, 10% and 16%.
  static const Color shadowAmbient = Color(0x0F1E3B31);
  static const Color shadowKey = Color(0x1A1E3B31);
  static const Color shadowContact = Color(0x291E3B31);

  /// Hero blobs: lighter and deeper mint, lime and sun glows.
  static const Color blobMintLight = Color(0xFF9FE3CC);
  static const Color blobMintDeep = Color(0xFF4FBF9C);
  static const Color blobLime = Color(0xB3E4E782);
  static const Color blobSun = Color(0x80FDD85C);

  /// Specular sheen on tilted cards and shimmer highlight (white 35%).
  static const Color sheen = Color(0x59FFFFFF);

  /// Long-press preview backdrop (ink 35%).
  static const Color previewScrim = Color(0x591E3B31);

  /// Swipe-to-delete row background.
  static const Color swipeDelete = danger;

  /// Auditor Monkey (2.5D): deep-green fur with highlight and shade, lime
  /// face with shade, mint ears and rim light (mascot_poster palette).
  static const Color mascotFurLight = Color(0xFF6E9A8C);
  static const Color mascotFur = primaryDeep;
  static const Color mascotFurShade = Color(0xFF33554A);
  static const Color mascotFace = lime;
  static const Color mascotFaceShade = Color(0xFFCDD15F);
  static const Color mascotOutline = ink;
  static const Color mascotLens = Color(0x40FFFFFF);
  static const Color mascotTongue = Color(0xFFE07A6E);
  static const Color mascotSweat = accountOutside;

  /// Confetti, in palette order.
  static const List<Color> confetti = <Color>[
    primary,
    lime,
    sun,
    primaryDeep,
    accountHand,
    accountOutside,
  ];
}
