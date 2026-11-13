import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/widgets/step_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('one pill for the current step, small dots for the others', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const StepDots(count: 4, current: 1));

    final List<Size> sizes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((AnimatedContainer c) => tester.getSize(find.byWidget(c)))
        .toList();
    expect(sizes.length, 4);
    expect(sizes[1].width, AppSizes.stepDotActiveWidth);
    expect(sizes[0].width, AppSizes.stepDot);
    expect(sizes[2].width, AppSizes.stepDot);
    expect(sizes[3].width, AppSizes.stepDot);

    final BoxDecoration active =
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).at(1))
                .decoration!
            as BoxDecoration;
    expect(active.color, AppColors.primaryDeep);
  });

  testWidgets('announces the step as text', (WidgetTester tester) async {
    await pumpThemed(tester, const StepDots(count: 4, current: 1));
    expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);
  });

  testWidgets('rejects an out of range current step', (
    WidgetTester tester,
  ) async {
    expect(
      () => StepDots(count: 3, current: 3),
      throwsA(isA<AssertionError>()),
    );
  });
}
