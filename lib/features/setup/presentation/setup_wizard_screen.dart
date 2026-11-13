import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/wow/confetti.dart';
import '../../../shared/wow/haptics.dart';
import '../../accounts/presentation/widgets/account_form_sheet.dart';
import '../../accounts/presentation/widgets/account_form_values.dart';
import '../../accounts/presentation/widgets/show_account_form_sheet.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../application/setup_wizard_notifier.dart';
import '../application/setup_wizard_state.dart';
import '../application/wizard_mascot.dart';
import 'widgets/wizard_balances_step.dart';
import 'widgets/wizard_pick_step.dart';
import 'widgets/wizard_review_step.dart';
import 'widgets/wizard_step_transition.dart';
import 'widgets/wizard_welcome_step.dart';

/// The setup wizard (route `/setup`): welcome, pick accounts, opening
/// balances, review. Nothing is saved until "Create accounts". Android back
/// goes to the previous step; on the welcome step it leaves the app. Once
/// the accounts exist, the router sends the person to Accounts.
class SetupWizardScreen extends ConsumerWidget {
  const SetupWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SetupWizardState state = ref.watch(setupWizardProvider);
    final MascotController mascot = ref.watch(wizardMascotProvider);
    final SetupWizardNotifier notifier = ref.read(setupWizardProvider.notifier);

    return PopScope(
      canPop: state.step == WizardStep.welcome && !state.isSaving,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) notifier.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: WizardStepTransition(
            step: state.step.index,
            child: _step(context, ref, state, mascot),
          ),
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    WidgetRef ref,
    SetupWizardState state,
    MascotController mascot,
  ) {
    final SetupWizardNotifier notifier = ref.read(setupWizardProvider.notifier);
    return switch (state.step) {
      WizardStep.welcome => WizardWelcomeStep(
        onStart: () {
          notifier.next();
        },
      ),
      WizardStep.pick => WizardPickStep(
        mascot: mascot,
        accounts: state.accounts,
        selectedCount: state.selected.length,
        canContinue: state.canContinueFromPick,
        onBack: () {
          notifier.back();
        },
        onToggle: (String key) {
          AppHaptics.tap();
          final bool wasPicked = state.accounts
              .where((WizardAccount a) => a.key == key)
              .any((WizardAccount a) => a.selected);
          mascot.react(wasPicked ? MascotReaction.del : MascotReaction.add);
          notifier.toggle(key);
        },
        onEdit: (WizardAccount a) => _openSheet(context, ref, a),
        onAdd: () => _openSheet(context, ref, null),
        onContinue: () {
          notifier.next();
        },
      ),
      WizardStep.balances => WizardBalancesStep(
        mascot: mascot,
        state: state,
        onBack: () {
          notifier.back();
        },
        onAmountChanged: (String key, String text) {
          mascot.type();
          notifier.setBalanceText(key, text);
        },
        onOwesChanged: notifier.setOwes,
        onContinue: () {
          notifier.next();
        },
      ),
      WizardStep.review => WizardReviewStep(
        mascot: mascot,
        state: state,
        onBack: () {
          notifier.back();
        },
        onSave: () async {
          final bool done = await notifier.save();
          // Goal reached: the books are set up. Confetti and a success
          // haptic (the overlay outlives the route change).
          if (done && context.mounted) {
            Confetti.burst(context);
          } else if (!done) {
            AppHaptics.warning();
            mascot.react(MascotReaction.sad);
          }
        },
      ),
    };
  }

  /// Opens the add sheet (when [account] is null) or the edit sheet. Wizard
  /// accounts the user added can be removed from the edit sheet. Names are
  /// read at the moment the sheet opens.
  void _openSheet(BuildContext context, WidgetRef ref, WizardAccount? account) {
    final SetupWizardNotifier notifier = ref.read(setupWizardProvider.notifier);
    final List<String> others = ref
        .read(setupWizardProvider)
        .otherNames(account?.key)
        .toList(growable: false);
    final WizardAccount? a = account;
    showAccountFormSheet(
      context,
      AccountFormSheet(
        title: a == null ? 'Add account' : 'Edit account',
        submitLabel: a == null ? 'Add account' : 'Save',
        otherNames: others,
        initial: a == null
            ? null
            : AccountFormValues(name: a.name, type: a.type, colour: a.colour),
        onRemove: a == null || a.isPreset
            ? null
            : () => notifier.removeCustom(a.key),
        onSave: (AccountFormValues v) async {
          final String? error = a == null
              ? notifier.addCustom(name: v.name, type: v.type, colour: v.colour)
              : notifier.editAccount(
                  a.key,
                  name: v.name,
                  type: v.type,
                  colour: v.colour,
                );
          return error == null ? null : AccountFormError(error);
        },
      ),
    );
  }
}
