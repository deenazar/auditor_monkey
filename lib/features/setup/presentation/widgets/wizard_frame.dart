import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/step_dots.dart';

/// Layout shared by the wizard steps: an optional top row (back button and
/// progress dots, steps 1 to 3), a scrolling body and a fixed footer with
/// the main button.
class WizardFrame extends StatelessWidget {
  const WizardFrame({
    required this.body,
    required this.footer,
    this.stepIndex,
    this.onBack,
    this.padded = true,
    super.key,
  });

  /// Zero-based step among the three form steps (0 = pick). Null on the
  /// welcome step, which has no top row.
  final int? stepIndex;

  final VoidCallback? onBack;

  /// Side and top padding for [body]. Off for the full-bleed welcome hero.
  final bool padded;

  final Widget body;
  final Widget footer;

  static const int formStepCount = 3;

  @override
  Widget build(BuildContext context) {
    final int? step = stepIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (step != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    size: AppSizes.iconNav,
                    color: AppColors.ink,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: StepDots(count: formStepCount, current: step),
                  ),
                ),
                // Same width as the back button, keeps the dots centred.
                const SizedBox(width: AppSpacing.minTapTarget),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: padded
                ? const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space6,
                    AppSpacing.screenPadding,
                    AppSpacing.space6,
                  )
                : EdgeInsets.zero,
            child: body,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            AppSpacing.space6,
          ),
          child: footer,
        ),
      ],
    );
  }
}
