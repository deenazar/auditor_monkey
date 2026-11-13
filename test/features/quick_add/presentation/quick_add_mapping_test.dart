import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/domain/category_order.dart';
import 'package:auditor_monkey/features/quick_add/domain/quick_add_validator.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_mapping.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_view_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/account_fixtures.dart';

void main() {
  test('an account without a balance yet has none (not 0.00)', () {
    final Account a = fixtureAccount(n: 1, name: 'Hand');
    final Account b = fixtureAccount(n: 2, name: 'SBI');
    final List<AccountOption> out = accountOptionsOf(
      <Account>[a, b],
      <String, int>{b.id: 0},
    );
    expect(out[0].balancePaise, isNull);
    expect(out[1].balancePaise, 0);
  });

  test('limits come from one source each', () {
    expect(quickAddChipLimit, maxSuggestedCategories);
    expect(quickAddLastDate(DateTime(2026, 11, 12)), DateTime(2026, 12, 13));
    expect(maxDaysAhead, 31);
  });
}
