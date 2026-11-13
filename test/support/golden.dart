// Helpers for golden (screenshot) tests.
//
// Masters are made ONLY on Linux with Flutter 3.47.9 (a cloud session or
// CI): `flutter test --tags golden --update-goldens`. macOS output differs,
// so never commit goldens made on a Mac. PNGs live next to the tests in a
// `goldens/` folder; failures go to `failures/` (git-ignored, uploaded by
// CI).
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'test_env.dart';

// Family loaded by test/flutter_test_config.dart.
const String rupeeFallbackFamily = 'RupeeFallback';

/// Logical size of every golden: a 390x844 phone at device pixel ratio 2
/// (PNG size 780x1688).
const double goldenWidth = 390;
const double goldenHeight = 844;
const double goldenPixelRatio = 2;

/// The fixed "now" of every golden test: 2026-11-12, noon.
final DateTime goldenNow = DateTime(2026, 11, 12, 12);

/// A clock stuck at [goldenNow].
FakeClock goldenClock() => FakeClock(goldenNow.millisecondsSinceEpoch);

/// Sets the phone-sized surface (resets itself after the test).
void setPhoneSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(
      goldenWidth * goldenPixelRatio,
      goldenHeight * goldenPixelRatio,
    )
    ..devicePixelRatio = goldenPixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// [setPhoneSurface] plus shadows drawn as in the app (flutter_test turns
/// them off by default).
void setGoldenSurface(WidgetTester tester) {
  setPhoneSurface(tester);
  // flutter_test checks that this is back to its default when the test body
  // ends (before tearDown runs), so expectGolden() puts it back.
  debugDisableShadows = false;
}

/// The real theme plus the test-only ₹ fallback font (The app fonts have no ₹; a
/// phone's system font draws it, tests have none).
ThemeData _goldenTheme() {
  final ThemeData theme = AppTheme.light();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      fontFamilyFallback: const <String>[rupeeFallbackFamily],
    ),
  );
}

/// [home] inside the real theme, with the fixed clock, "reduce motion" on
/// (unless [reduceMotion] is false, for motion tests)
/// (so nothing is mid-animation) and the given text scale.
///
/// [overrides] are added after the clock, so a test can replace it.
Widget goldenApp(
  Widget home, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
  bool reduceMotion = true,
}) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(goldenClock()),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _goldenTheme(),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Compares the whole screen with `goldens/<name>.png` (next to the test),
/// then turns the shadow switch back to flutter_test's default. A test that
/// takes a second golden calls [setGoldenSurface] and pumps again first.
Future<void> expectGolden(WidgetTester tester, String name) async {
  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

/// Pumps [widget] on the golden surface, settles, and compares it with
/// `goldens/<name>.png`. [textScale] is 1 except for the large-text case.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget widget,
  String name, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
}) async {
  setGoldenSurface(tester);
  await tester.pumpWidget(
    goldenApp(widget, overrides: overrides, textScale: textScale),
  );
  await tester.pumpAndSettle();
  await expectGolden(tester, name);
}
