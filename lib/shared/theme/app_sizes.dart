/// Design tokens: fixed component sizes and press feedback.
abstract final class AppSizes {
  /// Bottom nav bar height, without the system bottom inset.
  static const double navBarHeight = 72;

  /// Icon size in the nav bar.
  static const double iconNav = 24;

  /// Active nav indicator pill (behind the icon).
  static const double navIndicatorWidth = 56;
  static const double navIndicatorHeight = 32;

  /// Pill starts at this scale and grows to 1 when a tab becomes active.
  static const double navIndicatorStartScale = 0.8;

  /// Quick Add button diameter.
  static const double quickAddSize = 56;

  /// Scale of a pressed button.
  static const double pressScale = 0.94;
}
