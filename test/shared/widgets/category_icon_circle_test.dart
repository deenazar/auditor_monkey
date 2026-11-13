import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/theme/category_colours.dart';
import 'package:auditor_monkey/shared/widgets/category_icon.dart';
import 'package:auditor_monkey/shared/widgets/category_icon_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

/// The round badge: the decorated box that holds the icon.
Finder _badge() =>
    find.ancestor(of: find.byType(Icon), matching: find.byType(DecoratedBox));

void main() {
  testWidgets('shows the category icon on the group tint, 44 by default', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const Align(
        child: CategoryIconCircle(
          iconName: 'shopping-cart',
          colourGroup: 'food',
        ),
      ),
    );
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, categoryIconFor('shopping-cart'));
    expect(icon.color, AppColors.ink);
    expect(icon.size, AppSizes.iconInline);
    expect(tester.getSize(_badge()), const Size(44, 44));
    expect(
      (tester.widget<DecoratedBox>(_badge()).decoration as BoxDecoration).color,
      categoryGroupTint('food'),
    );
  });

  testWidgets('explicit fill and size override the tint and size', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const Align(
        child: CategoryIconCircle(
          iconName: 'not-real',
          colourGroup: 'unknown',
          size: AppSizes.chipIconCircle,
          iconSize: AppSizes.iconChip,
          fill: AppColors.background,
        ),
      ),
    );
    expect(tester.getSize(_badge()), const Size(28, 28));
    expect(tester.widget<Icon>(find.byType(Icon)).icon, categoryFallbackIcon);
    expect(
      (tester.widget<DecoratedBox>(_badge()).decoration as BoxDecoration).color,
      AppColors.background,
    );
  });
}
