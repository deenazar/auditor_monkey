@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/home_fixtures.dart';
import '../../../support/rupee_golden.dart';
import '../../../support/test_env.dart';

/// Home with the clock (sky and sleepiness) at [time].
Widget _at(DateTime time) => ProviderScope(
  overrides: <Override>[
    clockProvider.overrideWithValue(FakeClock(time.millisecondsSinceEpoch)),
  ],
  child: const Scaffold(body: HomeScreen()),
);

void main() {
  testWidgets('golden: home_day', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: HomeScreen()),
      'home_day',
      overrides: homeOverrides(homeSummary()),
    );
  });

  testWidgets('golden: home_night_over_budget', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      _at(DateTime(2026, 11, 12, 21, 30)),
      'home_night_over_budget',
      overrides: homeOverrides(homeSummary(), budget: 1500000),
    );
  });

  testWidgets('golden: home_dawn_empty', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      _at(DateTime(2026, 11, 12, 6, 30)),
      'home_dawn_empty',
      overrides: homeOverrides(emptyHomeSummary()),
    );
  });

  testWidgets('golden: home_late_night_sleeping', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      _at(DateTime(2026, 11, 12, 23, 30)),
      'home_late_night_sleeping',
      overrides: homeOverrides(emptyHomeSummary()),
    );
  });
}
