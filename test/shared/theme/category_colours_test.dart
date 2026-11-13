import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/category_colours.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every stored group name maps to its DESIGN.md token', () {
    expect(categoryGroupColour('essentials'), AppColors.accountScb);
    expect(categoryGroupColour('food'), AppColors.accountHand);
    expect(categoryGroupColour('transport'), AppColors.accountOutside);
    expect(categoryGroupColour('home'), AppColors.sun);
    expect(categoryGroupColour('lifestyle'), AppColors.accountSbi);
    expect(categoryGroupColour('health'), AppColors.primaryLight);
    expect(categoryGroupColour('family'), AppColors.lime);
    expect(categoryGroupColour('finance'), AppColors.accountPf);
    expect(categoryGroupColour('other'), AppColors.iconInactive);
    expect(categoryGroupColour('income'), AppColors.primary);
  });

  test('every CategoryColourGroup value is mapped and listed in order', () {
    for (final CategoryColourGroup group in CategoryColourGroup.values) {
      // `other` is the fallback colour itself; the rest must be explicit.
      if (group != CategoryColourGroup.other) {
        expect(
          categoryGroupColour(group.name),
          isNot(AppColors.iconInactive),
          reason: group.name,
        );
      }
    }
    expect(
      categoryGroupOrder.toSet(),
      CategoryColourGroup.values.map((CategoryColourGroup g) => g.name).toSet(),
    );
    expect(categoryGroupOrder.length, CategoryColourGroup.values.length);
  });

  test('unknown and empty names give the other colour and never throw', () {
    expect(categoryGroupColour('not-a-group'), AppColors.iconInactive);
    expect(categoryGroupColour(''), AppColors.iconInactive);
    expect(categoryGroupTint('not-a-group'), categoryGroupTint('other'));
  });

  test('tint is the group colour at 20% opacity', () {
    final Color tint = categoryGroupTint('food');
    expect(tint.a, closeTo(0.2, 0.01));
    expect(tint.r, closeTo(AppColors.accountHand.r, 0.01));
    expect(tint.g, closeTo(AppColors.accountHand.g, 0.01));
    expect(tint.b, closeTo(AppColors.accountHand.b, 0.01));
  });
}
