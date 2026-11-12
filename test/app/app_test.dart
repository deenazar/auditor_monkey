import 'package:auditor_monkey/app/app.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _app({bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const ProviderScope(child: AuditorMonkeyApp()),
  );
}

void main() {
  const List<String> labels = <String>[
    'Home',
    'Insights',
    'Transactions',
    'Accounts',
  ];

  testWidgets('nav slots and Quick Add are at least 44x44', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final String label in <String>[...labels, 'Quick Add']) {
      final Size size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
      expect(size.height, greaterThanOrEqualTo(44), reason: label);
    }
    handle.dispose();
  });

  testWidgets('with reduce motion, tab switch shows the screen at once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Accounts'));
    await tester.pump();
    expect(find.text('Your Wallet'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Insights'));
    await tester.pump();
    expect(find.text('Your Spending'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Quick Add'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('active tab icon is ink and only it shows the pill', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    double pillOpacity(String id) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(ValueKey<String>('nav-indicator-$id')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    Color? iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;

    expect(iconColor(LucideIcons.house), AppColors.ink);
    expect(iconColor(LucideIcons.wallet), AppColors.iconInactive);
    expect(pillOpacity('home'), 1);
    expect(pillOpacity('accounts'), 0);

    await tester.tap(find.byIcon(LucideIcons.wallet));
    await tester.pumpAndSettle();

    expect(iconColor(LucideIcons.wallet), AppColors.ink);
    expect(iconColor(LucideIcons.house), AppColors.iconInactive);
    expect(pillOpacity('accounts'), 1);
    expect(pillOpacity('home'), 0);
  });
}
