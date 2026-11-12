import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Account a;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A');
  });
  tearDown(() => env.close());

  Future<int> outstandingOf(String loanId) async {
    final List<LoanSummary> all = await env.loans.getSummaries();
    return all.firstWhere((LoanSummary s) => s.loan.id == loanId).outstanding;
  }

  group('outstanding amount', () {
    test(
      'lent: repayments are income; disbursement is not a repayment',
      () async {
        final Loan loan = await env.loans.create(loanDraft(principal: 100000));
        final String given = await env.seededCategoryId(
          'Loan Given',
          'expense',
        );
        final String back = await env.seededCategoryId(
          'Loan Repayment Received',
          'income',
        );
        await env.transactions.create(
          expenseDraft(
            accountId: a.id,
            categoryId: given,
            amount: 100000,
            loanId: loan.id,
          ),
        );
        expect(await outstandingOf(loan.id), 100000);
        await env.transactions.create(
          incomeDraft(
            accountId: a.id,
            categoryId: back,
            amount: 25000,
            loanId: loan.id,
          ),
        );
        await env.transactions.create(
          incomeDraft(
            accountId: a.id,
            categoryId: back,
            amount: 5000,
            loanId: loan.id,
          ),
        );
        expect(await outstandingOf(loan.id), 70000);
      },
    );

    test('borrowed: repayments are expense; money received is not', () async {
      final Loan loan = await env.loans.create(
        loanDraft(direction: LoanDirection.borrowed, principal: 80000),
      );
      final String received = await env.seededCategoryId(
        'Loan Received',
        'income',
      );
      final String repay = await env.seededCategoryId(
        'Loan Repayment',
        'expense',
      );
      await env.transactions.create(
        incomeDraft(
          accountId: a.id,
          categoryId: received,
          amount: 80000,
          loanId: loan.id,
        ),
      );
      expect(await outstandingOf(loan.id), 80000);
      await env.transactions.create(
        expenseDraft(
          accountId: a.id,
          categoryId: repay,
          amount: 30000,
          loanId: loan.id,
        ),
      );
      expect(await outstandingOf(loan.id), 50000);
    });

    test(
      'deleted repayments do not count; over-repaying goes negative',
      () async {
        final Loan loan = await env.loans.create(loanDraft(principal: 1000));
        final String back = await env.seededCategoryId(
          'Loan Repayment Received',
          'income',
        );
        final t = await env.transactions.create(
          incomeDraft(
            accountId: a.id,
            categoryId: back,
            amount: 1500,
            loanId: loan.id,
          ),
        );
        expect(await outstandingOf(loan.id), -500);
        await env.transactions.softDelete(t.id);
        expect(await outstandingOf(loan.id), 1000);
      },
    );

    test('summaries stream updates, open loans come first', () async {
      final Loan open = await env.loans.create(loanDraft(person: 'Open'));
      final Loan done = await env.loans.create(
        const LoanDraft(
          direction: LoanDirection.lent,
          person: 'Done',
          principal: 500,
          startDate: '2026-11-01',
          closed: true,
        ),
      );
      final List<LoanSummary> list = await env.loans.watchSummaries().first;
      expect(list.map((LoanSummary s) => s.loan.id), <String>[
        open.id,
        done.id,
      ]);
      expect(list.last.loan.closed, isTrue);
    });
  });

  group('validation', () {
    Future<void> rejects(LoanDraft d, String field) => expectLater(
      env.loans.create(d),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.field,
          'field',
          field,
        ),
      ),
    );

    test('person, principal and dates', () async {
      await rejects(loanDraft(person: ' '), 'person');
      await rejects(loanDraft(person: 'p' * 61), 'person');
      await rejects(loanDraft(principal: 0), 'principal');
      await rejects(loanDraft(principal: maxPaise + 1), 'principal');
      await rejects(
        const LoanDraft(
          direction: LoanDirection.lent,
          person: 'R',
          principal: 5,
          startDate: '2026-02-30',
        ),
        'startDate',
      );
      await rejects(
        const LoanDraft(
          direction: LoanDirection.lent,
          person: 'R',
          principal: 5,
          startDate: '2026-10-01',
          dueDate: '2026-09-30',
        ),
        'dueDate',
      );
      await rejects(
        LoanDraft(
          direction: LoanDirection.lent,
          person: 'R',
          principal: 5,
          startDate: '2026-10-01',
          note: 'n' * 201,
        ),
        'note',
      );
    });

    test('due date equal to start date is fine', () async {
      final Loan l = await env.loans.create(
        const LoanDraft(
          direction: LoanDirection.borrowed,
          person: 'R',
          principal: 5,
          startDate: '2026-10-01',
          dueDate: '2026-10-01',
        ),
      );
      expect(l.dueDate, '2026-10-01');
    });
  });

  group('update and delete', () {
    test('update can close a loan', () async {
      final Loan l = await env.loans.create(loanDraft());
      env.clock.advance();
      final Loan u = await env.loans.update(
        l.id,
        const LoanDraft(
          direction: LoanDirection.lent,
          person: 'Ravi',
          principal: 100000,
          startDate: '2026-10-01',
          closed: true,
        ),
      );
      expect(u.closed, isTrue);
      expect(u.updatedAt, l.updatedAt + 1000);
    });

    test(
      'delete is refused while live entries are linked; then allowed',
      () async {
        final Loan l = await env.loans.create(loanDraft());
        final String cat = await env.seededCategoryId('Loan Given', 'expense');
        final t = await env.transactions.create(
          expenseDraft(accountId: a.id, categoryId: cat, loanId: l.id),
        );
        await expectLater(
          env.loans.softDelete(l.id),
          throwsA(isA<InUseFailure>()),
        );
        await env.transactions.softDelete(t.id);
        await env.loans.softDelete(l.id);
        expect(await env.loans.getById(l.id), isNull);
        expect((await env.loans.restore(l.id)).isDeleted, isFalse);
      },
    );

    test('missing loan is a NotFoundFailure', () async {
      await expectLater(
        env.loans.softDelete('x'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
