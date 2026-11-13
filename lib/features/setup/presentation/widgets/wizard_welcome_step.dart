import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'wizard_frame.dart';
import 'wizard_sky_hero.dart';

/// Step 0 (W0): the sky hero with the Auditor Monkey waving, the title and
/// one line of text, and "Get started" at the bottom.
class WizardWelcomeStep extends StatelessWidget {
  const WizardWelcomeStep({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return WizardFrame(
      padded: false,
      footer: PrimaryButton(label: 'Get started', onPressed: onStart),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const WizardSkyHero(),
          const SizedBox(height: AppSpacing.space8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  'Set up your accounts',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayTitle,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Add the accounts you use, with today\'s balance.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
