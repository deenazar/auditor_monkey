// The DB CHECK rules are a backup for the repository checks. These tests
// bypass the repositories with raw SQL and expect SQLite itself to refuse.
import 'package:auditor_monkey/core/database/repository_support.dart';
import 'package:auditor_monkey/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

const int _check = 275;
const int _foreignKey = 787;
const int _unique = 2067;
// ON DELETE RESTRICT reports this code.
const int _restrict = 1811;

const String _id1 = '00000000-0000-4000-8000-000000000001';
const String _id2 = '00000000-0000-4000-8000-000000000002';
const String _id3 = '00000000-0000-4000-8000-000000000003';
const String _id4 = '00000000-0000-4000-8000-000000000004';
const String _cat = '00000000-0000-4000-8000-0000000000c1';

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.rawSql(_account(_id1, 'A'));
    await env.rawSql(_account(_id2, 'B'));
    await env.rawSql(_category(_cat, 'Food2', 'expense'));
  });
  tearDown(() => env.close());

  Future<void> rejected(String sql, int code, [List<Object?>? args]) async {
    Object? caught;
    try {
      await env.rawSql(sql, args ?? const <Object?>[]);
    } on Object catch (e) {
      caught = e;
    }
    expect(caught, isNotNull, reason: 'SQLite accepted: $sql');
    expect(describeErrorForLog(caught!), contains('code $code'), reason: sql);
  }

  test('the valid base rows are accepted', () async {
    await env.rawSql(_tx(_id3, 'expense', 100, '2026-11-12', _id1, cat: _cat));
    expect(await env.count('transactions'), 1);
  });

  group('shared columns', () {
    test('id must be 36 characters', () async {
      await rejected(_account('short', 'X'), _check);
    });

    test('updated_at cannot be before created_at', () async {
      await rejected(_account(_id3, 'X', created: 2000, updated: 1000), _check);
    });

    test('times must be whole numbers', () async {
      await rejected(_account(_id3, 'X', created: 1.5, updated: 2), _check);
    });

    test('sync_status must be pending or synced', () async {
      await rejected(_account(_id3, 'X', sync: 'maybe'), _check);
    });
  });

  group('accounts', () {
    test('name length, type, colour, opening balance', () async {
      await rejected(_account(_id3, '   '), _check);
      await rejected(_account(_id3, 'n' * 41), _check);
      await rejected(_account(_id3, 'X', type: 'crypto'), _check);
      await rejected(_account(_id3, 'X', colour: ''), _check);
      await rejected(_account(_id3, 'X', colour: 'c' * 33), _check);
      await rejected(_account(_id3, 'X', opening: 1.5), _check);
      await rejected(_account(_id3, 'X', opening: maxPaise + 1), _check);
      await rejected(_account(_id3, 'X', opening: -maxPaise - 1), _check);
    });

    test('opening balance limits are accepted at the edge', () async {
      await env.rawSql(_account(_id3, 'Hi', opening: maxPaise));
      await env.rawSql(_account(_id4, 'Lo', opening: -maxPaise));
    });

    test('name is unique ignoring case, among live rows only', () async {
      await rejected(_account(_id3, 'a'), _unique);
      await env.rawSql(
        'UPDATE accounts SET deleted_at = 5000 WHERE id = ?',
        <Object?>[_id1],
      );
      await env.rawSql(_account(_id3, 'a'));
    });
  });

  group('categories', () {
    test('name, kind, colour group, icon', () async {
      await rejected(_category(_id3, ' ', 'expense'), _check);
      await rejected(_category(_id3, 'X', 'other'), _check);
      await rejected(_category(_id3, 'X', 'expense', group: 'pink'), _check);
      await rejected(_category(_id3, 'X', 'expense', icon: ''), _check);
      await rejected(_category(_id3, 'X', 'expense', icon: 'i' * 41), _check);
    });

    test('name is unique per kind', () async {
      await rejected(_category(_id3, 'food2', 'expense'), _unique);
      await env.rawSql(_category(_id3, 'Food2', 'income', group: 'income'));
    });
  });

  group('transactions', () {
    test('type, amount, date, text lengths', () async {
      await rejected(
        _tx(_id3, 'refund', 1, '2026-11-12', _id1, cat: _cat),
        _check,
      );
      for (final Object? amount in <Object?>[0, -5, 1.5, maxPaise + 1]) {
        await rejected(
          _tx(_id3, 'expense', amount, '2026-11-12', _id1, cat: _cat),
          _check,
        );
      }
      for (final String date in <String>[
        '2026-13-01',
        '2026-02-30',
        '2026-1-1',
        '12/11/2026',
        '',
        '2026-11-12 ',
      ]) {
        await rejected(_tx(_id3, 'expense', 1, date, _id1, cat: _cat), _check);
      }
      await rejected(
        _tx(_id3, 'expense', 1, day, _id1, cat: _cat, note: 'n' * 201),
        _check,
      );
      await rejected(
        _tx(_id3, 'expense', 1, day, _id1, cat: _cat, source: 's' * 121),
        _check,
      );
    });

    test('transfer rules', () async {
      await rejected(_tx(_id3, 'transfer', 1, day, _id1), _check); // no to
      await rejected(
        _tx(_id3, 'transfer', 1, day, _id1, to: _id1),
        _check,
      ); // same account
      await rejected(
        _tx(_id3, 'transfer', 1, day, _id1, to: _id2, cat: _cat),
        _check,
      ); // category
      await env.rawSql(_loan(_id4));
      await rejected(
        _tx(_id3, 'transfer', 1, day, _id1, to: _id2, loan: _id4),
        _check,
      ); // loan
      await env.rawSql(_tx(_id3, 'transfer', 1, day, _id1, to: _id2));
    });

    test('expense and income rules', () async {
      await rejected(_tx(_id3, 'expense', 1, day, _id1), _check); // no category
      await rejected(
        _tx(_id3, 'income', 1, day, _id1, to: _id2, cat: _cat),
        _check,
      ); // to account
    });

    test('foreign keys are enforced', () async {
      await rejected(
        _tx(_id3, 'expense', 1, day, 'f' * 36, cat: _cat),
        _foreignKey,
      );
      await rejected(
        _tx(_id3, 'expense', 1, day, _id1, cat: '1' * 36),
        _foreignKey,
      );
      await rejected(
        _tx(_id3, 'expense', 1, day, _id1, cat: _cat, loan: '2' * 36),
        _foreignKey,
      );
      await rejected(
        _tx(_id3, 'transfer', 1, day, _id1, to: '3' * 36),
        _foreignKey,
      );
    });

    test('a referenced account cannot be hard deleted', () async {
      await env.rawSql(_tx(_id3, 'expense', 1, day, _id1, cat: _cat));
      await rejected('DELETE FROM accounts WHERE id = ?', _restrict, <Object?>[
        _id1,
      ]);
      await rejected(
        'DELETE FROM categories WHERE id = ?',
        _restrict,
        <Object?>[_cat],
      );
    });
  });

  group('budgets', () {
    test('month, amount, unique slot', () async {
      for (final String month in <String>[
        '2026-13',
        '2026-1',
        '2026-11-01',
        '',
      ]) {
        await rejected(_budget(_id3, _cat, month, 100), _check);
      }
      for (final Object? amount in <Object?>[0, -1, 2.5, maxPaise + 1]) {
        await rejected(_budget(_id3, _cat, '2026-11', amount), _check);
      }
      await env.rawSql(_budget(_id3, _cat, '2026-11', 100));
      await rejected(_budget(_id4, _cat, '2026-11', 100), _unique);
      await rejected(_budget(_id4, '9' * 36, '2026-12', 100), _foreignKey);
    });
  });

  group('loans', () {
    test('direction, person, principal, dates, note', () async {
      await rejected(_loan(_id3, direction: 'gave'), _check);
      await rejected(_loan(_id3, person: ' '), _check);
      await rejected(_loan(_id3, person: 'p' * 61), _check);
      await rejected(_loan(_id3, principal: 0), _check);
      await rejected(_loan(_id3, principal: 1.5), _check);
      await rejected(_loan(_id3, principal: maxPaise + 1), _check);
      await rejected(_loan(_id3, start: '2026-02-30'), _check);
      await rejected(_loan(_id3, due: '2026-09-30'), _check);
      await rejected(_loan(_id3, due: 'soon'), _check);
      await rejected(_loan(_id3, note: 'n' * 201), _check);
    });
  });

  group('gold', () {
    test('holdings', () async {
      await rejected(_holding(_id3, desc: ' '), _check);
      await rejected(_holding(_id3, desc: 'd' * 81), _check);
      await rejected(_holding(_id3, weight: 0), _check);
      await rejected(_holding(_id3, weight: 1.5), _check);
      await rejected(_holding(_id3, weight: 100000001), _check);
      await rejected(_holding(_id3, purity: '14k'), _check);
      await rejected(_holding(_id3, date: '2025-02-30'), _check);
      await rejected(_holding(_id3, price: -1), _check);
      await rejected(_holding(_id3, price: maxPaise + 1), _check);
      await rejected(_holding(_id3, account: '4' * 36), _foreignKey);
      await env.rawSql(_holding(_id3, weight: 100000000, price: 0));
    });

    test('rates', () async {
      await rejected(_rate(_id3, '2026-02-30', '22k', 1), _check);
      await rejected(_rate(_id3, day, '14k', 1), _check);
      await rejected(_rate(_id3, day, '22K', 1), _check);
      await rejected(_rate(_id3, day, '22k', 0), _check);
      await rejected(_rate(_id3, day, '22k', 1000000001), _check);
      await rejected(_rate(_id3, day, '22k', 1.5), _check);
      await env.rawSql(_rate(_id3, day, '22k', 1000000000));
      await rejected(_rate(_id4, day, '22k', 5), _unique);
      await env.rawSql(_rate(_id4, day, '24k', 5));
    });
  });

  group('daily activities', () {
    test('date, title, note', () async {
      await rejected(_activity(_id3, date: '2026-02-30'), _check);
      await rejected(_activity(_id3, title: ' '), _check);
      await rejected(_activity(_id3, title: 't' * 81), _check);
      await rejected(_activity(_id3, note: 'n' * 1001), _check);
      await env.rawSql(_activity(_id3, note: 'n' * 1000));
    });
  });

  test('every table has a partial index on pending rows', () async {
    final rows = await env.db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'ix_%_pending' ORDER BY name",
        )
        .get();
    expect(rows, hasLength(8));
  });
}

