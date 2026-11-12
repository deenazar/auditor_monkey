import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_undo.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures.dart';
import '../../../support/quick_add_env.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late QuickAddHarness h;

  setUp(() async {
    env = quickAddTestEnv();
    await threeAccounts(env);
    h = QuickAddHarness(env);
    await h.loaded();
  });
  tearDown(() async {
    h.dispose();
    await env.close();
  });

  void expectClean() {
    final String text = env.sink.allText;
    for (final String secret in <String>[
      '250',
      '25000',
      '1200',
      '120050',
      '2000',
      '200000',
      'secret note',
      'Hand',
      'SBI',
      'Axis',
      'Groceries',
      'Salary',
      day,
      '2026-11',
    ]) {
      expect(text, isNot(contains(secret)), reason: 'log has "$secret"');
    }
  }

  test(
    'expense, income, transfer, failed save and undo log no values',
    () async {
      env.sink.records.clear();
      h.type('250');
      h.notifier.setNote('secret note');
      await h.notifier.save();
      final String id = h.state.saved!.id;
      expect(env.sink.allText, contains('save started type=expense'));
      expect(env.sink.allText, contains('save done type=expense'));

      final QuickAddHarness inc = QuickAddHarness(env);
      addTearDown(inc.dispose);
      await inc.loaded();
      inc.notifier.setType(TransactionType.income);
      inc.type('1200.50');
      await inc.notifier.save();
      expect(env.sink.allText, contains('save done type=income'));

      final QuickAddHarness tr = QuickAddHarness(env);
      addTearDown(tr.dispose);
      await tr.loaded();
      tr.notifier.setType(TransactionType.transfer);
      tr.type('2000');
      await tr.notifier.save();
      expect(env.sink.allText, contains('save done type=transfer'));

      final Account temp = await env.account('Temp');
      final QuickAddHarness bad = QuickAddHarness(env);
      addTearDown(bad.dispose);
      await bad.loaded();
      bad.type('250');
      bad.notifier.pickAccount(temp.id);
      await env.accounts.softDelete(temp.id);
      await bad.notifier.save();
      expect(bad.state.status, SaveStatus.failed);
      expect(env.sink.allText, contains('save failed'));

      expect(await h.container.read(quickAddUndoProvider)(id), isTrue);
      expect(env.sink.allText, contains('undo done'));

      h.notifier.setType(TransactionType.income); // ignored: locked
      expectClean();
    },
  );

  test('tab change and pad keys log at most the tab name', () async {
    env.sink.records.clear();
    final QuickAddHarness x = QuickAddHarness(env);
    addTearDown(x.dispose);
    await x.loaded();
    x.type('250');
    x.notifier.paste('₹250');
    x.notifier.setType(TransactionType.income);
    expect(env.sink.allText, contains('tab changed to income'));
    expectClean();
  });
}
