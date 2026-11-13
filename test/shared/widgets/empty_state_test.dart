import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/widgets/empty_state.dart';
import 'package:auditor_monkey/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('shows icon, title and message', (WidgetTester tester) async {
    await pumpThemed(
      tester,
      const EmptyState(
        icon: LucideIcons.wallet,
        title: 'No accounts yet',
        message: 'Add your first account to start.',
      ),
    );
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('Add your first account to start.'), findsOneWidget);
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
  });

  testWidgets('shows the action when given and calls it', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpThemed(
      tester,
      EmptyState(
        title: 'No accounts yet',
        message: 'Set up your accounts.',
        action: PrimaryButton(
          label: 'Set up accounts',
          fullWidth: false,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Set up accounts'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('no icon and no action when not given', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const EmptyState(title: 'Nothing here', message: 'Still empty.'),
    );
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('icon colour can be set (danger for errors)', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const EmptyState(
        icon: LucideIcons.triangleAlert,
        iconColour: AppColors.danger,
        title: 'Oops',
        message: 'Something failed.',
      ),
    );
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.danger);
  });

  testWidgets('large text (2.0) scrolls instead of overflowing', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const EmptyState(
        icon: LucideIcons.wallet,
        title: 'No accounts yet',
        message: 'Add your first account to start, it takes a minute.',
      ),
      textScale: 2,
      width: 240,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
