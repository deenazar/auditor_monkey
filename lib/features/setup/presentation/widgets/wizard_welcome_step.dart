import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'wizard_frame.dart';

/// Step 0 (W0): a mint hero with the wallet icon, the title and one line of
/// text, and "Get started" at the bottom.
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
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.hero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space10),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.outlineStroke,
                    ),
                  ),
                  child: const SizedBox.square(
                    dimension: AppSizes.iconCircle,
                    child: Icon(
                      LucideIcons.wallet,
                      size: AppSizes.iconInline,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
