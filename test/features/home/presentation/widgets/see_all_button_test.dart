import 'package:auditor_monkey/features/home/presentation/widgets/see_all_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/haptics_probe.dart';
import '../../../../support/widget_harness.dart';

void main() {
  group('SeeAllButton', () {
    testWidgets('is a labelled button and calls onTap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpThemed(tester, SeeAllButton(onTap: () => taps++), height: null);
      expect(find.bySemanticsLabel('See all'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('See all'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('is at least 44pt tall and wide', (WidgetTester tester) async {
      await pumpThemed(tester, SeeAllButton(onTap: () {}), height: null);
      final Size size = tester.getSize(find.byType(SeeAllButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });

    testWidgets('a tap plays a selection haptic', (WidgetTester tester) async {
      final List<String> played = probeHaptics();
      await pumpThemed(tester, SeeAllButton(onTap: () {}), height: null);
      await tester.tap(find.bySemanticsLabel('See all'));
      await tester.pumpAndSettle();
      expect(played, contains('HapticFeedbackType.selectionClick'));
    });

    testWidgets('text scale 2.0 does not clip', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        SeeAllButton(onTap: () {}),
        textScale: 2,
        height: null,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
