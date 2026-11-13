import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:auditor_monkey/shared/widgets/error_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('shows the worried mascot, title and message', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const ErrorState(
        title: "We can't load accounts",
        message: 'Check your connection and try again.',
      ),
    );
    expect(find.text("We can't load accounts"), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    // Motion & 3D: an animated mascot moment instead of the drawing.
    expect(find.byType(AuditorMonkey), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets('retry button calls onRetry with the default label', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await pumpThemed(
      tester,
      ErrorState(
        title: 'Oops',
        message: 'It failed.',
        onRetry: () => retries++,
      ),
    );
    expect(find.bySemanticsLabel('Try again'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Try again'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('no retry button when onRetry is null', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const ErrorState(title: 'Oops', message: 'It failed.'),
    );
    expect(find.bySemanticsLabel('Try again'), findsNothing);
  });

  testWidgets('custom retry label is used', (WidgetTester tester) async {
    await pumpThemed(
      tester,
      ErrorState(
        title: 'Oops',
        message: 'It failed.',
        retryLabel: 'Retry now',
        onRetry: () {},
      ),
    );
    expect(find.bySemanticsLabel('Retry now'), findsOneWidget);
  });

  testWidgets('large text (2.0) does not overflow', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      ErrorState(
        title: "We can't open your data",
        message: 'Your data is safe. Update or restart the app.',
        onRetry: () {},
      ),
      textScale: 2,
      width: 240,
    );
    expect(tester.takeException(), isNull);
  });
}
