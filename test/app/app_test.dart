import 'dart:ui' as ui;

import 'package:auditor_monkey/app/app.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _navLabels = <String>[
  'Home',
  'Insights',
  'Quick Add',
  'Transactions',
  'Accounts',
];

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: AuditorMonkeyApp()));
  await tester.pumpAndSettle();
}

/// True when the single nav node with [label] reports the selected flag.
bool _isSelected(WidgetTester tester, String label) {
  final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel(label));
  return node.flagsCollection.isSelected == ui.Tristate.isTrue;
}

void main() {
  group('AuditorMonkeyApp', () {
    testWidgets(
      'launches with a bottom nav of exactly 5 items and Home selected',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await _pumpApp(tester);

        for (final String label in _navLabels) {
          expect(
            find.bySemanticsLabel(label),
            findsOneWidget,
            reason: 'nav item "$label" should appear exactly once',
          );
        }

        expect(_isSelected(tester, 'Home'), isTrue);
        for (final String label in <String>[
          'Insights',
          'Transactions',
          'Accounts',
        ]) {
          expect(
            _isSelected(tester, label),
            isFalse,
            reason: '"$label" should not be selected',
          );
        }

        handle.dispose();
      },
    );

    testWidgets('tapping Insights selects it and deselects Home', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpApp(tester);
      await tester.tap(find.bySemanticsLabel('Insights'));
      await tester.pumpAndSettle();

      expect(_isSelected(tester, 'Insights'), isTrue);
      expect(_isSelected(tester, 'Home'), isFalse);

      handle.dispose();
    });

    testWidgets('tapping Quick Add opens the sheet with its title', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpApp(tester);
      expect(find.text('Quick Add'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Quick Add'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsOneWidget);

      handle.dispose();
    });
  });
}
