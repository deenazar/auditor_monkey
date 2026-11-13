import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../application/setup_wizard_state.dart';
import 'wizard_balance_row.dart';
import 'wizard_frame.dart';
import 'wizard_scene.dart';

/// Step 2 (W2): today's balance of each picked account. Empty means 0.
/// Continue needs every amount valid.
class WizardBalancesStep extends StatelessWidget {
  const WizardBalancesStep({
    this.mascot,
    required this.state,
    required this.onBack,
    required this.onAmountChanged,
    required this.onOwesChanged,
    required this.onContinue,
    super.key,
  });

  final SetupWizardState state;
  final VoidCallback onBack;

  /// (account key, typed text).
  final void Function(String key, String text) onAmountChanged;

  /// (account key, owes).
  final void Function(String key, bool owes) onOwesChanged;

  final VoidCallback onContinue;

  /// The wizard's Auditor Monkey (perks up while you type).
  final MascotController? mascot;

  @override
  Widget build(BuildContext context) {
    final List<WizardAccount> picked = state.selected;
    return WizardFrame(
      stepIndex: 1,
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
                  illustration: 'wizard_balances',
                  say: "Today's balances, please",
                  mascot: mascot,
                ),
                const SizedBox(height: AppSpacing.space3),
                const PageHeader(
                  eyebrow: 'Step 2 of 3',
                  title: 'Opening balances',
                ),
                const SizedBox(height: AppSpacing.space3),
                const Text(
                  'Your balance today. Leave empty for ₹0.00.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
          for (int i = 0; i < picked.length; i++) ...<Widget>[
            StaggeredEntrance(
              index: i + 1,
              child: WizardBalanceRow(
                account: picked[i],
                error: state.balanceError(picked[i]),
                onChanged: (String text) =>
                    onAmountChanged(picked[i].key, text),
                onOwesChanged: (bool owes) =>
                    onOwesChanged(picked[i].key, owes),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
          ],
        ],
      ),
      footer: PrimaryButton(
        label: 'Continue',
        onPressed: state.balancesValid ? onContinue : null,
      ),
    );
  }
}
