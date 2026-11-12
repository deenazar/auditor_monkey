import 'package:auditor_monkey/core/utils/validators.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the 7 preset ids, names, types and colours never change', () {
    // If this test fails, DO NOT edit the expected values to match: the ids
    // are used by sync and must stay the same on every phone.
    final List<(String, String, AccountType, String)> actual = accountPresets
        .map((AccountPreset p) => (p.id, p.name, p.type, p.colour))
        .toList();
    expect(actual, const <(String, String, AccountType, String)>[
      (
        '118ca4e7-af5f-414a-9332-19254608cd87',
        'Hand',
        AccountType.cash,
        'accountHand',
      ),
      (
        '14965b59-7d32-46f1-995e-56999a15cb2d',
        'SBI',
        AccountType.bank,
        'accountSbi',
      ),
      (
        '985d51e8-1750-4514-a6c3-1a41705d301f',
        'Axis',
        AccountType.bank,
        'accountAxis',
      ),
      (
        '1bae59f9-27cf-405d-97e2-bee240a49d48',
        'SCB',
        AccountType.bank,
        'accountScb',
      ),
      (
        '99520539-5137-4493-b75a-6318e74d77c6',
        'Food Card',
        AccountType.wallet,
        'accountFoodCard',
      ),
      (
        '790e6963-46f7-4987-be74-1e02ca76c4c1',
        'Outside',
        AccountType.other,
        'accountOutside',
      ),
      (
        '7dc19b4c-74fb-4587-84ba-8356cfc6f9f0',
        'PF',
        AccountType.pf,
        'accountPf',
      ),
    ]);
  });

  test('ids are unique UUID v4 values and colours are valid tokens', () {
    final RegExp v4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(accountPresets.map((AccountPreset p) => p.id).toSet(), hasLength(7));
    for (final AccountPreset p in accountPresets) {
      expect(v4.hasMatch(p.id), isTrue, reason: p.name);
      expect(isUuidShape(p.id), isTrue);
      expect(accountColourTokens, contains(p.colour));
    }
  });
}
