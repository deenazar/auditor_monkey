import 'package:auditor_monkey/features/demo_data/application/demo_mode.dart';
import 'package:auditor_monkey/features/demo_data/presentation/demo_data_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a sheet with Load demo data when demo mode is off', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DemoDataMenuButton())),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Load demo data'), findsOneWidget);
    expect(find.text('Clear demo data'), findsNothing);
  });

  testWidgets('shows Clear demo data when demo mode is on', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [demoModeInitialProvider.overrideWithValue(true)],
        child: const MaterialApp(home: Scaffold(body: DemoDataMenuButton())),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Clear demo data'), findsOneWidget);
  });
}
