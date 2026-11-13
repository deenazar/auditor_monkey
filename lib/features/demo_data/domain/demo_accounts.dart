import '../../../core/database/seed/default_categories.dart';
import '../../accounts/domain/account.dart';
import '../../setup/domain/account_presets.dart';

/// Demo opening balances in paise, by preset account name.
const Map<String, int> demoOpeningBalances = <String, int>{
  'Hand': 800000,
  'SBI': 6000000,
  'Axis': 12000000,
  'SCB': 4000000,
  'Food Card': 300000,
  'Outside': 2000000,
  'PF': 25000000,
};

/// Preset account ids by name.
final Map<String, String> demoAccountIds = <String, String>{
  for (final AccountPreset p in accountPresets) p.name: p.id,
};

/// Default category ids by name.
final Map<String, String> demoCategoryIds = <String, String>{
  for (final DefaultCategory c in defaultCategories) c.name: c.id,
};

/// All seven preset accounts with demo opening balances.
List<AccountDraft> demoAccountDrafts() => <AccountDraft>[
  for (final AccountPreset p in accountPresets)
    AccountDraft(
      name: p.name,
      type: p.type,
      colour: p.colour,
      openingBalance: demoOpeningBalances[p.name]!,
    ),
];
