import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;
  late Account b;
  late String expenseCat;
  late String incomeCat;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A');
    b = await env.account('B');
    expenseCat = await env.seededCategoryId('Groceries', 'expense');
    incomeCat = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  Future<void> rejects(TransactionDraft d, String field, [FailureCode? code]) {
    return expectLater(
      env.transactions.create(d),
      throwsA(
        isA<ValidationFailure>()
            .having((ValidationFailure f) => f.field, 'field', field)
            .having(
              (ValidationFailure f) => f.code,
              'code',
              code ?? isA<FailureCode>(),
            ),
      ),
    );
  }

  TransactionDraft expense({
    int amount = 100,
    String date = day,
    String? note,
    String? categoryId,
    String? to,
    String? loanId,
  }) => TransactionDraft(
    type: TransactionType.expense,
    amount: amount,
    date: date,
    accountId: a.id,
    categoryId: categoryId ?? expenseCat,
    toAccountId: to,
    note: note,
    loanId: loanId,
  );

  group('amount', () {
    test('zero, negative and above maxPaise are rejected', () async {
      await rejects(expense(amount: 0), 'amount', FailureCode.outOfRange);
      await rejects(expense(amount: -1), 'amount', FailureCode.outOfRange);
      await rejects(
        expense(amount: maxPaise + 1),
        'amount',
        FailureCode.outOfRange,
      );
    });

    test('1 paisa and exactly maxPaise are accepted', () async {
      expect((await env.transactions.create(expense(amount: 1))).amount, 1);
      expect(
        (await env.transactions.create(expense(amount: maxPaise))).amount,
        maxPaise,
      );
    });
  });

  group('dates', () {
    test('bad dates are rejected', () async {
      for (final String bad in <String>[
        '',
        '2026-13-01',
        '2026-02-30',
        '2025-02-29',
        '2026-1-5',
        '26-11-12',
        '2026/11/12',
        '2026-11-12 ',
        '2026-11-12T10:00',
        'abcd-ef-gh',
        '0001-01-01',
      ]) {
        await rejects(expense(date: bad), 'date', FailureCode.invalidDate);
      }
    });

    test('leap day and month ends are accepted', () async {
      for (final String ok in <String>[
        '2024-02-29',
        '2026-12-31',
        '2026-04-30',
      ]) {
        expect((await env.transactions.create(expense(date: ok))).date, ok);
      }
    });
  });

  group('transfer rules', () {
    test('needs a destination', () async {
      await rejects(
        TransactionDraft(
          type: TransactionType.transfer,
          amount: 100,
          date: day,
          accountId: a.id,
        ),
        'toAccountId',
        FailureCode.required,
      );
    });

    test('cannot go to the same account', () async {
      await rejects(
        transferDraft(from: a.id, to: a.id),
        'toAccountId',
        FailureCode.rule,
      );
    });

    test('cannot have a category', () async {
      await rejects(
        TransactionDraft(
          type: TransactionType.transfer,
          amount: 100,
          date: day,
          accountId: a.id,
          toAccountId: b.id,
          categoryId: expenseCat,
        ),
        'categoryId',
        FailureCode.rule,
      );
    });

    test('cannot be linked to a loan', () async {
      final Loan loan = await env.loans.create(loanDraft());
      await rejects(
        TransactionDraft(
          type: TransactionType.transfer,
          amount: 100,
          date: day,
          accountId: a.id,
          toAccountId: b.id,
          loanId: loan.id,
        ),
        'loanId',
        FailureCode.rule,
      );
    });
  });

  group('expense and income rules', () {
    test('need a category', () async {
      await rejects(
        TransactionDraft(
          type: TransactionType.expense,
          amount: 100,
          date: day,
          accountId: a.id,
        ),
        'categoryId',
        FailureCode.required,
      );
      await rejects(
        TransactionDraft(
          type: TransactionType.income,
          amount: 100,
          date: day,
          accountId: a.id,
        ),
        'categoryId',
        FailureCode.required,
      );
    });

    test('cannot have a destination account', () async {
      await rejects(expense(to: b.id), 'toAccountId', FailureCode.rule);
    });

    test('category kind must match the type', () async {
      await rejects(
        expense(categoryId: incomeCat),
        'categoryId',
        FailureCode.kindMismatch,
      );
      await rejects(
        incomeDraft(accountId: a.id, categoryId: expenseCat),
        'categoryId',
        FailureCode.kindMismatch,
      );
    });
  });

  group('references', () {
    test('unknown or deleted account, category or loan is rejected', () async {
      await rejects(
        expenseDraft(accountId: 'nope', categoryId: expenseCat),
        'accountId',
        FailureCode.referenceMissing,
      );
      await rejects(
        transferDraft(from: a.id, to: 'nope'),
        'toAccountId',
        FailureCode.referenceMissing,
      );
      await rejects(
        expense(categoryId: 'nope'),
        'categoryId',
        FailureCode.referenceMissing,
      );
      await rejects(
        expense(loanId: 'nope'),
        'loanId',
        FailureCode.referenceMissing,
      );
      await env.accounts.softDelete(b.id);
      await rejects(
        transferDraft(from: a.id, to: b.id),
        'toAccountId',
        FailureCode.referenceMissing,
      );
      final Loan loan = await env.loans.create(loanDraft());
      await env.loans.softDelete(loan.id);
      await rejects(
        expense(loanId: loan.id),
        'loanId',
        FailureCode.referenceMissing,
      );
    });

    test('nothing is saved when a check fails', () async {
      await rejects(expense(categoryId: 'nope'), 'categoryId');
      expect(await env.count('transactions'), 0);
    });
  });

  group('text fields', () {
    test('note up to 200 characters, empty note becomes null', () async {
      expect(
        (await env.transactions.create(expense(note: 'n' * 200))).note,
        hasLength(200),
      );
      expect((await env.transactions.create(expense(note: '  '))).note, isNull);
      await rejects(expense(note: 'n' * 201), 'note', FailureCode.tooLong);
    });

    test('import source up to 120 characters', () async {
      TransactionDraft withSource(String s) => TransactionDraft(
        type: TransactionType.expense,
        amount: 100,
        date: day,
        accountId: a.id,
        categoryId: expenseCat,
        importSource: s,
      );
      await env.transactions.create(withSource('s' * 120));
      await rejects(withSource('s' * 121), 'importSource', FailureCode.tooLong);
    });
  });

  group('update and restore re-check the rules', () {
    test('update cannot break a rule', () async {
      final TransactionEntry t = await env.transactions.create(expense());
      await expectLater(
        env.transactions.update(t.id, expense(amount: 0)),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        env.transactions.update(t.id, expense(categoryId: incomeCat)),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await env.transactions.getById(t.id))!.amount, 100);
    });

    test('update can turn an expense into a transfer', () async {
      final TransactionEntry t = await env.transactions.create(expense());
      final TransactionEntry u = await env.transactions.update(
        t.id,
        transferDraft(from: a.id, to: b.id, amount: 250),
      );
      expect(u.type, TransactionType.transfer);
      expect(u.categoryId, isNull);
      expect(u.toAccountId, b.id);
    });

    test(
      'restore is refused when its category was deleted meanwhile',
      () async {
        final String cat = (await env.categories.create(categoryDraft())).id;
        final TransactionEntry t = await env.transactions.create(
          expense(categoryId: cat),
        );
        await env.transactions.softDelete(t.id);
        await env.categories.softDelete(cat);
        await expectLater(
          env.transactions.restore(t.id),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );
  });
}
