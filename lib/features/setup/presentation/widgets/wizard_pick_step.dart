import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../../shared/wow/tilt_3d.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../application/setup_wizard_state.dart';
import 'account_pick_tile.dart';
import 'wizard_frame.dart';
import 'wizard_scene.dart';

/// Step 1 (W1): the account list. Presets start selected; the pencil edits
/// a row, "Add another account" adds one. Continue needs at least one
/// account picked.
class WizardPickStep extends StatelessWidget {
  const WizardPickStep({
    this.mascot,
    required this.accounts,
    required this.selectedCount,
    required this.canContinue,
    required this.onBack,
    required this.onToggle,
    required this.onEdit,
    required this.onAdd,
    required this.onContinue,
    super.key,
  });

  final List<WizardAccount> accounts;
  final int selectedCount;
  final bool canContinue;
  final VoidCallback onBack;
  final ValueChanged<String> onToggle;
  final ValueChanged<WizardAccount> onEdit;
  final VoidCallback onAdd;
  final VoidCallback onContinue;

  /// The wizard's Auditor Monkey (reacts to picks).
  final MascotController? mascot;

  @override
  Widget build(BuildContext context) {
    return WizardFrame(
      stepIndex: 0,
      onBack: onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaggeredEntrance(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                WizardScene(
                  illustration: 'wizard_pick',
                  say: 'Pick the ones you use',
                  mascot: mascot,
                ),
                const SizedBox(height: AppSpacing.space3),
                const PageHeader(
                  eyebrow: 'Step 1 of 3',
                  title: 'Your accounts',
                ),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
          for (int i = 0; i < accounts.length; i++) ...<Widget>[
            StaggeredEntrance(
              index: i + 1,
              child: Tilt3D(
                maxDegrees: 5,
                child: AccountPickTile(
                  account: accounts[i],
                  onToggle: () => onToggle(accounts[i].key),
                  onEdit: () => onEdit(accounts[i]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          const SizedBox(height: AppSpacing.space2),
          Semantics(
            label: 'Add another account',
            button: true,
            onTap: onAdd,
            excludeSemantics: true,
            child: SpringPress(
              onTap: onAdd,
              child: SizedBox(
                height: AppSpacing.minTapTarget,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.plus,
                      size: AppSizes.iconInline,
                      color: AppColors.accentText,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Add another account',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.accentText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (selectedCount == 0) ...<Widget>[
            const Text(
              'Pick at least one account to continue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          PrimaryButton(
            label: 'Continue',
            onPressed: canContinue ? onContinue : null,
          ),
        ],
      ),
    );
  }
}
