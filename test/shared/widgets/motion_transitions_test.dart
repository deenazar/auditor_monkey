import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/widgets/fade_indexed_stack.dart';
import 'package:auditor_monkey/shared/widgets/shared_axis_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
  builder: (BuildContext context, Widget? c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: c!,
  ),
  home: Scaffold(body: child),
);

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int index = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      TextButton(
        onPressed: () => setState(() => index = 1),
        child: const Text('go'),
      ),
      Expanded(
        child: FadeIndexedStack(
          index: index,
          children: const <Widget>[Text('one'), Text('two')],
        ),
      ),
    ],
  );
}

void main() {
  group('FadeIndexedStack fade-through', () {
    testWidgets('old tab fades out, then the new one fades in and scales', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Tabs()));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(AppMotion.durationFast ~/ 2);
      final Opacity out = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(out.opacity, inExclusiveRange(0, 1));
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

      await tester.pump(AppMotion.durationMedium ~/ 2 + AppMotion.durationFast);
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      final Transform t = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byType(IndexedStack),
              matching: find.byType(Transform),
            )
            .first,
      );
      final double scale = t.transform.storage[0];
      expect(scale, inInclusiveRange(AppMotion.tabFadeScaleFrom, 1));

      await tester.pump(AppMotion.durationMedium);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    });

    testWidgets('reduce motion swaps at once with no scale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Tabs(), reduce: true));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    });
  });

  group('SharedAxisTransition', () {
    Widget axis(AnimationController c, {bool reduce = false}) => _host(
      SharedAxisTransition(animation: c, child: const Text('page')),
      reduce: reduce,
    );

    testWidgets('slides pageSlideOffset while fading in', (
      WidgetTester tester,
    ) async {
      final AnimationController c = AnimationController(
        vsync: const TestVSync(),
        duration: AppMotion.durationMedium,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(axis(c));
      final double rest = tester.getTopLeft(find.text('page')).dx;
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        0,
      );
      expect(rest - 0, greaterThan(0));
      c.value = 0;
      await tester.pump();
      final double start = tester.getTopLeft(find.text('page')).dx;
      c.value = 1;
      await tester.pump();
      final double end = tester.getTopLeft(find.text('page')).dx;
      // The page also swings in on the Y axis (3D), which shifts the
      // projected corner a little; the slide itself is pageSlideOffset.
      expect(start - end, closeTo(AppMotion.pageSlideOffset, 1));
    });

    testWidgets('reduce motion only fades (no movement)', (
      WidgetTester tester,
    ) async {
      final AnimationController c = AnimationController(
        vsync: const TestVSync(),
        duration: AppMotion.durationMedium,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(axis(c, reduce: true));
      c.value = 0.2;
      await tester.pump();
      final double a = tester.getTopLeft(find.text('page')).dx;
      c.value = 1;
      await tester.pump();
      expect(tester.getTopLeft(find.text('page')).dx, a);
    });
  });
}
