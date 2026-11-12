import 'package:flutter/material.dart';

import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/placeholder_view.dart';

/// Empty placeholder for the Quick Add sheet (built in a later session).
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  /// Opens the sheet: [AppMotion.durationMedium], [AppMotion.curveEnter].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppMotion.durationMedium),
        reverseDuration: AppMotion.resolve(context, AppMotion.durationMedium),
        curve: AppMotion.curveEnter,
        reverseCurve: AppMotion.curveExit,
      ),
      builder: (BuildContext context) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: const Padding(
        padding: EdgeInsets.only(top: AppSpacing.space2),
        child: PlaceholderView(
          eyebrow: 'New entry',
          title: 'Quick Add',
          message: 'Expense, income and transfer will go here.',
        ),
      ),
    );
  }
}
