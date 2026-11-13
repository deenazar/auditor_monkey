import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';

/// Opens [sheet] as a bottom sheet over the current screen. `canvas` is the
/// scrim behind it (DESIGN.md Component rules). Completes when the sheet
/// closes.
Future<void> showAccountFormSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: AppColors.canvas,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.resolve(context, AppMotion.durationMedium),
      reverseDuration: AppMotion.resolve(context, AppMotion.durationMedium),
      curve: AppMotion.curveEnter,
      reverseCurve: AppMotion.curveExit,
    ),
    builder: (BuildContext sheetContext) => sheet,
  );
}
