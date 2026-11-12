import 'dart:io';

import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/seed/default_categories.dart';
import 'package:auditor_monkey/core/logging/app_logger.dart';
import 'package:auditor_monkey/core/logging/log_level.dart';
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/core/logging/log_sink.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../support/test_env.dart';

void main() {
  group('fresh database', () {
    late TestEnv env;

    setUp(() => env = TestEnv());
    tearDown(() => env.close());

    test('has the 8 tables and schema version 1', () async {
      final List<QueryRow> rows = await env.db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      expect(rows.map((QueryRow r) => r.read<String>('name')), <String>[
        'accounts',
        'budgets',
        'categories',
        'daily_activities',
        'gold_holdings',
        'gold_rates',
        'loans',
        'transactions',
      ]);
      expect(env.db.schemaVersion, 1);
      final QueryRow v = await env.db
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(v.read<int>('user_version'), 1);
    });

    test('turns foreign keys on', () async {
      final QueryRow row = await env.db
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('seeds 34 categories: 26 expense and 8 income', () async {
      final List<QueryRow> rows = await env.db
          .customSelect(
            'SELECT kind, COUNT(*) AS c FROM categories GROUP BY kind',
          )
          .get();
      final Map<String, int> counts = <String, int>{
        for (final QueryRow r in rows) r.read<String>('kind'): r.read<int>('c'),
      };
      expect(counts, <String, int>{'expense': 26, 'income': 8});
    });

    test('seeded categories use the fixed ids and list order', () async {
      expect(defaultCategories, hasLength(34));
      expect(
        defaultCategories.map((DefaultCategory c) => c.id).toSet(),
        hasLength(34),
      );
      final List<Category> all = await env.categories.watchAll().first;
      expect(
        all.map((Category c) => c.id),
        defaultCategories.map((DefaultCategory c) => c.id),
      );
      expect(all.first.name, 'Groceries');
      expect(all.first.sortOrder, 0);
      expect(all.last.name, 'Other Income');
      expect(all.last.sortOrder, 33);
      expect(all.last.kind, CategoryKind.income);
      expect(all.last.colourGroup, CategoryColourGroup.income);
    });

    test('seed ids are well formed UUID v4 and rows are pending', () async {
      final RegExp v4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (final DefaultCategory c in defaultCategories) {
        expect(v4.hasMatch(c.id), isTrue, reason: c.name);
      }
      final Map<String, Object?> row = await env.rawRow(
        'categories',
        defaultCategories.first.id,
      );
      expect(row['sync_status'], 'pending');
      expect(row['created_at'], env.clock.now);
    });

    test('default category names are unique per kind', () {
      final Set<String> keys = defaultCategories
          .map((DefaultCategory c) => '${c.kind.name}:${c.name.toLowerCase()}')
          .toSet();
      expect(keys, hasLength(34));
    });

    test('logs the creation without any user data', () async {
      await env.categories.watchAll().first;
      expect(env.sink.allText, contains('created database v1'));
      expect(env.sink.allText, contains('seeded 34 categories'));
    });
  });

  group('file database', () {
    late Directory dir;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('am_db_test_');
      file = File('${dir.path}/test.sqlite');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('reopening does not seed again', () async {
      AppDatabase open() => AppDatabase(NativeDatabase(file));
      final AppDatabase first = open();
      expect(await first.categoriesDao.countLive(), 34);
      // Delete one seeded row (soft). A reseed would bring it back or add 34.
      await first.categoriesDao.softDelete(defaultCategories.first.id, 5000);
      await first.close();

      final AppDatabase second = open();
      expect(await second.categoriesDao.countLive(), 33);
      final QueryRow total = await second
          .customSelect('SELECT COUNT(*) AS c FROM categories')
          .getSingle();
      expect(total.read<int>('c'), 34);
      await second.close();
    });

    test('refuses a database from a newer app and keeps the data', () async {
      sqlite.sqlite3.open(file.path)
        ..execute('CREATE TABLE keep (x INTEGER)')
        ..execute('INSERT INTO keep VALUES (42)')
        ..execute('PRAGMA user_version = 5')
        ..close();

      final List<String> errors = <String>[];
      final AppLogger logger = AppLogger(
        sinks: <LogSink>[_CollectErrors(errors)],
        isRelease: false,
      );
      final AppDatabase db = AppDatabase(NativeDatabase(file), logger: logger);
      await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
      await db.close();
      expect(errors.single, contains('refusing to open database v5'));

      final sqlite.Database check = sqlite.sqlite3.open(file.path);
      expect(check.select('SELECT x FROM keep').single['x'], 42);
      expect(check.select('PRAGMA user_version').single['user_version'], 5);
      check.close();
    });
  });
}

class _CollectErrors implements LogSink {
  _CollectErrors(this.errors);

  final List<String> errors;

  @override
  void write(LogRecord record) {
    if (record.level == LogLevel.error) errors.add(record.message);
  }
}
