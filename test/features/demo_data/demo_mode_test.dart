import 'dart:io';

import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/connection/open_connection.dart';
import 'package:auditor_monkey/core/database/database_files.dart';
import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/demo_data/application/demo_mode.dart';
import 'package:auditor_monkey/features/demo_data/data/demo_files.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('am_demo_test');
    container = ProviderContainer(
      overrides: [
        databaseDirectoryProvider.overrideWithValue(() async => dir),
        clockProvider.overrideWithValue(_FixedClock()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    dir.deleteSync(recursive: true);
  });

  File real() => File(p.join(dir.path, databaseFileName));
  File demo() => File(p.join(dir.path, demoDatabaseFileName));
  File marker() => File(p.join(dir.path, demoMarkerFileName));

  test('load and clear never write the real database file', () async {
    // Make the real file with one known custom row count (7 categories seed).
    final AppDatabase realDb = container.read(appDatabaseProvider);
    expect((await realDb.accountsDao.getBalances()), isEmpty);
    expect(real().existsSync(), isTrue);
    final List<int> before = real().readAsBytesSync();

    final DemoModeController demoCtl = container.read(
      demoModeControllerProvider.notifier,
    );
    await demoCtl.load();
    expect(container.read(demoModeActiveProvider), isTrue);
    expect(demo().existsSync(), isTrue);
    expect(marker().existsSync(), isTrue);
    final AppDatabase demoDb = container.read(appDatabaseProvider);
    expect((await demoDb.accountsDao.getBalances()).length, 7);

    await demoCtl.clear();
    expect(container.read(demoModeActiveProvider), isFalse);
    expect(demo().existsSync(), isFalse);
    expect(marker().existsSync(), isFalse);
    final AppDatabase back = container.read(appDatabaseProvider);
    expect(await back.accountsDao.getBalances(), isEmpty);
    expect(real().readAsBytesSync(), before);
  });

  test('marker file is read at start', () async {
    expect(await readDemoMarker(() async => dir), isFalse);
    await DemoFiles(dir).writeMarker();
    expect(await readDemoMarker(() async => dir), isTrue);
  });
}

class _FixedClock implements Clock {
  @override
  int nowMs() => DateTime(2026, 11, 13, 10).millisecondsSinceEpoch;
}
