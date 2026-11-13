@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/home_fixtures.dart';
import '../../../support/rupee_golden.dart';

void main() {
  testWidgets('golden: home_data', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: HomeScreen()),
      'home_data',
      overrides: homeOverrides(homeSummary()),
    );
  });

  testWidgets('golden: home_over_plan', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: HomeScreen()),
      'home_over_plan',
      overrides: homeOverrides(
        homeSummary(monthSpent: 9000000, monthIncome: 8500000),
      ),
    );
  });

  testWidgets('golden: home_empty', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: HomeScreen()),
      'home_empty',
      overrides: homeOverrides(emptyHomeSummary()),
    );
  });
}
