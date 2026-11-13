import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

Finder _button() => find.descendant(
  of: find.byType(PrimaryButton),
  matching: find.byType(AnimatedContainer),
);

void main() {
  testWidgets('shows the label, is 52pt tall and full width', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      PrimaryButton(label: 'Get started', onPressed: () {}),
    );
    expect(find.bySemanticsLabel('Get started'), findsOneWidget);
    final Size size = tester.getSize(_button());
    expect(size.height, AppSizes.buttonHeight);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, testPhoneWidth);
  });

  testWidgets('tap calls onPressed', (WidgetTester tester) async {
    int taps = 0;
    await pumpCompact(
      tester,
      PrimaryButton(label: 'Save', onPressed: () => taps++),
    );
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('pressed scales to pressScale and turns primaryDeep', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, PrimaryButton(label: 'Save', onPressed: () {}));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final AnimatedScale scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, AppSizes.pressScale);

    final BoxDecoration decoration =
        tester.widget<AnimatedContainer>(_button()).decoration!
            as BoxDecoration;
    expect(decoration.color, AppColors.primaryDeep);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('reduce motion: pressed does not scale', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      PrimaryButton(label: 'Save', onPressed: () {}),
      reduceMotion: true,
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Save')),
    );
    await tester.pump();

    final AnimatedScale scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('disabled: divider fill, no tap, semantics disabled', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, const PrimaryButton(label: 'Continue'));

    final BoxDecoration decoration =
        tester.widget<AnimatedContainer>(_button()).decoration!
            as BoxDecoration;
    expect(decoration.color, AppColors.divider);
    final Semantics semantics = tester.widget<Semantics>(
      find.bySemanticsLabel('Continue'),
    );
    expect(semantics.properties.enabled, isFalse);
    expect(semantics.properties.button, isTrue);
  });

  testWidgets('loading: shows a ring, hides the label, ignores taps', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpCompact(
      tester,
      PrimaryButton(
        label: 'Create accounts',
        loading: true,
        onPressed: () => taps++,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Create accounts'), findsNothing);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(taps, 0);
    // The ring spins forever, so do not settle; the test ends here.
  });

  testWidgets('large text (2.0) does not overflow', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      PrimaryButton(label: 'Create my accounts now', onPressed: () {}),
      textScale: 2,
      width: 200,
    );
    expect(tester.takeException(), isNull);
  });
}
