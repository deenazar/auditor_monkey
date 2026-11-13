import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_toast.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/success_check.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({bool reduce = false, bool check = true}) => MaterialApp(
  builder: (BuildContext context, Widget? c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: c!,
  ),
  home: Scaffold(
    body: QuickAddToastContent(message: 'Expense saved', showCheck: check),
  ),
);

void main() {
  testWidgets('check pops from successPopFrom to 1 over durationSlow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host());
    Transform t() => tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(SuccessCheck),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(t().transform.storage[0], closeTo(AppMotion.successPopFrom, 0.001));
    await tester.pump(AppMotion.durationSlow ~/ 2);
    expect(
      t().transform.storage[0],
      inExclusiveRange(AppMotion.successPopFrom, 1),
    );
    await tester.pump(AppMotion.durationSlow);
    expect(t().transform.storage[0], closeTo(1, 0.001));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduce motion draws the finished check, no scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(reduce: true));
    expect(
      find.descendant(
        of: find.byType(SuccessCheck),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('no check unless asked; check is excluded from semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(check: false));
    expect(find.byType(SuccessCheck), findsNothing);
    await tester.pumpWidget(_host());
    expect(
      find.ancestor(
        of: find.byType(CustomPaint),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}
