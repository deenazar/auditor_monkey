import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// Wizard progress: a row of dots, one per step. The current step is a
/// wider `primaryDeep` pill; the others are small `divider` dots. Shows
/// progress only (not tappable), so it needs no 44pt tap target.
class StepDots extends StatelessWidget {
  const StepDots({required this.count, required this.current, super.key})
    : assert(count > 0, 'count must be positive'),
      assert(
        current >= 0 && current < count,
        'current must be between 0 and count - 1',
      );

  /// Number of steps.
  final int count;

  /// Zero-based index of the current step.
  final int current;

  @override
  Widget build(BuildContext context) {
    final Duration duration = AppMotion.resolve(
      context,
      AppMotion.durationFast,
    );
    final List<Widget> dots = <Widget>[];
    for (int i = 0; i < count; i++) {
      if (i > 0) dots.add(const SizedBox(width: AppSpacing.space2));
      final bool active = i == current;
      dots.add(
        AnimatedContainer(
          duration: duration,
          curve: AppMotion.curveEnter,
          width: active ? AppSizes.stepDotActiveWidth : AppSizes.stepDot,
          height: AppSizes.stepDot,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryDeep : AppColors.divider,
            borderRadius: AppRadius.pill,
          ),
        ),
      );
    }
    return Semantics(
      label: 'Step ${current + 1} of $count',
      container: true,
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: dots),
      ),
    );
  }
}
