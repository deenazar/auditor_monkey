import 'package:auditor_monkey/features/quick_add/presentation/widgets/num_pad_key.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/number_pad.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

void main() {
  late List<String> log;

  NumberPad pad({bool enabled = true}) => NumberPad(
    enabled: enabled,
    onDigit: (String d) => log.add('digit $d'),
    onDot: () => log.add('dot'),
    onBackspace: () => log.add('backspace'),
    onClear: () => log.add('clear'),
  );

  setUp(() => log = <String>[]);

  testWidgets('digits, point and delete call their callbacks', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad());
    await tester.tap(find.text('7'));
    await tester.tap(find.text('0'));
    await tester.tap(find.bySemanticsLabel('point'));
    await tester.tap(find.bySemanticsLabel('delete'));
    expect(log, <String>['digit 7', 'digit 0', 'dot', 'backspace']);
  });

  testWidgets('long press on delete clears and does not backspace', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad());
    await tester.longPress(find.bySemanticsLabel('delete'));
    await tester.pump();
    expect(log, <String>['clear']);
  });

  testWidgets('shows 12 keys in 4 rows of 3, in order', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad());
    expect(find.byType(NumPadKey), findsNWidgets(12));
    final double row1 = tester.getCenter(find.bySemanticsLabel('1')).dy;
    final double row4 = tester.getCenter(find.bySemanticsLabel('delete')).dy;
    expect(row4, greaterThan(row1));
    expect(
      tester.getCenter(find.bySemanticsLabel('1')).dx,
      lessThan(tester.getCenter(find.bySemanticsLabel('3')).dx),
    );
  });

  testWidgets('keys are 56 tall and at least 44 wide', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad());
    for (final String label in <String>['1', '0', 'point', 'delete']) {
      final Size size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.height, AppSizes.numPadKeyHeight, reason: label);
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
    }
  });

  testWidgets('disabled pad ignores taps and long presses', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad(enabled: false));
    await tester.tap(find.text('5'));
    await tester.tap(find.bySemanticsLabel('point'));
    await tester.longPress(find.bySemanticsLabel('delete'));
    expect(log, isEmpty);
  });

  testWidgets('a pressed key scales, unless reduce motion is on', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad());
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('1')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale,
      AppSizes.pressScale,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    await pumpCompact(tester, pad(), reduceMotion: true);
    final TestGesture reduced = await tester.startGesture(
      tester.getCenter(find.text('1')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale,
      1,
    );
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).duration,
      Duration.zero,
    );
    await reduced.up();
    await tester.pumpAndSettle();
  });

  testWidgets('text scale 2.0 keeps every key whole and at 44 or more', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, pad(), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.bySemanticsLabel('8')).height,
      greaterThanOrEqualTo(44),
    );
  });
}
