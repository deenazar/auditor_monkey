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
}
