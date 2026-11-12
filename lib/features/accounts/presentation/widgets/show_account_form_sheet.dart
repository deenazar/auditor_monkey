import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Opens [sheet] as a bottom sheet over the current screen. `canvas` is the
/// scrim behind it (DESIGN.md Component rules). Completes when the sheet
/// closes.
Future<void> showAccountFormSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: AppColors.canvas,
    builder: (BuildContext sheetContext) => sheet,
  );
}
