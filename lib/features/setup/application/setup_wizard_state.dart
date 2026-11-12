import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_form_rules.dart';
import '../domain/opening_balance_input.dart';

/// Wizard pages, in order. `index` is the page number (0 = welcome).
enum WizardStep { welcome, pick, balances, review }

enum WizardSaveStatus { idle, saving, done, failed }

/// One account row in the wizard (preset or added by the user).
///
/// Nothing here is in the database until "Create accounts".
class WizardAccount {
  const WizardAccount({
    required this.key,
    required this.name,
    required this.type,
    required this.colour,
    this.presetId,
    this.selected = true,
    this.balanceText = '',
    this.owes = false,
  });

  /// Stable id of this row inside the wizard (the preset id for presets).
  final String key;

  /// The fixed account id for presets, `null` for accounts the user added.
  final String? presetId;
  final String name;
  final AccountType type;

  /// DESIGN.md colour token name.
  final String colour;
  final bool selected;

  /// What the user typed (rupees). Empty = 0.
  final String balanceText;

  /// "I owe" toggle. Only meaningful for card accounts.
  final bool owes;

  bool get isPreset => presetId != null;

  WizardAccount copyWith({
    String? name,
    AccountType? type,
    String? colour,
    bool? selected,
    String? balanceText,
    bool? owes,
  }) => WizardAccount(
    key: key,
    presetId: presetId,
    name: name ?? this.name,
    type: type ?? this.type,
    colour: colour ?? this.colour,
    selected: selected ?? this.selected,
    balanceText: balanceText ?? this.balanceText,
    owes: owes ?? this.owes,
  );
}

/// Everything the wizard screens show. Immutable; the notifier replaces it.
class SetupWizardState {
  const SetupWizardState({
    required this.step,
    required this.accounts,
    this.saveStatus = WizardSaveStatus.idle,
    this.saveError,
  });

  final WizardStep step;

  /// Presets first, then accounts the user added, in the order shown.
  final List<WizardAccount> accounts;
  final WizardSaveStatus saveStatus;

  /// Friendly message of the last failed save (never contains names or
  /// amounts). Cleared on the next try.
  final String? saveError;

  bool get isSaving => saveStatus == WizardSaveStatus.saving;

  /// The accounts that will be created, in list order.
  List<WizardAccount> get selected =>
      accounts.where((WizardAccount a) => a.selected).toList(growable: false);

  /// Names of every account in the list except [key].
  Iterable<String> otherNames(String? key) => accounts
      .where((WizardAccount a) => a.key != key)
      .map((WizardAccount a) => a.name);

  /// Friendly name problem of one account, or `null`.
  String? nameError(WizardAccount a) =>
      accountNameError(a.name, otherNames: otherNames(a.key));

  OpeningBalanceInput openingFor(WizardAccount a) =>
      parseOpeningBalance(a.balanceText, type: a.type, owes: a.owes);

  /// Friendly amount problem of one account, or `null`.
  String? balanceError(WizardAccount a) => openingFor(a).error;

  /// Step 1 can continue: something picked and every picked name is fine.
  bool get canContinueFromPick =>
      selected.isNotEmpty &&
      selected.every((WizardAccount a) => nameError(a) == null);

  /// Step 2 can continue: every picked amount is valid.
  bool get balancesValid =>
      selected.every((WizardAccount a) => openingFor(a).isValid);

  /// Can the final save run now.
  bool get canSave => canContinueFromPick && balancesValid && !isSaving;

  /// Sum of the picked opening balances (paise), or `null` while any amount
  /// is invalid. Integer maths only.
  int? get totalPaise {
    int total = 0;
    for (final WizardAccount a in selected) {
      final int? paise = openingFor(a).paise;
      if (paise == null) return null;
      total += paise;
    }
    return total;
  }

  SetupWizardState copyWith({
    WizardStep? step,
    List<WizardAccount>? accounts,
    WizardSaveStatus? saveStatus,
    String? saveError,
    bool clearSaveError = false,
  }) => SetupWizardState(
    step: step ?? this.step,
    accounts: accounts ?? this.accounts,
    saveStatus: saveStatus ?? this.saveStatus,
    saveError: clearSaveError ? null : saveError ?? this.saveError,
  );
}
