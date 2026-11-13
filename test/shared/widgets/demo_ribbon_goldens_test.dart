@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/demo_data/application/demo_mode.dart';
import 'package:auditor_monkey/shared/widgets/demo_ribbon.dart';
import 'package:auditor_monkey/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/rupee_golden.dart';

void main() {
  testWidgets('golden: demo_ribbon', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DemoRibbon(),
            Expanded(child: Center(child: Text('Accounts'))),
          ],
        ),
      ),
      'demo_ribbon',
      overrides: <Override>[demoModeActiveProvider.overrideWithValue(true)],
    );
  });

  testWidgets('golden: error_generic', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const Scaffold(
        body: ErrorState(
          title: "We couldn't load your accounts",
          message: 'Check the app and try again.',
          onRetry: _noop,
        ),
      ),
      'error_generic',
    );
  });
}

void _noop() {}
