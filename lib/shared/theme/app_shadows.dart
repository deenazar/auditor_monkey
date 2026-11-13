import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Design tokens: elevation. Cards are flat with a 1px `line` border.
abstract final class AppShadows {
  /// Soft text shadow for white text on the sky (DESIGN.md: white text on the
  /// sky always has a soft shadow).
  static const List<Shadow> textOnSky = <Shadow>[
    Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// `elevationNone`: no shadow.
  static const List<BoxShadow> elevationNone = <BoxShadow>[];

  /// `shadowFloat`: 0 8 22 -8 black 40%. Bubbles, menus, toasts.
  static const List<BoxShadow> shadowFloat = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 8),
      blurRadius: 22,
      spreadRadius: -8,
    ),
  ];

  /// `shadowPanel`: 0 -10 30 -12 black 25%. The sliding panel and sheets.
  static const List<BoxShadow> shadowPanel = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowInk,
      offset: Offset(0, -10),
      blurRadius: 30,
      spreadRadius: -12,
    ),
  ];

  /// `shadowCoral`: 0 8 18 -8 coral. The coral primary button.
  static const List<BoxShadow> shadowCoral = <BoxShadow>[
    BoxShadow(
      color: AppColors.coral,
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -8,
    ),
  ];

  /// `shadowGlass`: 0 10 24 -14 black 30%. The week-bar glass.
  static const List<BoxShadow> shadowGlass = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -14,
    ),
  ];
}