const String day = '2026-11-12';

String _lit(Object? v) {
  if (v == null) return 'NULL';
  if (v is String) return "'${v.replaceAll("'", "''")}'";
  return '$v';
}

String _insert(String table, Map<String, Object?> v) =>
    'INSERT INTO $table (${v.keys.join(', ')}) '
    'VALUES (${v.values.map(_lit).join(', ')})';

Map<String, Object?> _base(
  String id, {
  Object? created = 1000,
  Object? updated = 1000,
  String sync = 'pending',
}) => <String, Object?>{
  'id': id,
  'created_at': created,
  'updated_at': updated,
  'sync_status': sync,
};

String _account(
  String id,
  String name, {
  String type = 'bank',
  String colour = 'primary',
  Object? opening = 0,
  Object? created = 1000,
  Object? updated = 1000,
  String sync = 'pending',
}) => _insert('accounts', <String, Object?>{
  ..._base(id, created: created, updated: updated, sync: sync),
  'name': name,
  'type': type,
  'colour': colour,
  'opening_balance': opening,
});

String _category(
  String id,
  String name,
  String kind, {
  String group = 'other',
  String icon = 'tag',
}) => _insert('categories', <String, Object?>{
  ..._base(id),
  'name': name,
  'kind': kind,
  'colour_group': group,
  'icon': icon,
});

