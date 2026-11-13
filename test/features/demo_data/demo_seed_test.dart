import 'package:auditor_monkey/core/database/seed/default_categories.dart';
import 'package:auditor_monkey/core/utils/date_keys.dart';
import 'package:auditor_monkey/features/accounts/data/accounts_repository.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/demo_data/data/demo_seeder.dart';
import 'package:auditor_monkey/features/demo_data/domain/demo_accounts.dart';
import 'package:auditor_monkey/features/demo_data/domain/demo_seed_generator.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  final DateTime today = DateTime(2026, 11, 13);
  late List<TransactionDraft> drafts;

  setUp(() => drafts = generateDemoTransactions(today));

  test('is deterministic', () {
    final List<TransactionDraft> again = generateDemoTransactions(today);
    expect(again.length, drafts.length);
    for (int i = 0; i < drafts.length; i++) {
      expect(again[i].amount, drafts[i].amount);
      expect(again[i].note, drafts[i].note);
      expect(again[i].date, drafts[i].date);
    }
  });

  test('has a realistic number of rows', () {
    expect(drafts.length, inInclusiveRange(300, 600));
  });

  test('every account and every category is used', () {
    final Set<String> accounts = <String>{
      for (final TransactionDraft d in drafts) ...<String>[
        d.accountId,
        ?d.toAccountId,
      ],
    };
    expect(accounts, accountPresets.map((AccountPreset p) => p.id).toSet());
    final Set<String> cats = <String>{
      for (final TransactionDraft d in drafts) ?d.categoryId,
    };
    expect(cats, defaultCategories.map((DefaultCategory c) => c.id).toSet());
  });

  test('dates are inside the 90 day range', () {
    final String from = dateKey(DateTime(2026, 11, 13 - (demoDays - 1)));
    for (final TransactionDraft d in drafts) {
      expect(d.date.compareTo(from), greaterThanOrEqualTo(0));
      expect(d.date.compareTo('2026-11-13'), lessThanOrEqualTo(0));
    }
  });

  test('transfers have no category; others have one; amounts are paise', () {
    for (final TransactionDraft d in drafts) {
      expect(d.amount, greaterThan(0));
      if (d.type == TransactionType.transfer) {
        expect(d.categoryId, isNull);
        expect(d.toAccountId, isNotNull);
        expect(d.toAccountId, isNot(d.accountId));
      } else {
        expect(d.categoryId, isNotNull);
      }
      expect(d.note!.length, lessThanOrEqualTo(200));
    }
  });

  test('salary is on the 1st', () {
    final String salary = demoCategoryIds['Salary']!;
    for (final TransactionDraft d in drafts.where(
      (TransactionDraft d) => d.categoryId == salary,
    )) {
      expect(d.date.endsWith('-01'), isTrue);
    }
  });

  test('seeding writes everything and balances follow the rules', () async {
    final TestEnv env = TestEnv();
    addTearDown(env.db.close);
    final int clockToday = DateTime(2026, 11, 13, 10).millisecondsSinceEpoch;
    env.clock.now = clockToday;
    final Stopwatch watch = Stopwatch()..start();
    final int count = await seedDemoData(
      env.db,
      clock: env.clock,
      logger: env.ctx.logger,
    );
    watch.stop();
    expect(count, drafts.length);
    expect(watch.elapsedMilliseconds, lessThan(2000));

    final List<AccountBalance> balances = await AccountsRepository(env.ctx)
        .getBalances();
    expect(balances, hasLength(7));
    int expected = 0;
    for (final MapEntry<String, int> e in demoOpeningBalances.entries) {
      expected += e.value;
    }
    for (final TransactionDraft d in drafts) {
      if (d.type == TransactionType.income) expected += d.amount;
      if (d.type == TransactionType.expense) expected -= d.amount;
    }
    expect(
      balances.fold<int>(0, (int s, AccountBalance b) => s + b.balance),
      expected,
    );
    for (final AccountBalance b in balances) {
      expect(b.balance, greaterThanOrEqualTo(0));
    }
  });
}
