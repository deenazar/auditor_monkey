import 'package:auditor_monkey/features/setup/presentation/start_screen.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../support/widget_harness.dart';

void main() {
  testWidgets('loading: no ring before 300ms, ring after 300ms', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const StartScreen());
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    final CircularProgressIndicator ring = tester.widget(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.color, AppColors.primary);
    expect(ring.semanticsLabel, 'Loading');
  });

  testWidgets('leaving before 300ms cancels the timer without errors', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const StartScreen());
    await tester.pump(const Duration(milliseconds: 100));
    await pumpThemed(tester, const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('white background while loading', (WidgetTester tester) async {
    await pumpThemed(tester, const StartScreen());
    final ColoredBox box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(StartScreen),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, AppColors.background);
  });

  testWidgets('error: danger icon, title, body and Try again', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await pumpThemed(
      tester,
      StartScreen(
        error: Exception('database key rejected'),
        onRetry: () => retries++,
      ),
    );
    expect(find.text("We can't open your data"), findsOneWidget);
    expect(
      find.text('Your data is safe. Update or restart the app.'),
      findsOneWidget,
    );
    final Icon icon = tester.widget<Icon>(
      find.byIcon(LucideIcons.triangleAlert),
    );
    expect(icon.color, AppColors.danger);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.bySemanticsLabel('Try again'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('error text never shows the raw error object', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      StartScreen(error: Exception('database key rejected')),
    );
    expect(find.textContaining('database key'), findsNothing);
    expect(find.bySemanticsLabel('Try again'), findsNothing);
  });

  testWidgets('large text (2.0) on the error screen does not overflow', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      StartScreen(error: Object(), onRetry: () {}),
      textScale: 2,
      width: 280,
    );
    expect(tester.takeException(), isNull);
  });
}
