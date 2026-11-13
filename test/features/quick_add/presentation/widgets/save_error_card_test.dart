import 'package:auditor_monkey/features/quick_add/presentation/widgets/save_error_card.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

Finder _fade() => find.descendant(
  of: find.byType(SaveErrorCard),
  matching: find.byType(Opacity),
);

void main() {
  testWidgets('shows the message with a danger warning icon', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const SaveErrorCard(message: "That account is not available."),
    );
    await tester.pump(AppMotion.durationFast);
    expect(find.text("That account is not available."), findsOneWidget);
    final Icon icon = tester.widget<Icon>(
      find.byIcon(LucideIcons.triangleAlert),
    );
    expect(icon.color, AppColors.danger);
    expect(
      find.bySemanticsLabel("That account is not available."),
      findsOneWidget,
    );
  });

  testWidgets('fades in over durationFast', (WidgetTester tester) async {
    await pumpCompact(tester, const SaveErrorCard(message: 'Failed'));
    expect(tester.widget<Opacity>(_fade()).opacity, 0);
    await tester.pump(AppMotion.durationFast);
    await tester.pump();
    expect(tester.widget<Opacity>(_fade()).opacity, 1);
  });

  testWidgets('reduce motion: fully visible at once', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const SaveErrorCard(message: 'Failed'),
      reduceMotion: true,
    );
    await tester.pump();
    expect(tester.widget<Opacity>(_fade()).opacity, 1);
  });

  testWidgets('long messages wrap at text scale 2.0', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const SaveErrorCard(
        message: 'Something went wrong while saving. Your fields are kept, so you can try again.',
      ),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
