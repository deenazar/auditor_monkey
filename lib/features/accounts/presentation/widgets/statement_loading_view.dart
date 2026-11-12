import 'package:flutter/material.dart';

import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton_block.dart';

/// Static skeleton of a statement while it loads: a title line, the balance
/// card, the chart tile and five row blocks. No animation.
class StatementLoadingView extends StatelessWidget {
  const StatementLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: SkeletonBlock(height: 32, width: 180)),
          const SizedBox(height: AppSpacing.space6),
          const SkeletonBlock(height: 120),
          const SizedBox(height: AppSpacing.space5),
          const SkeletonBlock(height: AppSizes.statChartHeight),
          const SizedBox(height: AppSpacing.sectionGap),
          for (int i = 0; i < 5; i++) ...<Widget>[
            const SkeletonBlock(height: AppSizes.iconCircle),
            const SizedBox(height: AppSpacing.listRowGap),
          ],
        ],
      ),
    );
  }
}
