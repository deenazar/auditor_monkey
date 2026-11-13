import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Design tokens: elevation. Cards and tiles are flat (elevationNone).
abstract final class AppShadows {
  /// `elevationNone`: no shadow.
  static const List<BoxShadow> elevationNone = <BoxShadow>[];

  /// `shadowFloat`: 0 4 16 rgba(30,59,49,0.12). Quick Add, sheets, menus.
  static const List<BoxShadow> shadowFloat = <BoxShadow>[
    BoxShadow(color: AppColors.shadowInk, offset: Offset(0, 4), blurRadius: 16),
  ];

  /// `shadowLayered`: three stacked shadows (contact, key, ambient) for
  /// cards that lift in the Motion & 3D layer.
  static const List<BoxShadow> shadowLayered = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowContact,
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(color: AppColors.shadowKey, offset: Offset(0, 6), blurRadius: 14),
    BoxShadow(
      color: AppColors.shadowAmbient,
      offset: Offset(0, 18),
      blurRadius: 36,
      spreadRadius: -6,
    ),
  ];

  /// `shadowLifted`: [shadowLayered] while a card is pressed / tilted.
  static const List<BoxShadow> shadowLifted = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowContact,
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: AppColors.shadowKey,
      offset: Offset(0, 12),
      blurRadius: 24,
    ),
    BoxShadow(
      color: AppColors.shadowAmbient,
      offset: Offset(0, 28),
      blurRadius: 48,
      spreadRadius: -8,
    ),
  ];
}
