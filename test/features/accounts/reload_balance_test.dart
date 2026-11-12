// The owner's "done when" check for session 3: balances match the sum of
// transactions after a reload. Uses a real database FILE.
import 'dart:io';
import 'dart:math';

import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/logging/app_logger.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/accounts/application/account_statement_provider.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/loans/application/loans_providers.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_notifier.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_state.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_providers.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

ProviderContainer _open(File file, FakeClock clock) {
  return ProviderContainer(
    overrides: <Override>[
      appDatabaseProvider.overrideWith((Ref ref) {
        final AppDatabase db = AppDatabase(
          NativeDatabase(file),
          logger: AppLogger(sinks: const [], isRelease: false),
          clock: clock,
        );
        ref.onDispose(db.close);
        return db;
      }),
      clockProvider.overrideWithValue(clock),
    ],
  );
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('am_reload_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'balances match opening + live entries after close and reopen',
    () async {
      final File file = File('${dir.path}/test.sqlite');
      final FakeClock clock = FakeClock();
      final Random rnd = Random(42);

      // 1. Wizard save through providers.
      ProviderContainer c = _open(file, clock);
      c.listen(setupWizardProvider, (_, _) {});
      final SetupWizardNotifier wizard = c.read(setupWizardProvider.notifier);
      wizard.setBalanceText(
        c.read(setupWizardProvider).accounts[1].key,
        '12,345.50',
      );
      final String cardKey = () {
        wizard.addCustom(name: 'Card', type: AccountType.card, colour: 'sun');
        return c.read(setupWizardProvider).accounts.last.key;
      }();
      wizard
        ..setBalanceText(cardKey, '800')
        ..setOwes(cardKey, true)
        ..next()
        ..next()
        ..next();
      expect(await wizard.save(), isTrue);
      expect(c.read(setupWizardProvider).saveStatus, WizardSaveStatus.done);

      // 2. 200 mixed entries through the repository.
      final List<Account> accounts =
          (await c.read(accountsRepositoryProvider).getBalances())
              .map((AccountBalance b) => b.account)
              .toList();
      expect(accounts, hasLength(8));
      final tx = c.read(transactionsRepositoryProvider);
      final db = c.read(appDatabaseProvider);
      final String expenseCat =
          (await db.categoriesDao.watchLive(kind: 'expense').first).first.id;
      final String incomeCat =
          (await db.categoriesDao.watchLive(kind: 'income').first).first.id;
      final String loanId =
          (await c.read(loansRepositoryProvider).create(loanDraft())).id;
      final List<String> deleted = <String>[];
      for (int i = 0; i < 200; i++) {
        clock.advance();
        final Account a = accounts[rnd.nextInt(accounts.length)];
        Account b = accounts[rnd.nextInt(accounts.length)];
        while (b.id == a.id) {
          b = accounts[rnd.nextInt(accounts.length)];
        }
        final String date =
            '2026-${(1 + rnd.nextInt(11)).toString().padLeft(2, '0')}-'
            '${(1 + rnd.nextInt(28)).toString().padLeft(2, '0')}';
        final int amount = 100 + rnd.nextInt(500000);
        final TransactionEntry e = await tx.create(switch (i % 4) {
          0 => expenseDraft(
            accountId: a.id,
            categoryId: expenseCat,
            amount: amount,
            date: date,
            loanId: i % 8 == 0 ? loanId : null,
          ),
          1 => incomeDraft(
            accountId: a.id,
            categoryId: incomeCat,
            amount: amount,
            date: date,
            loanId: i % 8 == 1 ? loanId : null,
          ),
          _ => transferDraft(from: a.id, to: b.id, amount: amount, date: date),
        });
        if (i % 9 == 0) deleted.add(e.id);
      }
      for (final String id in deleted) {
        await tx.softDelete(id);
      }
      expect(deleted, isNotEmpty);
      final int loanRows = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM transactions WHERE loan_id IS NOT NULL',
          )
          .getSingle()
          .then((r) => r.read<int>('c'));
      expect(loanRows, greaterThan(5));

      // 3. Close everything and reopen the same file.
      c.dispose();
      await pumpEventQueue();
      c = _open(file, clock);
      addTearDown(c.dispose);
      final db2 = c.read(appDatabaseProvider);
      final List<AccountBalance> balances = await c
          .read(accountsRepositoryProvider)
          .getBalances();
      expect(balances, hasLength(8));

      // 4. Hand sum in Dart over live rows.
      final List<TransactionRow> live = await (db2.select(
        db2.transactions,
      )..where((t) => t.deletedAt.isNull())).get();
      expect(live.length, 200 - deleted.length);
      for (final AccountBalance b in balances) {
        int expected = b.account.openingBalance;
        for (final TransactionRow t in live) {
          if (t.accountId == b.account.id) {
            expected += t.type == 'income' ? t.amount : -t.amount;
          }
          if (t.toAccountId == b.account.id) expected += t.amount;
        }
        expect(
          b.balance,
          expected,
          reason: 'balance of ${b.account.sortOrder}',
        );

        // 5. Newest statement balanceAfter equals the card balance.
        final StatementPage all = await c
            .read(transactionsRepositoryProvider)
            .statementThrough(b.account.id, count: 5000);
        if (all.lines.isEmpty) {
          expect(b.balance, b.account.openingBalance);
        } else {
          expect(all.lines.first.balanceAfter, b.balance);
          final StatementLine oldest = all.lines.last;
          expect(oldest.balanceAfter - oldest.effect, b.account.openingBalance);
        }
        // Chart sums: hand sum that leaves out transfers and loan rows.
        final Map<String, int> income = <String, int>{};
        final Map<String, int> expense = <String, int>{};
        for (final TransactionRow t in live) {
          if (t.accountId != b.account.id || t.loanId != null) continue;
          final String m = t.date.substring(0, 7);
          if (t.type == 'income') income[m] = (income[m] ?? 0) + t.amount;
          if (t.type == 'expense') expense[m] = (expense[m] ?? 0) + t.amount;
        }
        final List<MonthlyTotal> monthly = await c
            .read(transactionsRepositoryProvider)
            .monthlyTotalsForAccount(
              b.account.id,
              fromMonth: '2026-01',
              toMonth: '2026-12',
            );
        expect(monthly, hasLength(12));
        for (final MonthlyTotal m in monthly) {
          expect(m.income, income[m.month] ?? 0, reason: m.month);
          expect(m.expense, expense[m.month] ?? 0, reason: m.month);
        }
        // Through the provider too.
        c.listen(accountStatementProvider(b.account.id), (_, _) {});
        final AccountStatementState s = await c.read(
          accountStatementProvider(b.account.id).future,
        );
        expect(s.balance, b.balance);
      }
      // Net worth is the sum of the cards.
      final int total = balances.fold(
        0,
        (int s, AccountBalance b) => s + b.balance,
      );
      expect(
        await c.read(accountsRepositoryProvider).watchNetWorth().first,
        total,
      );
    },
  );
}
