import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_illustration.dart';
import '../../../../shared/wow/depth_pop_in.dart';
import '../../../../shared/wow/tilt_3d.dart';

/// "Savings goal reached" on Home: a `tile` card with the success
/// illustration, shown while this month's savings are at or above the
/// goal. Pops in with depth and tilts under the finger.
class GoalBanner extends StatelessWidget {
  const GoalBanner({required this.percent, required this.goal, super.key});

  final int percent;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Savings goal reached: $percent percent saved this month',
      excludeSemantics: true,
      child: DepthPopIn(
        child: Tilt3D(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.tile,
              borderRadius: AppRadius.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Row(
                children: <Widget>[
                  SvgPicture.asset(
                    AppIllustration.assetPath('success_goal'),
                    width: 72,
                    height: 60,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Savings goal reached',
                          style: AppTextStyles.bodyStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$percent% of this month\'s income saved '
                          '(goal $goal%).',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
