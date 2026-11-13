import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;
  late Account b;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A', opening: 100000);
    b = await env.account('B');
  });
  tearDown(() => env.close());

  Future<Map<String, String?>> groups() async {
    final StatementPage page = await env.transactions.statementPage(a.id);
    return <String, String?>{
      for (final StatementLine l in page.lines)
        l.entry.id: l.categoryColourGroup,
    };
  }

  test(
    'lines carry the colour group of their category; transfers null',
    () async {
      final String food = await env.seededCategoryId(
        'Food & Dining',
        'expense',
      );
      final String salary = await env.seededCategoryId('Salary', 'income');
      env.clock.advance();
      final String e = (await env.transactions.create(
        expenseDraft(accountId: a.id, categoryId: food),
      )).id;
      env.clock.advance();
      final String i = (await env.transactions.create(
        incomeDraft(accountId: a.id, categoryId: salary),
      )).id;
      env.clock.advance();
      final String t = (await env.transactions.create(
        transferDraft(from: a.id, to: b.id),
      )).id;
      expect(await groups(), <String, String?>{
        e: 'food',
        i: 'income',
        t: null,
      });
    },
  );

  test('an unknown stored group is shown as other', () async {
    final String food = await env.seededCategoryId('Food & Dining', 'expense');
    env.clock.advance();
    final String id = (await env.transactions.create(
      expenseDraft(accountId: a.id, categoryId: food),
    )).id;
    await env.rawSql('PRAGMA ignore_check_constraints = ON');
    await env.rawSql(
      "UPDATE categories SET colour_group = 'future-group' WHERE id = ?",
      <Object?>[food],
    );
    await env.rawSql('PRAGMA ignore_check_constraints = OFF');
    expect(await groups(), <String, String?>{id: 'other'});
  });
}
