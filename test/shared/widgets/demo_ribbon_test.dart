import 'package:auditor_monkey/features/demo_data/application/demo_mode.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:auditor_monkey/shared/widgets/demo_ribbon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool demo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [demoModeActiveProvider.overrideWithValue(demo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              DemoRibbon(),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the demo message while demo mode is on', (
    WidgetTester tester,
  ) async {
    await _pump(tester, demo: true);
    expect(find.text(DemoRibbon.message), findsOneWidget);
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text(DemoRibbon.message),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, AppColors.warning);
  });

  testWidgets('shows nothing while demo mode is off', (
    WidgetTester tester,
  ) async {
    await _pump(tester, demo: false);
    expect(find.text(DemoRibbon.message), findsNothing);
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.warning,
      ),
      findsNothing,
    );
  });
}
