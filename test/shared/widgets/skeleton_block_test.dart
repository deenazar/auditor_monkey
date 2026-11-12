import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_radius.dart';
import 'package:auditor_monkey/shared/widgets/skeleton_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('is a static tile block with the given size and radius', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SkeletonBlock(height: 120, width: 200),
      ),
    );
    final Finder box = _block();
    expect(tester.getSize(box), const Size(200, 120));

    final BoxDecoration decoration =
        tester.widget<Container>(box).decoration! as BoxDecoration;
    expect(decoration.color, AppColors.tile);
    expect(decoration.borderRadius, AppRadius.card);
  });

  testWidgets('fills the width when no width is given', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, const SkeletonBlock(height: 40));
    expect(tester.getSize(_block()).width, testPhoneWidth);
  });

  testWidgets('is hidden from screen readers', (WidgetTester tester) async {
    await pumpCompact(tester, const SkeletonBlock(height: 40));
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
  });
}

/// The Container that paints the block.
Finder _block() => find.descendant(
  of: find.byType(SkeletonBlock),
  matching: find.byType(Container),
);
