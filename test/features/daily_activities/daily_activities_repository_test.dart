import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/daily_activities/domain/daily_activity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  test('create, read, update, delete, restore', () async {
    final DailyActivity a = await env.activities.create(
      const DailyActivityDraft(date: day, title: '  Paid rent ', note: ' ok '),
    );
    expect(a.title, 'Paid rent');
    expect(a.note, 'ok');
    expect((await env.activities.watchForDate(day).first).single.id, a.id);
    expect(await env.activities.watchForDate('2026-11-13').first, isEmpty);

    env.clock.advance();
    final DailyActivity u = await env.activities.update(
      a.id,
      const DailyActivityDraft(date: '2026-11-13', title: 'Moved'),
    );
    expect(u.date, '2026-11-13');
    expect(u.note, isNull);
    expect(u.updatedAt, a.updatedAt + 1000);

    await env.activities.softDelete(a.id);
    expect(await env.activities.getById(a.id), isNull);
    expect(await env.activities.watchForDate('2026-11-13').first, isEmpty);
    expect((await env.activities.restore(a.id)).isDeleted, isFalse);
  });

  test('validation: title, date, note length', () async {
    for (final DailyActivityDraft bad in <DailyActivityDraft>[
      const DailyActivityDraft(date: day, title: ' '),
      DailyActivityDraft(date: day, title: 't' * 81),
      const DailyActivityDraft(date: '2026-02-30', title: 'x'),
      DailyActivityDraft(date: day, title: 'x', note: 'n' * 1001),
    ]) {
      await expectLater(
        env.activities.create(bad),
        throwsA(isA<ValidationFailure>()),
      );
    }
    final DailyActivity ok = await env.activities.create(
      DailyActivityDraft(date: day, title: 't' * 80, note: 'n' * 1000),
    );
    expect(ok.note, hasLength(1000));
  });

  test('a note can have line breaks, a title cannot', () async {
    await env.activities.create(
      const DailyActivityDraft(date: day, title: 'x', note: 'a\nb'),
    );
    await expectLater(
      env.activities.create(const DailyActivityDraft(date: day, title: 'a\nb')),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('watchForDate rejects a bad date', () {
    expect(
      () => env.activities.watchForDate('nope'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('missing ids give NotFoundFailure', () async {
    await expectLater(
      env.activities.softDelete('x'),
      throwsA(isA<NotFoundFailure>()),
    );
    await expectLater(
      env.activities.update('x', activityDraft()),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
