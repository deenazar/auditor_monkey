import 'dart:ui' show Tristate;

import 'package:auditor_monkey/features/quick_add/presentation/widgets/category_chip.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/category_chip_row.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/choice_pill.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_view_models.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

const List<CategoryChipData> _chips = <CategoryChipData>[
  CategoryChipData(
    id: 'g',
    name: 'Groceries',
    icon: 'shopping-cart',
    colourGroup: 'food',
  ),
  CategoryChipData(id: 'b', name: 'Bus', icon: 'bus', colourGroup: 'transport'),
  CategoryChipData(
    id: 'x',
    name: 'Unknown',
    icon: 'no-such',
    colourGroup: 'nope',
  ),
];

Color _labelColourOf(WidgetTester tester, String label) {
  final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DefaultTextStyle))
        .first,
  );
  return style.style.color!;
}

void main() {
  testWidgets('a chip reports its tap and reads as a selected button', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpCompact(
      tester,
      CategoryChip(
        name: 'Groceries',
        iconName: 'shopping-cart',
        colourGroup: 'food',
        selected: true,
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_labelColourOf(tester, 'Groceries'), AppColors.onDark);
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Groceries'),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('an unselected chip is tile with ink text, 44 tall', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChip(
        name: 'Bus',
        iconName: 'bus',
        colourGroup: 'transport',
        selected: false,
        onTap: () {},
      ),
    );
    expect(_labelColourOf(tester, 'Bus'), AppColors.ink);
    expect(
      tester.getSize(find.bySemanticsLabel('Bus')).height,
      AppSizes.chipHeight,
    );
  });

  testWidgets('All chip uses the layout-grid icon and calls onAll', (
    WidgetTester tester,
  ) async {
    int all = 0;
    await pumpCompact(
      tester,
      Align(child: CategoryChip.all(selected: false, onTap: () => all++)),
    );
    expect(find.byIcon(LucideIcons.layoutGrid), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('All categories'));
    expect(all, 1);
  });

  testWidgets('row: All first, then chips in order; picks report the id', (
    WidgetTester tester,
  ) async {
    final List<String> picked = <String>[];
    int allTaps = 0;
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: 'g',
        onSelected: picked.add,
        onAll: () => allTaps++,
      ),
    );
    final double allX = tester
        .getCenter(find.bySemanticsLabel('All categories'))
        .dx;
    final double groceriesX = tester.getCenter(find.text('Groceries')).dx;
    expect(allX, lessThan(groceriesX));

    await tester.tap(find.text('Bus'));
    await tester.tap(find.bySemanticsLabel('All categories'));
    expect(picked, <String>['b']);
    expect(allTaps, 1);
  });

  testWidgets('the selected chip is the one whose id matches', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: 'b',
        onSelected: (String _) {},
        onAll: () {},
      ),
    );
    expect(_labelColourOf(tester, 'Bus'), AppColors.onDark);
    expect(_labelColourOf(tester, 'Groceries'), AppColors.ink);
    expect(_labelColourOf(tester, 'Unknown'), AppColors.ink);
  });

  testWidgets('allSelected highlights the All chip', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: null,
        allSelected: true,
        onSelected: (String _) {},
        onAll: () {},
      ),
    );
    final ChoicePill pill = tester.widget<ChoicePill>(
      find.byType(ChoicePill).first,
    );
    expect(pill.selected, isTrue);
  });

  testWidgets('unknown icon and group names do not throw', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: null,
        onSelected: (String _) {},
        onAll: () {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('press feedback: reduce motion keeps the chip still', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: null,
        onSelected: (String _) {},
        onAll: () {},
      ),
      reduceMotion: true,
    );
    final AnimatedContainer box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    expect(box.duration, Duration.zero);
    expect(AppMotion.durationFast, isNot(Duration.zero));
  });

  testWidgets('text scale 2.0 keeps chips whole inside the row', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      CategoryChipRow(
        chips: _chips,
        selectedId: 'g',
        onSelected: (String _) {},
        onAll: () {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.bySemanticsLabel('Groceries')).height,
      AppSizes.chipHeight,
    );
  });
}
