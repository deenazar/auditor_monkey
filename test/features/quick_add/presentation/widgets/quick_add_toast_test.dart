import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_toast.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

void main() {
  test('the SnackBar lasts toastDuration and floats with space6 margin', () {
    final SnackBar bar = buildQuickAddToast(message: 'Expense saved');
    expect(bar.duration, AppMotion.toastDuration);
    expect(bar.behavior, SnackBarBehavior.floating);
    expect(bar.margin, const EdgeInsets.all(24));
  });

  testWidgets('content shows the message on primaryDeep with onDark text', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const QuickAddToastContent(message: 'Expense saved · ₹250.00'),
    );
    expect(find.text('Expense saved · ₹250.00'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    final Text text = tester.widget<Text>(find.text('Expense saved · ₹250.00'));
    expect(text.style?.color, AppColors.onDark);
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(QuickAddToastContent),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, AppColors.primaryDeep);
  });

  testWidgets('Undo is a 44 tap target and calls back', (
    WidgetTester tester,
  ) async {
    int undo = 0;
    await pumpCompact(
      tester,
      QuickAddToastContent(message: 'Entry removed', onUndo: () => undo++),
    );
    expect(
      tester.getSize(find.bySemanticsLabel('Undo')).height,
      AppSizes.chipHeight,
    );
    await tester.tap(find.text('Undo'));
    expect(undo, 1);
  });

  testWidgets('the SnackBar built by the helper shows its Undo action', (
    WidgetTester tester,
  ) async {
    int undo = 0;
    await pumpCompact(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            buildQuickAddToast(
              message: 'Expense saved · ₹250.00',
              onUndo: () => undo++,
            ),
          ),
          child: const Text('show'),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Expense saved · ₹250.00'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undo, 1);
  });

  testWidgets('text scale 2.0: the message wraps, Undo stays visible', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      QuickAddToastContent(
        message: 'Transfer saved · ₹2,000.00 from SBI to Axis',
        onUndo: () {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Undo'), findsOneWidget);
  });
}
