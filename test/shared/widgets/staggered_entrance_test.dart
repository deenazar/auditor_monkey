import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/widgets/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
  builder: (BuildContext context, Widget? c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: c!,
  ),
  home: Scaffold(body: child),
);

double _opacity(WidgetTester t, String key) => t
    .widget<Opacity>(
      find.ancestor(of: find.text(key), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  testWidgets('fades and slides up once, then rests at full opacity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const StaggeredEntrance(index: 0, child: Text('a'))),
    );
    expect(_opacity(tester, 'a'), 0);
    await tester.pump(AppMotion.durationMedium ~/ 2);
    final double mid = _opacity(tester, 'a');
    expect(mid, inExclusiveRange(0, 1));
    final double dy = tester.getTopLeft(find.text('a')).dy;
    await tester.pump(AppMotion.durationMedium);
    expect(_opacity(tester, 'a'), 1);
    expect(tester.getTopLeft(find.text('a')).dy, lessThan(dy));
  });

  testWidgets('items wait durationStagger more each, capped at item 8', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: <Widget>[
            StaggeredEntrance(index: 0, child: Text('i0')),
            StaggeredEntrance(index: 3, child: Text('i3')),
            StaggeredEntrance(index: 7, child: Text('i7')),
            StaggeredEntrance(index: 20, child: Text('i20')),
          ],
        ),
      ),
    );
    // 100ms in: item 0 moving, item 3 (120ms delay) not started.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester, 'i0'), greaterThan(0));
    expect(_opacity(tester, 'i3'), 0);
    // Item 7 and item 20 start together (cap = item 8).
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester, 'i7'), _opacity(tester, 'i20'));
    expect(_opacity(tester, 'i7'), greaterThan(0));
    await tester.pump(const Duration(seconds: 1));
    expect(_opacity(tester, 'i20'), 1);
  });

  testWidgets('does not replay when rebuilt', (WidgetTester tester) async {
    Widget build() =>
        _host(const StaggeredEntrance(index: 0, child: Text('a')));
    await tester.pumpWidget(build());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(build());
    expect(_opacity(tester, 'a'), 1);
  });

  testWidgets('reduce motion shows the child at once, no animation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const StaggeredEntrance(index: 5, child: Text('a')), reduce: true),
    );
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('a'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
