/// Design tokens: fixed component sizes and press feedback.
abstract final class AppSizes {
  /// Bottom nav bar height, without the system bottom inset.
  static const double navBarHeight = 72;

  /// Icon size in the nav bar.
  static const double iconNav = 24;

  /// Icon size inline with text (DESIGN.md Icons: 20 inline).
  static const double iconInline = 20;

  /// Icon size inside chips (DESIGN.md Icons: 16 inside chips).
  static const double iconChip = 16;

  /// Large icon on empty and error states. Not yet in DESIGN.md.
  static const double iconLarge = 48;

  /// Progress ring size (loading button, start screen). Not yet in DESIGN.md.
  static const double progressRing = 24;

  /// Progress ring stroke width. Not yet in DESIGN.md.
  static const double progressStroke = 2;

  /// Focused and error line on text fields (DESIGN.md Component rules: 2pt).
  static const double fieldLineWidth = 2;

  /// Active nav indicator pill (behind the icon).
  static const double navIndicatorWidth = 56;
  static const double navIndicatorHeight = 32;

  /// Pill starts at this scale and grows to 1 when a tab becomes active.
  static const double navIndicatorStartScale = 0.8;

  /// Quick Add button diameter.
  static const double quickAddSize = 56;

  /// Scale of a pressed button.
  static const double pressScale = 0.94;

  /// Account carousel card height.
  static const double accountCardHeight = 200;

  /// Width of the card side-tab with the vertical account name.
  static const double accountSideTabWidth = 40;

  /// How far the next carousel card peeks in from the right.
  static const double carouselPeek = 24;

  /// Primary pill button height.
  static const double buttonHeight = 52;

  /// Text field height.
  static const double fieldHeight = 52;

  /// Leading circle in list rows.
  static const double iconCircle = 44;

  /// Colour dot in rows.
  static const double colourDot = 20;

  /// Colour swatch in the picker (sits inside a 44pt tap target).
  static const double colourSwatch = 32;

  /// Chart height inside a stat tile.
  static const double statChartHeight = 160;

  /// Wizard step dot, and the width of the active (pill) dot.
  static const double stepDot = 8;
  static const double stepDotActiveWidth = 24;
}
