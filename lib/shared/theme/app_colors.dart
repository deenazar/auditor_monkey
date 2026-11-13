import 'package:flutter/painting.dart';

/// Design tokens: colors. The only file in the app (with sky_palette.dart)
/// that contains hex values. Names and values match DESIGN.md, which ports
/// mini_checklist's `web/styles.css` tokens. Change DESIGN.md first.
abstract final class AppColors {
  // ---- mini_checklist tokens (styles.css :root) ----
  /// `--panel`: page and sliding-panel background.
  static const Color panel = Color(0xFFF5F8F7);

  /// `--card`: cards, tiles and inputs.
  static const Color card = Color(0xFFFFFFFF);

  /// `--line`: 1px card borders and dividers.
  static const Color line = Color(0xFFDFE7E5);

  /// `--fill`: quiet fills (secondary buttons, tracks, chips).
  static const Color fill = Color(0xFFEBF1EF);

  /// `--coral`: the accent (primary buttons, today, Quick Add).
  static const Color coral = Color(0xFFFF6B4A);

  /// `--teal`: focus rings and progress start.
  static const Color teal = Color(0xFF0E9F9A);

  /// `--glass`: dark glass over the sky.
  static const Color glass = Color(0x5708101E);

  /// `--glass-ink`: text and icons on glass.
  static const Color glassInk = Color(0xFFFFFFFF);

  /// Inner 1px border of glass (white 16%).
  static const Color glassEdge = Color(0x29FFFFFF);

  /// Week-bar glass on the sky (white 26%) and its inner border (white 34%).
  static const Color glassLight = Color(0x42FFFFFF);
  static const Color glassLightEdge = Color(0x57FFFFFF);

  /// Bar track on the sky (white 30%).
  static const Color glassTrack = Color(0x4DFFFFFF);

  /// Today's bar gradient (top, bottom) and its dot.
  static const Color todayBarTop = Color(0xFFFFD86E);
  static const Color todayBarBottom = Color(0xFFFF7E57);
  static const Color todayDot = Color(0xFFFFB35C);

  /// Other bars (top, bottom).
  static const Color barTop = Color(0xFFFFFFFF);
  static const Color barBottom = Color(0xFFE7F0FF);

  /// Violet (category "family"; mimi-world.js burst colour).
  static const Color violet = Color(0xFF8E7BEF);

  /// Modal scrim: rgba(5,10,20,.4).
  static const Color scrim = Color(0x66050A14);

  // ---- Names used across the app (mapped onto the tokens above) ----
  static const Color background = panel;
  static const Color canvas = fill;
  static const Color tile = card;
  static const Color divider = line;

  // Brand
  static const Color primary = coral;
  static const Color primaryLight = Color(0xFFFFE3DB);
  static const Color primaryDeep = ink;

  /// Coral darkened for small text on light surfaces (4.5:1 on panel).
  static const Color accentText = Color(0xFFC2410C);
  static const Color lime = Color(0xFF5DB82E);
  static const Color sun = Color(0xFFF5A400);
  static const Color notifDot = coral;

  // Text and icons
  /// `--ink`.
  static const Color ink = Color(0xFF10202A);

  /// `--sec`.
  static const Color inkMuted = Color(0xFF5E6E76);
  static const Color iconInactive = Color(0xFF8A979D);

  /// Selected nav / chip background: coral at 14% on panel.
  static const Color navIndicator = Color(0xFFFFE3DB);
  static const Color onDark = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF33801A);
  static const Color warning = sun;

  /// `--red`.
  static const Color danger = Color(0xFFE5484D);

  // Accounts (stored per account; unchanged so saved colours still match)
  static const Color accountAxis = Color(0xFFFDD85C);
  static const Color accountSbi = Color(0xFFC2457F);
  static const Color accountScb = Color(0xFF4CB58E);
  static const Color accountHand = Color(0xFFF59E5B);
  static const Color accountFoodCard = Color(0xFFC9D86A);
  static const Color accountOutside = Color(0xFF6BB8E0);
  static const Color accountPf = Color(0xFF476E61);

  /// Chart series order: coral, teal, lime, sun, then account colors.
  static const List<Color> chartSeries = <Color>[
    coral,
    teal,
    lime,
    sun,
    accountSbi,
    accountScb,
    accountHand,
    accountFoodCard,
    accountOutside,
    accountPf,
  ];

  /// Celebration burst colours (mimi-world.js COLORS).
  static const List<Color> burst = <Color>[
    Color(0xFFFF6B4A),
    Color(0xFF2CC4BE),
    Color(0xFFFFC24D),
    Color(0xFF8ED85A),
    Color(0xFFB59CFF),
  ];

  /// Shadow colour for cards and sheets: black 25%.
  static const Color shadowInk = Color(0x40000000);
}
