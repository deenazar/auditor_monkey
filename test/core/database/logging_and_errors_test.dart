import 'package:auditor_monkey/core/database/repository_support.dart';
import 'package:auditor_monkey/core/logging/log_level.dart';
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/core/utils/id_generator.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  group('logging', () {
    late TestEnv env;

    setUp(() => env = TestEnv());
    tearDown(() => env.close());

    test('logs operations by name and short id, never user data', () async {
      final Account a = await env.accounts.create(
        accountDraft(name: 'ZebraSecretBank', opening: 987654321),
      );
      final String cat = await env.seededCategoryId('Groceries', 'expense');
      final TransactionEntry t = await env.transactions.create(
        expenseDraft(
          accountId: a.id,
          categoryId: cat,
          amount: 123456789,
          note: 'SECRETNOTE for Ravi',
        ),
      );
      final Loan loan = await env.loans.create(
        loanDraft(person: 'PersonXyzAbc', principal: 555666777),
      );
      await env.transactions.update(
        t.id,
        expenseDraft(accountId: a.id, categoryId: cat, amount: 42424242),
      );
      await env.transactions.softDelete(t.id);
      await env.transactions.restore(t.id);
      await env.loans.softDelete(loan.id);

      final String text = env.sink.allText;
      for (final String secret in <String>[
        'ZebraSecretBank',
        'SECRETNOTE',
        'PersonXyzAbc',
        '987654321',
        '123456789',
        '555666777',
        '42424242',
        'Ravi',
      ]) {
        expect(text, isNot(contains(secret)), reason: secret);
      }
      expect(text, contains('create ok id=${shortId(a.id)}'));
      expect(text, contains('update ok id=${shortId(t.id)}'));
      expect(text, contains('softDelete ok id=${shortId(t.id)}'));
      expect(text, contains('restore ok id=${shortId(t.id)}'));
      // Full ids are never logged.
      expect(text, isNot(contains(a.id)));
    });

    test('short ids made only of digits are logged, not masked', () async {
      final TestEnv digits = TestEnv(ids: _DigitIds());
      addTearDown(digits.close);
      final Account a = await digits.accounts.create(
        accountDraft(name: 'Wallet', opening: 100),
      );
      expect(shortId(a.id), '12345678');
      expect(digits.sink.allText, contains('create ok id=12345678'));
    });

    test('rejected input is a warning with the code only', () async {
      await expectLater(
        env.accounts.create(accountDraft(name: 'SecretName', opening: -5)),
        throwsA(isA<ValidationFailure>()),
      );
      final LogRecord last = env.sink.records.last;
      expect(last.level, LogLevel.warning);
      expect(last.message, 'create rejected: outOfRange');
      expect(env.sink.allText, isNot(contains('SecretName')));
    });

    test('a duplicate is a warning; unexpected failures are errors', () async {
      await env.accounts.create(accountDraft(name: 'Dup'));
      await expectLater(
        env.accounts.create(accountDraft(name: 'dup')),
        throwsA(isA<DuplicateFailure>()),
      );
      expect(env.sink.records.last.level, LogLevel.warning);
      expect(env.sink.records.last.message, 'create rejected: duplicate');

      await expectLater(
        env.ctx.run<void>('test', 'boom', () async {
          throw StateError('SECRET inner text 99887766');
        }),
        throwsA(isA<StorageFailure>()),
      );
      final LogRecord err = env.sink.records.last;
      expect(err.level, LogLevel.error);
      expect(err.message, 'boom failed: storage');
      expect(env.sink.allText, isNot(contains('SECRET')));
    });

    test('stream errors are mapped and logged', () async {
      final Stream<int> bad = env.ctx.guardStream<int>(
        'test',
        'watchBad',
        Stream<int>.error(StateError('SECRET')),
      );
      await expectLater(bad, emitsError(isA<StorageFailure>()));
      expect(env.sink.allText, contains('watchBad failed: storage'));
      expect(env.sink.allText, isNot(contains('SECRET')));
    });
  });

  group('mapDatabaseError', () {
    test('overflow, unique and primary key map to typed failures', () {
      expect(
        mapDatabaseError(
          SqliteException(extendedResultCode: 1, message: 'integer overflow'),
        ),
        isA<OverflowFailure>(),
      );
      final DataFailure unique = mapDatabaseError(
        SqliteException(
          extendedResultCode: 2067,
          message: 'UNIQUE constraint failed',
        ),
        duplicateMessage: 'Already there.',
      );
      expect(unique, isA<DuplicateFailure>());
      expect(unique.message, 'Already there.');
      expect(
        mapDatabaseError(
          SqliteException(extendedResultCode: 1555, message: 'PRIMARY KEY'),
        ),
        isA<DuplicateFailure>(),
      );
    });

    test('CHECK, foreign key and unknown errors become StorageFailure', () {
      for (final Object e in <Object>[
        SqliteException(
          extendedResultCode: 275,
          message: 'CHECK constraint failed',
        ),
        SqliteException(
          extendedResultCode: 787,
          message: 'FOREIGN KEY constraint failed',
        ),
        StateError('x'),
        'a string',
      ]) {
        expect(mapDatabaseError(e), isA<StorageFailure>());
      }
    });

    test('failure messages never contain the raw error text', () {
      final DataFailure f = mapDatabaseError(
        SqliteException(
          extendedResultCode: 275,
          message: 'CHECK failed',
          causingStatement: 'INSERT INTO t VALUES (SECRETVALUE)',
        ),
      );
      expect(f.message, isNot(contains('SECRETVALUE')));
      expect(
        describeErrorForLog(
          SqliteException(
            extendedResultCode: 275,
            message: 'x',
            causingStatement: 'SECRETVALUE',
          ),
        ),
        'SqliteException(code 275)',
      );
    });

    test('DataFailure passes through unchanged', () {
      const NotFoundFailure f = NotFoundFailure();
      expect(identical(mapDatabaseError(f), f), isTrue);
    });
  });

  group('checks that need the seeded data', () {
    test('category kind enum round trip', () {
      expect(CategoryKind.values.byName('income'), CategoryKind.income);
      expect(AccountType.values.byName('pf'), AccountType.pf);
    });
  });
}

/// Makes valid UUID v4 text whose first 8 characters are all digits
/// (about 1 in 100 random ids look like this).
class _DigitIds extends IdGenerator {
  int _next = 0;

  @override
  String newId() =>
      '12345678-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
}
