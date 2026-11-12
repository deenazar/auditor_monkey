import 'package:auditor_monkey/features/accounts/domain/account_form_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a normal name is fine', () {
    expect(accountNameError('SBI'), isNull);
    expect(accountNameError('  Food Card  '), isNull);
    expect(accountNameError('A' * 40), isNull);
  });

  test('empty, spaces only, too long and control characters', () {
    expect(accountNameError(''), isNotNull);
    expect(accountNameError('   '), isNotNull);
    expect(accountNameError('A' * 41), contains('40'));
    expect(accountNameError('Bad\u0000name'), isNotNull);
    expect(accountNameError('two\nlines'), isNotNull);
  });

  test('same name as another account, ignoring case and spaces', () {
    expect(
      accountNameError(' sbi ', otherNames: const <String>['Axis', 'SBI']),
      isNotNull,
    );
    expect(accountNameError('SBI', otherNames: const <String>['Axis']), isNull);
  });
}
