import 'package:auditor_monkey/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const ProviderScope(child: AuditorMonkeyApp()),
  );
}

void main() {
  const List<String> labels = <String>[
    'Home',
    'Insights',
    'Transactions',
    'Accounts',
  ];

  testWidgets('nav slots and Quick Add are at least 44x44', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final String label in <String>[...labels, 'Quick Add']) {
      final Size size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
      expect(size.height, greaterThanOrEqualTo(44), reason: label);
    }
    handle.dispose();
  });

  testWidgets('with reduce motion, tab switch shows the screen at once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Accounts'));
    await tester.pump();
    expect(find.text('Your Wallet'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Insights'));
    await tester.pump();
    expect(find.text('Your Spending'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Quick Add'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    handle.dispose();
  });
}
