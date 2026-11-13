import 'package:auditor_monkey/features/mascot/domain/mascot_mood.dart';
import 'package:auditor_monkey/features/mascot/presentation/auditor_monkey.dart';
import 'package:auditor_monkey/features/mascot/presentation/mascot_controller.dart';
import 'package:auditor_monkey/features/mascot/presentation/mascot_view.dart';
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
  testWidgets('say shows the bubble, then hides it', (WidgetTester t) async {
    final MascotController c = MascotController();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(AuditorMonkey(controller: c)));
    c.say('Hello there', duration: const Duration(milliseconds: 500));
    await t.pump();
    expect(c.bubble.value, 'Hello there');
    expect(find.text('Hello there'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 600));
    expect(c.bubble.value, isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('react with text speaks; loops rest after 15 s', (
    WidgetTester t,
  ) async {
    final MascotController c = MascotController();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(AuditorMonkey(controller: c)));
    c.react(MascotReaction.add, text: 'Logged ₹10.00');
    await t.pump(const Duration(milliseconds: 100));
    expect(c.bubble.value, 'Logged ₹10.00');
    expect(t.hasRunningAnimations, isTrue);
    // Settles once the reaction, the talking and the idle loops finish.
    await t.pumpAndSettle(const Duration(milliseconds: 500));
    expect(t.hasRunningAnimations, isFalse);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduce motion: no ticker, moods and bubbles still work', (
    WidgetTester t,
  ) async {
    final MascotController c = MascotController();
    addTearDown(c.dispose);
    await t.pumpWidget(
      _app(
        AuditorMonkey(controller: c, mood: MascotMood.worried),
        reduce: true,
      ),
    );
    expect(t.hasRunningAnimations, isFalse);
    c.react(MascotReaction.win, text: 'Yay');
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
    expect(c.bubble.value, 'Yay');
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('taps react by zone and six fast taps make it dizzy', (
    WidgetTester t,
  ) async {
    final MascotController c = MascotController();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(AuditorMonkey(controller: c, size: 160)));
    final Finder m = find.byType(AuditorMonkey);
    final Offset topLeft = t.getTopLeft(m);
    // Tail (right, lower half).
    await t.tapAt(topLeft + const Offset(140, 120));
    await t.pump(const Duration(milliseconds: 50));
    expect(<String>[
      'Hey! Not my tail! 🙊',
      'Hmph!',
      'Mind the tail!',
    ], contains(c.bubble.value));
    await t.pump(const Duration(seconds: 3));
    for (int i = 0; i < 6; i++) {
      await t.tapAt(topLeft + const Offset(80, 60));
      await t.pump(const Duration(milliseconds: 400));
    }
    expect(c.bubble.value, 'Whoa… so dizzy 😵‍💫');
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('MascotView keeps its square size and a label', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      _app(const MascotView(mood: MascotMood.idle, size: 180), reduce: true),
    );
    expect(t.getSize(find.byType(MascotView)), const Size(180, 180));
    expect(find.bySemanticsLabel(RegExp('Auditor Monkey')), findsOneWidget);
  });
}
