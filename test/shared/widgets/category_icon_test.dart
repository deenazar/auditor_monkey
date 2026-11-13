import 'package:auditor_monkey/core/database/seed/default_categories.dart';
import 'package:auditor_monkey/shared/widgets/category_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('every seeded category icon maps to its own Lucide icon', () {
    expect(defaultCategories.length, 34);
    final Set<String> names = <String>{
      for (final DefaultCategory c in defaultCategories) c.icon,
    };
    // 34 categories share 30 distinct icon names.
    expect(names.length, 30);
    for (final String name in names) {
      // 'ellipsis' is itself the fallback icon, so it is checked by name.
      if (name == 'ellipsis') continue;
      expect(
        categoryIconFor(name),
        isNot(categoryFallbackIcon),
        reason: 'icon "$name" has no mapping',
      );
    }
    expect(categoryIconFor('ellipsis'), LucideIcons.ellipsis);
  });

  test('known names map to the expected Lucide icons', () {
    expect(categoryIconFor('shopping-cart'), LucideIcons.shoppingCart);
    expect(categoryIconFor('graduation-cap'), LucideIcons.graduationCap);
    expect(categoryIconFor('undo-2'), LucideIcons.undo2);
    expect(categoryIconFor('heart-pulse'), LucideIcons.heartPulse);
  });

  test('unknown or empty names give the fallback and never throw', () {
    expect(categoryIconFor('not-a-real-icon'), categoryFallbackIcon);
    expect(categoryIconFor(''), categoryFallbackIcon);
    expect(categoryIconFor('🙂'), categoryFallbackIcon);
    expect(categoryFallbackIcon, isA<IconData>());
  });
}
