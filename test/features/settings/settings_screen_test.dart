import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:auditor_monkey/features/settings/presentation/settings_screen.dart';
import 'package:auditor_monkey/shared/wow/swipe_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

void main() {
  testWidgets('living header, monkey and the setting rows', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(AuditorMonkey), findsOneWidget);
    expect(find.text('Demo data'), findsOneWidget);
    expect(find.text('Say hi to the monkey'), findsOneWidget);
    expect(find.text('Reduced, as set on your phone'), findsOneWidget);
    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.byType(SwipeActionRow), findsNWidgets(5));
  });

  testWidgets('open-source licences opens the licence page', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('long press on a row previews what it does', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Motion'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('follows the Reduce Motion setting'),
      findsOneWidget,
    );
  });
}
