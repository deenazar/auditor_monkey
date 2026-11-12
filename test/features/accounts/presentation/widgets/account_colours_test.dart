import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_colours.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_type_label.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pickerTests();
  final Map<String, Color> expected = <String, Color>{
    'primary': AppColors.primary,
    'lime': AppColors.lime,
    'sun': AppColors.sun,
    'accountAxis': AppColors.accountAxis,
    'accountSbi': AppColors.accountSbi,
    'accountScb': AppColors.accountScb,
    'accountHand': AppColors.accountHand,
    'accountFoodCard': AppColors.accountFoodCard,
    'accountOutside': AppColors.accountOutside,
    'accountPf': AppColors.accountPf,
  };

  test('all 10 colour tokens map to their DESIGN.md colour', () {
    expect(expected.length, accountColourTokens.length);
    for (final String token in accountColourTokens) {
      expect(accountColourFor(token), expected[token], reason: token);
      expect(accountColourName(token), isNot('Colour'), reason: token);
    }
  });

  test('SBI and PF text is onDark, the rest is ink', () {
    expect(accountTextColourFor('accountSbi'), AppColors.onDark);
    expect(accountTextColourFor('accountPf'), AppColors.onDark);
    for (final String token in accountColourTokens) {
      if (token == 'accountSbi' || token == 'accountPf') continue;
      expect(accountTextColourFor(token), AppColors.ink, reason: token);
    }
  });

  test('unknown token falls back to mint with ink text, no throw', () {
    expect(accountColourFor('accountNope'), AppColors.primary);
    expect(accountTextColourFor('accountNope'), AppColors.ink);
    expect(accountColourName('accountNope'), 'Colour');
  });

  test('every account type has a label', () {
    final Map<AccountType, String> labels = <AccountType, String>{
      for (final AccountType t in AccountType.values) t: accountTypeLabel(t),
    };
    expect(labels, <AccountType, String>{
      AccountType.cash: 'Cash',
      AccountType.bank: 'Bank',
      AccountType.card: 'Card',
      AccountType.wallet: 'Wallet',
      AccountType.pf: 'PF',
      AccountType.other: 'Other',
    });
  });
}

void pickerTests() {
  test('the picker offers every colour except sun (same yellow as Axis)', () {
    expect(
      pickerAccountColours.toSet(),
      accountColourTokens.difference(<String>{'sun'}),
    );
    expect(pickerAccountColours, hasLength(9));
    // sun still resolves for values stored before it left the picker.
    expect(accountColourFor('sun'), AppColors.sun);
  });
}
