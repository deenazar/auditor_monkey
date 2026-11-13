import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/validation_failure.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_form_rules.dart';
import '../domain/account_presets.dart';
import 'setup_wizard_state.dart';

const String _tag = 'wizard';

/// State of the setup wizard. Lives only in memory: nothing touches the
/// database until [save] ("Create accounts"). Leaving the wizard drops it.
class SetupWizardNotifier extends Notifier<SetupWizardState> {
  int _customCounter = 0;

  AppLogger get _log => ref.read(loggerProvider);

  @override
  SetupWizardState build() => SetupWizardState(
    step: WizardStep.welcome,
    accounts: <WizardAccount>[
      for (final AccountPreset p in accountPresets)
        WizardAccount(
          key: p.id,
          presetId: p.id,
          name: p.name,
          type: p.type,
          colour: p.colour,
        ),
    ],
  );

  // Steps.

  /// Goes to the next step when the current one allows it. Returns whether
  /// it moved.
  bool next() {
    final WizardStep? target = switch (state.step) {
      WizardStep.welcome => WizardStep.pick,
      WizardStep.pick => state.canContinueFromPick ? WizardStep.balances : null,
      WizardStep.balances => state.balancesValid ? WizardStep.review : null,
      WizardStep.review => null,
    };
    if (target == null) return false;
    _goTo(target);
    return true;
  }

  /// Goes to the previous step. Returns `false` on the welcome step (the
  /// caller then leaves the app). While saving, back is swallowed (`true`,
  /// no move).
  bool back() {
    if (state.isSaving) return true;
    if (state.step == WizardStep.welcome) return false;
    _goTo(WizardStep.values[state.step.index - 1]);
    return true;
  }

  void _goTo(WizardStep step) {
    state = state.copyWith(step: step, clearSaveError: true);
    _log.debug(_tag, 'step ${step.index}');
  }

  // Step 1: pick accounts.

  void toggle(String key) {
    if (!_has(key)) return;
    _update(key, (WizardAccount a) => a.copyWith(selected: !a.selected));
  }

  /// Adds an account the user typed (picked, random id on save). Returns a
  /// friendly message when it cannot be added, else `null`.
  String? addCustom({
    required String name,
    required AccountType type,
    required String colour,
  }) {
    final String? error = _checkDetails(null, name, colour);
    if (error != null) return error;
    _customCounter++;
    state = state.copyWith(
      accounts: <WizardAccount>[
        ...state.accounts,
        WizardAccount(
          key: 'custom-$_customCounter',
          name: name.trim(),
          type: type,
          colour: colour,
        ),
      ],
    );
    _log.debug(_tag, 'custom account added');
    return null;
  }

  /// Changes name, type and colour of a row (presets too; a preset keeps
  /// its fixed id). Returns a friendly message or `null`.
  String? editAccount(
    String key, {
    required String name,
    required AccountType type,
    required String colour,
  }) {
    if (!_has(key)) return 'This account is not in the list.';
    final String? error = _checkDetails(key, name, colour);
    if (error != null) return error;
    _update(
      key,
      (WizardAccount a) => a.copyWith(
        name: name.trim(),
        type: type,
        colour: colour,
        // "I owe" only exists for cards.
        owes: type == AccountType.card ? a.owes : false,
      ),
    );
    return null;
  }

  /// Removes an account the user added. Presets can only be unpicked.
  void removeCustom(String key) {
    final bool isCustom = state.accounts.any(
      (WizardAccount a) => a.key == key && !a.isPreset,
    );
    if (!isCustom) return;
    state = state.copyWith(
      accounts: state.accounts
          .where((WizardAccount a) => a.key != key)
          .toList(growable: false),
    );
  }

  String? _checkDetails(String? key, String name, String colour) {
    if (!accountColourTokens.contains(colour)) return 'Pick a colour.';
    return accountNameError(name, otherNames: state.otherNames(key));
  }

  // Step 2: opening balances.

  /// Sets the typed amount (rupees text). Validation shows in
  /// [SetupWizardState.balanceError].
  void setBalanceText(String key, String text) {
    if (!_has(key)) return;
    _update(key, (WizardAccount a) => a.copyWith(balanceText: text));
  }

  /// "I owe" toggle. Ignored for accounts that are not cards.
  void setOwes(String key, bool owes) {
    final bool isCard = state.accounts.any(
      (WizardAccount a) => a.key == key && a.type == AccountType.card,
    );
    if (!isCard) return;
    _update(key, (WizardAccount a) => a.copyWith(owes: owes));
  }

  // Step 3: save.

  /// Creates all picked accounts in one go. Returns `true` on success.
  ///
  /// A second call while saving (double tap) does nothing. On failure the
  /// entries stay and [SetupWizardState.saveError] explains.
  Future<bool> save() async {
    if (state.isSaving || state.saveStatus == WizardSaveStatus.done) {
      return false;
    }
    if (!state.canSave) {
      _log.warning(_tag, 'save blocked: not valid');
      return false;
    }
    final List<WizardAccount> picked = state.selected;
    final List<AccountDraft> drafts = <AccountDraft>[];
    for (final WizardAccount a in picked) {
      drafts.add(
        AccountDraft(
          name: a.name,
          type: a.type,
          colour: a.colour,
          openingBalance: state.openingFor(a).paise!,
        ),
      );
    }
    final List<String?> ids = <String?>[
      for (final WizardAccount a in picked) a.presetId,
    ];
    state = state.copyWith(
      saveStatus: WizardSaveStatus.saving,
      clearSaveError: true,
    );
    _log.info(_tag, 'save started count=${drafts.length}');
    final AccountsRepository repo = ref.read(accountsRepositoryProvider);
    try {
      await repo.createAll(drafts, fixedIds: ids);
      _log.info(_tag, 'save done');
      if (ref.mounted) {
        state = state.copyWith(saveStatus: WizardSaveStatus.done);
      }
      return true;
    } on DataFailure catch (failure) {
      _log.warning(_tag, 'save failed: ${failure.code.name}');
      if (ref.mounted) {
        state = state.copyWith(
          saveStatus: WizardSaveStatus.failed,
          saveError: failure.message,
        );
      }
      return false;
    }
  }

  // Helpers.

  bool _has(String key) =>
      state.accounts.any((WizardAccount a) => a.key == key);

  void _update(String key, WizardAccount Function(WizardAccount) change) {
    state = state.copyWith(
      accounts: <WizardAccount>[
        for (final WizardAccount a in state.accounts)
          a.key == key ? change(a) : a,
      ],
    );
  }
}

/// The setup wizard state. Dropped when the wizard screen goes away.
final NotifierProvider<SetupWizardNotifier, SetupWizardState>
setupWizardProvider =
    NotifierProvider.autoDispose<SetupWizardNotifier, SetupWizardState>(
      SetupWizardNotifier.new,
    );