String _tx(
  String id,
  String type,
  Object? amount,
  String date,
  String account, {
  String? to,
  String? cat,
  String? loan,
  String? note,
  String? source,
}) => _insert('transactions', <String, Object?>{
  ..._base(id),
  'type': type,
  'amount': amount,
  'date': date,
  'account_id': account,
  'to_account_id': to,
  'category_id': cat,
  'loan_id': loan,
  'note': note,
  'import_source': source,
});

String _budget(String id, String cat, String month, Object? amount) =>
    _insert('budgets', <String, Object?>{
      ..._base(id),
      'category_id': cat,
      'month': month,
      'amount': amount,
    });

String _loan(
  String id, {
  String direction = 'lent',
  String person = 'Ravi',
  Object? principal = 100,
  String start = '2026-10-01',
  String? due,
  String? note,
}) => _insert('loans', <String, Object?>{
  ..._base(id),
  'direction': direction,
  'person': person,
  'principal': principal,
  'start_date': start,
  'due_date': due,
  'note': note,
});

String _holding(
  String id, {
  String desc = 'Chain',
  Object? weight = 1000,
  String purity = '22k',
  String date = '2025-05-01',
  Object? price = 0,
  String? account,
}) => _insert('gold_holdings', <String, Object?>{
  ..._base(id),
  'description': desc,
  'weight_mg': weight,
  'purity': purity,
  'purchase_date': date,
  'purchase_price': price,
  'account_id': account,
});

String _rate(String id, String date, String purity, Object? rate) =>
    _insert('gold_rates', <String, Object?>{
      ..._base(id),
      'date': date,
      'purity': purity,
      'rate_per_gram': rate,
    });

String _activity(
  String id, {
  String date = day,
  String title = 'Did a thing',
  String? note,
}) => _insert('daily_activities', <String, Object?>{
  ..._base(id),
  'date': date,
  'title': title,
  'note': note,
});
