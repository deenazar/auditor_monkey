// Checks the hand-built test month (test/support/fixtures) with the
// existing APIs only: account balances, Net Worth and the Transactions
// tab's month summary. Numbers are plan section 5.3 to 5.4.
import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_list_repository.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures/test_month_2026_10.dart';

void main() {
  late TestMonth month;

  setUp(() async {
    month = await buildTestMonth();
  });

  tearDown(() async {
    await month.close();
  });

  group('test month 2026-10 fixture', () {
    test('account balances match plan 5.4 to the paisa', () async {
      final balances = await month.env.accounts.getBalances();
      final Map<String, int> byName = <String, int>{
        for (final AccountBalance b in balances) b.account.name: b.balance,
      };

      expect(byName, <String, int>{
        'Hand': 234950,
        'SBI': 8000000,
        'Axis': 1790000,
        'Food Card': 85000,
        'PF': 10000000,
        'Outside': 0,
        'HDFC Card': -180000,
        'Old Wallet': 30000,
      });
    });

    test('archived accounts are listed and counted in balances', () async {
      final balances = await month.env.accounts.getBalances();
      final AccountBalance oldWallet = balances.singleWhere(
        (AccountBalance b) => b.account.name == 'Old Wallet',
      );
      expect(oldWallet.account.archived, isTrue);
      expect(oldWallet.balance, 30000);
      expect(oldWallet.account.id, month.account('Old Wallet'));
    });

    test('preset accounts keep their fixed ids', () {
      expect(month.account('Hand'), '118ca4e7-af5f-414a-9332-19254608cd87');
      expect(month.account('SBI'), '14965b59-7d32-46f1-995e-56999a15cb2d');
      expect(month.account('PF'), '7dc19b4c-74fb-4587-84ba-8356cfc6f9f0');
    });

    test('Net Worth is ₹1,99,599.50 to the paisa', () async {
      final int netWorth = await month.env.accounts.watchNetWorth().first;
      expect(netWorth, 19959950);
      expect(formatPaise(netWorth), '₹1,99,599.50');
    });

    test(
      'Transactions month summary (no filter) gives Spent and Income',
      () async {
        final TransactionsListRepository list = TransactionsListRepository(
          month.env.ctx,
        );
        final MonthSummary summary = await list.monthSummary(
          const TransactionFilter(),
          testMonth,
        );

        expect(summary.spent, 3130050, reason: 'Spent ₹31,300.50');
        expect(summary.income, 6370000, reason: 'Income ₹63,700.00');
      },
    );

    test('soft-deleted T19 and its row are kept but hidden', () async {
      final transactions = month.env.transactions;
      expect(await transactions.getById(month.tx('T19')), isNull);
      expect(
        await transactions.getById(month.tx('T19'), includeDeleted: true),
        isNotNull,
      );
    });

    test('loan "Ravi" is lent with principal 10,000.00', () async {
      final loan = await month.env.loans.getById(month.loanId);
      expect(loan, isNotNull);
      expect(loan!.person, 'Ravi');
      expect(loan.principal, 1000000);
      expect(loan.startDate, '2026-10-12');
    });
  });
}
