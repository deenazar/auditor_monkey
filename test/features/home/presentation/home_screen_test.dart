import 'package:auditor_monkey/features/demo_data/presentation/demo_data_menu_button.dart';
import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:auditor_monkey/features/mascot/application/mascot_providers.dart';
import 'package:auditor_monkey/features/mascot/presentation/mascot_view.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shows the idle mascot at 160pt above the message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mascotPosterOnlyProvider.overrideWithValue(true)],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(MascotView), findsOneWidget);
    expect(tester.getSize(find.byType(MascotView)), const Size(160, 160));
    expect(find.text('Your dashboard will show up here.'), findsOneWidget);
    expect(find.byType(DemoDataMenuButton), findsOneWidget);
  });
}
