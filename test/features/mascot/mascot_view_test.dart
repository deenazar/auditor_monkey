import 'package:auditor_monkey/features/mascot/application/mascot_player.dart';
import 'package:auditor_monkey/features/mascot/application/mascot_providers.dart';
import 'package:auditor_monkey/features/mascot/domain/mascot_mood.dart';
import 'package:auditor_monkey/features/mascot/presentation/mascot_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _FakePlayer implements MascotPlayer {
  _FakePlayer(this.clips);

  final List<String> clips;
  final List<(String, int)> played = <(String, int)>[];

  @override
  Future<List<String>> availableClips() async => clips;

  @override
  void play(String clip, {int loops = 0}) => played.add((clip, loops));
}

Widget _app(
  MascotMood mood, {
  List<Override> overrides = const <Override>[],
  bool reduce = false,
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    builder: (BuildContext context, Widget? c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: c!,
    ),
    home: Scaffold(
      body: Center(child: MascotView(mood: mood, size: 160)),
    ),
  ),
);

/// Frames for: first frame, visibility report, build viewer, load, fade.
Future<void> _frames(WidgetTester tester) async {
  for (int i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  group('poster only (tests, reduce motion)', () {
    testWidgets('poster mode builds no 3D viewer and has the label', (
      WidgetTester tester,
    ) async {
      int built = 0;
      await tester.pumpWidget(
        _app(
          MascotMood.idle,
          overrides: <Override>[
            mascotPosterOnlyProvider.overrideWithValue(true),
            mascotViewerFactoryProvider.overrideWithValue(({
              required onReady,
              required onError,
            }) {
              built++;
              return const SizedBox();
            }),
          ],
        ),
      );
      await tester.pump();
      expect(built, 0);
      expect(
        find.bySemanticsLabel('Auditor Monkey, tap to say hi'),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(MascotView)), const Size(160, 160));
    });

    testWidgets('reduce motion shows the poster only', (
      WidgetTester tester,
    ) async {
      int built = 0;
      await tester.pumpWidget(
        _app(
          MascotMood.idle,
          reduce: true,
          overrides: <Override>[
            mascotPosterOnlyProvider.overrideWithValue(false),
            mascotViewerFactoryProvider.overrideWithValue(({
              required onReady,
              required onError,
            }) {
              built++;
              return const SizedBox();
            }),
          ],
        ),
      );
      await _frames(tester);
      expect(built, 0);
    });

    testWidgets('tap gives a light haptic', (WidgetTester tester) async {
      final List<String> haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        _app(
          MascotMood.idle,
          overrides: <Override>[
            mascotPosterOnlyProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.tap(find.byType(MascotView));
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
    });
  });

  group('3D viewer (fake)', () {
    late _FakePlayer player;
    int built = 0;

    List<Override> factory(List<String> clips) {
      // (the poster-only default is true under flutter test)
      player = _FakePlayer(clips);
      built = 0;
      return <Override>[
        mascotPosterOnlyProvider.overrideWithValue(false),
        mascotViewerFactoryProvider.overrideWithValue(({
          required onReady,
          required onError,
        }) {
          built++;
          Future<void>.microtask(() => onReady(player));
          return const SizedBox(key: ValueKey('viewer'));
        }),
      ];
    }

    testWidgets('built only after the first frame, plays the mood clip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MascotMood.worried,
          overrides: factory(<String>['idle', 'worried', 'happy']),
        ),
      );
      // First frame: nothing built yet.
      expect(built, 0);
      await _frames(tester);
      expect(find.byKey(const ValueKey('viewer')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(player.played.last, ('worried', 0));
    });

    testWidgets('a missing clip falls back to idle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(MascotMood.sleeping, overrides: factory(<String>['idle'])),
      );
      await _frames(tester);
      expect(player.played.last.$1, 'idle');
    });

    testWidgets('tap plays happy once, then returns to the mood', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(MascotMood.idle, overrides: factory(<String>['idle', 'happy'])),
      );
      await _frames(tester);
      player.played.clear();
      await tester.tap(find.byType(MascotView));
      await tester.pump();
      expect(player.played.single, ('happy', 1));
      await tester.pump(mascotHappyDuration + const Duration(milliseconds: 10));
      expect(player.played.last, ('idle', 0));
    });

    testWidgets('unmounts the viewer when the app goes to background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(MascotMood.idle, overrides: factory(<String>['idle'])),
      );
      await _frames(tester);
      expect(find.byKey(const ValueKey('viewer')), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(find.byKey(const ValueKey('viewer')), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _frames(tester);
      expect(find.byKey(const ValueKey('viewer')), findsOneWidget);
    });

    testWidgets('an error keeps the poster and drops the viewer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MascotMood.idle,
          overrides: <Override>[
            mascotPosterOnlyProvider.overrideWithValue(false),
            mascotViewerFactoryProvider.overrideWithValue(({
              required onReady,
              required onError,
            }) {
              Future<void>.microtask(() => onError('boom'));
              return const SizedBox(key: ValueKey('viewer'));
            }),
          ],
        ),
      );
      await _frames(tester);
      expect(find.byKey(const ValueKey('viewer')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
