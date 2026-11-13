import 'package:auditor_monkey/shared/theme/app_depth.dart';
import 'package:auditor_monkey/shared/wow/animated_blobs.dart';
import 'package:auditor_monkey/shared/wow/confetti.dart';
import 'package:auditor_monkey/shared/wow/flip_switcher.dart';
import 'package:auditor_monkey/shared/wow/parallax.dart';
import 'package:auditor_monkey/shared/wow/shimmer.dart';
import 'package:auditor_monkey/shared/wow/spring_press.dart';
import 'package:auditor_monkey/shared/wow/tilt_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  builder: (BuildContext context, Widget? c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: c!,
  ),
  home: Scaffold(body: Center(child: child)),
);

/// Counts haptic calls sent to the platform.
List<String> _recordHaptics(WidgetTester t) {
  final List<String> calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('Tilt3D leans under the finger and springs back', (
    WidgetTester t,
  ) async {
    final List<String> haptics = _recordHaptics(t);
    await t.pumpWidget(
      _app(const Tilt3D(child: SizedBox(width: 200, height: 120))),
    );
    final TestGesture g = await t.startGesture(
      t.getTopLeft(find.byType(Tilt3D)) + const Offset(190, 10),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final Matrix4 m = t
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(Tilt3D),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    expect(m.getRotation().isIdentity(), isFalse);
    await t.pump();
    expect(
      haptics,
      contains('HapticFeedbackType.lightImpact'),
      reason: '$haptics',
    );
    await g.up();
    await t.pumpAndSettle();
    final Matrix4 rest = t
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(Tilt3D),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    expect(rest.getRotation().isIdentity(), isTrue);
  });

  testWidgets('Tilt3D does nothing with reduce motion', (WidgetTester t) async {
    await t.pumpWidget(
      _app(
        const Tilt3D(child: SizedBox(width: 200, height: 120)),
        reduce: true,
      ),
    );
    expect(
      find.descendant(
        of: find.byType(Tilt3D),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('SpringPress: haptic on tap, scales, calls onTap', (
    WidgetTester t,
  ) async {
    final List<String> haptics = _recordHaptics(t);
    int taps = 0;
    await t.pumpWidget(
      _app(
        SpringPress(
          onTap: () => taps++,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    final TestGesture g = await t.startGesture(
      t.getCenter(find.byType(SpringPress)),
    );
    await t.pump(AppDepth.press);
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.92);
    await g.up();
    await t.pumpAndSettle();
    expect(taps, 1);
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
  });

  testWidgets('Confetti inserts an overlay that removes itself', (
    WidgetTester t,
  ) async {
    late BuildContext ctx;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (BuildContext c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    Confetti.burst(ctx, seed: 1);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Confetti draws nothing with reduce motion', (
    WidgetTester t,
  ) async {
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
    Confetti.burst(ctx);
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Shimmer stops after its maximum time', (WidgetTester t) async {
    await t.pumpWidget(
      _app(const Shimmer(child: SizedBox(width: 100, height: 20))),
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    await t.pump(AppDepth.shimmerMax + const Duration(seconds: 1));
    await t.pump();
    expect(find.byType(ShaderMask), findsNothing);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('AnimatedBlobs rest after the scene rest time', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      _app(const SizedBox(width: 300, height: 200, child: AnimatedBlobs())),
    );
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(AppDepth.sceneRestAfter + const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 16));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Parallax moves its child by a share of the scroll', (
    WidgetTester t,
  ) async {
    final ScrollOffset offset = ScrollOffset();
    addTearDown(offset.dispose);
    await t.pumpWidget(
      _app(
        Parallax(
          offset: offset,
          factor: 0.5,
          child: const SizedBox(width: 10, height: 10, key: Key('p')),
        ),
      ),
    );
    final double y0 = t.getTopLeft(find.byKey(const Key('p'))).dy;
    offset.value = 40;
    await t.pump();
    expect(t.getTopLeft(find.byKey(const Key('p'))).dy - y0, closeTo(20, 0.01));
  });

  testWidgets('FlipSwitcher turns the new child in, then settles flat', (
    WidgetTester t,
  ) async {
    Widget host(int i) => _app(
      SizedBox(
        width: 200,
        height: 100,
        child: FlipSwitcher(child: Text('page $i', key: ValueKey<int>(i))),
      ),
    );
    await t.pumpWidget(host(0));
    await t.pumpWidget(host(1));
    await t.pump(AppDepth.flip ~/ 3);
    expect(find.text('page 0'), findsOneWidget);
    expect(find.text('page 1'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
  });
}
