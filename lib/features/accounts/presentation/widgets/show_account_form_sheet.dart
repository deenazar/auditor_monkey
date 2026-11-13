import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/wow/wow_sheet.dart';

/// Opens [sheet] as a bottom sheet over the current screen. `canvas` is the
/// scrim behind it (DESIGN.md Component rules). Completes when the sheet
/// closes.
Future<void> showAccountFormSheet(BuildContext context, Widget sheet) {
  return showWowSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: AppColors.canvas,
    animationStyle: wowSheetAnimation(context),
    builder: (BuildContext sheetContext) => sheet,
  );
}
