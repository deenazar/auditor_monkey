import 'package:auditor_monkey/shared/wow/depth_turn.dart';
import 'package:auditor_monkey/shared/wow/shake_in.dart';
import 'package:auditor_monkey/shared/wow/swipe_action_row.dart';
import 'package:auditor_monkey/shared/wow/wow_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  builder: (BuildContext context, Widget? c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: c!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a swipe action that keeps the row runs and springs back', (
    WidgetTester t,
  ) async {
    int edits = 0;
    await t.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: SwipeActionRow(
            id: 'a',
            start: SwipeAction(
              icon: Icons.edit,
              label: 'Edit',
              colour: Colors.green,
              onTrigger: () => edits++,
            ),
            child: const SizedBox(height: 60, child: Text('row')),
          ),
        ),
      ),
    );
    await t.drag(find.text('row'), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(edits, 1);
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('a removing swipe action dismisses the row', (
    WidgetTester t,
  ) async {
    int deletes = 0;
    bool shown = true;
    await t.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter set) => _app(
          SizedBox(
            width: 300,
            child: shown
                ? SwipeActionRow(
                    id: 'b',
                    end: SwipeAction(
                      icon: Icons.delete,
                      label: 'Delete',
                      colour: Colors.red,
                      removesRow: true,
                      onTrigger: () => set(() {
                        deletes++;
                        shown = false;
                      }),
                    ),
                    child: const SizedBox(height: 60, child: Text('row')),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
    await t.drag(find.text('row'), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(deletes, 1);
    expect(find.text('row'), findsNothing);
  });

  testWidgets('DepthTurn turns on a key change and settles flat', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(_app(const DepthTurn(turnKey: 1, child: Text('x'))));
    expect(
      find.descendant(
        of: find.byType(DepthTurn),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await t.pumpWidget(_app(const DepthTurn(turnKey: 2, child: Text('x'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(
      find.descendant(
        of: find.byType(DepthTurn),
        matching: find.byType(Transform),
      ),
      findsWidgets,
    );
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DepthTurn),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('ShakeIn shakes once; nothing moves with reduce motion', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(_app(const ShakeIn(child: Text('oops'))));
    await t.pump(const Duration(milliseconds: 60));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    await t.pumpWidget(_app(const ShakeIn(child: Text('oops2')), reduce: true));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('sheets open at once with reduce motion', (WidgetTester t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (BuildContext c) {
            ctx = c;
            return const SizedBox();
          },
        ),
        reduce: true,
      ),
    );
    expect(wowSheetAnimation(ctx).duration, Duration.zero);
  });
}
