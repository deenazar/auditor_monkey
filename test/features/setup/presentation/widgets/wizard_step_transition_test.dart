import 'package:auditor_monkey/features/setup/presentation/widgets/wizard_step_transition.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int step = 0;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              TextButton(
                onPressed: () => setState(() => step++),
                child: const Text('next'),
              ),
              TextButton(
                onPressed: () => setState(() => step--),
                child: const Text('back'),
              ),
            ],
          ),
          Expanded(
            child: WizardStepTransition(
              step: step,
              child: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: Text('step $step'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _x(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text)).dx;

void main() {
  testWidgets('forward: the new step slides in 24pt from the right', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const _Host(), reduceMotion: false));
    final double rest = _x(tester, 'step 0');

    await tester.tap(find.text('next'));
    await tester.pump(); // start
    // Entering step 1 starts 24pt to the right; step 0 starts at rest.
    expect(_x(tester, 'step 1') - rest, closeTo(AppSpacing.space6, 0.5));
    expect(_x(tester, 'step 0'), closeTo(rest, 0.5));

    await tester.pump(AppMotion.durationMedium ~/ 2);
    final double mid = _x(tester, 'step 1') - rest;
    expect(mid, inExclusiveRange(0, AppSpacing.space6));
    // The old step moves left while it fades.
    expect(_x(tester, 'step 0'), lessThan(rest));

    await tester.pumpAndSettle();
    expect(find.text('step 0'), findsNothing);
    expect(_x(tester, 'step 1'), closeTo(rest, 0.5));
  });

  testWidgets('back: the previous step comes in from the left', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const _Host(), reduceMotion: false));
    final double rest = _x(tester, 'step 0');
    await tester.tap(find.text('next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pump();
    expect(_x(tester, 'step 0') - rest, closeTo(-AppSpacing.space6, 0.5));
    await tester.pumpAndSettle();
    expect(find.text('step 1'), findsNothing);
  });

  testWidgets('reduce motion: fade only, no movement', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const _Host()));
    final double rest = _x(tester, 'step 0');
    await tester.tap(find.text('next'));
    await tester.pump();
    await tester.pump(AppMotion.durationFast ~/ 2);
    expect(_x(tester, 'step 1'), closeTo(rest, 0.01));
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('step 0'), findsNothing);
  });

  testWidgets('the leaving step ignores taps', (WidgetTester tester) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const _Host(), reduceMotion: false));
    await tester.tap(find.text('next'));
    await tester.pump();
    await tester.pump(AppMotion.durationMedium ~/ 4);
    final Finder old = find.text('step 0');
    expect(old, findsOneWidget);
    expect(
      find
          .ancestor(of: old, matching: find.byType(IgnorePointer))
          .evaluate()
          .any((Element e) => (e.widget as IgnorePointer).ignoring),
      isTrue,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('a rebuild with the same step does not animate', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(const _Host(), reduceMotion: false));
    await tester.pumpWidget(goldenApp(const _Host(), reduceMotion: false));
    expect(find.text('step 0'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
