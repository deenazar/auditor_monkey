@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:auditor_monkey/features/mascot/application/mascot_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/rupee_golden.dart';

void main() {
  testWidgets('golden: home_with_mascot', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(body: HomeScreen()),
      'home_with_mascot',
      overrides: <Override>[mascotPosterOnlyProvider.overrideWithValue(true)],
    );
  });
}
