/// The 7 accounts offered by the setup wizard.
///
/// The ids are FIXED on purpose (hard-coded UUID v4 values). NEVER change or
/// regenerate them: if the wizard runs again on a new phone before sign-in,
/// the same ids let sync merge these accounts with the cloud copies instead
/// of creating a second "SBI". A test pins every value. Custom accounts
/// added by the user get random ids.
library;

import '../../accounts/domain/account.dart';

/// One preset account.
class AccountPreset {
  const AccountPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.colour,
  });

  final String id;
  final String name;
  final AccountType type;

  /// DESIGN.md colour token name.
  final String colour;
}

/// Presets in wizard order (the list order is the `sort_order` value).
const List<AccountPreset> accountPresets = <AccountPreset>[
  AccountPreset(
    id: '118ca4e7-af5f-414a-9332-19254608cd87',
    name: 'Hand',
    type: AccountType.cash,
    colour: 'accountHand',
  ),
  AccountPreset(
    id: '14965b59-7d32-46f1-995e-56999a15cb2d',
    name: 'SBI',
    type: AccountType.bank,
    colour: 'accountSbi',
  ),
  AccountPreset(
    id: '985d51e8-1750-4514-a6c3-1a41705d301f',
    name: 'Axis',
    type: AccountType.bank,
    colour: 'accountAxis',
  ),
  AccountPreset(
    id: '1bae59f9-27cf-405d-97e2-bee240a49d48',
    name: 'SCB',
    type: AccountType.bank,
    colour: 'accountScb',
  ),
  AccountPreset(
    id: '99520539-5137-4493-b75a-6318e74d77c6',
    name: 'Food Card',
    type: AccountType.wallet,
    colour: 'accountFoodCard',
  ),
  AccountPreset(
    id: '790e6963-46f7-4987-be74-1e02ca76c4c1',
    name: 'Outside',
    type: AccountType.other,
    colour: 'accountOutside',
  ),
  AccountPreset(
    id: '7dc19b4c-74fb-4587-84ba-8356cfc6f9f0',
    name: 'PF',
    type: AccountType.pf,
    colour: 'accountPf',
  ),
];
