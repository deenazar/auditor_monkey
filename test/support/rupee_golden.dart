// Golden app with the test-only ₹ fallback font on EVERY text, including
// text with explicit styles (AppTextStyles). Outfit has no ₹; on a phone the
// system font draws it. Wrapping the whole app in a DefaultTextStyle lets
// the fallback reach routes and sheets too. Built on golden.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'golden.dart';

/// [goldenApp] with the ₹ fallback font applied to all text.
Widget rupeeGoldenApp(
  Widget home, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
  bool reduceMotion = true,
}) {
  return DefaultTextStyle(
    style: const TextStyle(fontFamilyFallback: <String>[rupeeFallbackFamily]),
    child: goldenApp(
      home,
      overrides: overrides,
      textScale: textScale,
      reduceMotion: reduceMotion,
    ),
  );
}

/// [pumpGolden] with [rupeeGoldenApp]: settles, then compares with
/// `goldens/<name>.png` next to the test.
Future<void> pumpRupeeGolden(
  WidgetTester tester,
  Widget widget,
  String name, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
}) async {
  setGoldenSurface(tester);
  await tester.pumpWidget(
    rupeeGoldenApp(widget, overrides: overrides, textScale: textScale),
  );
  await tester.pumpAndSettle();
  await expectGolden(tester, name);
}
