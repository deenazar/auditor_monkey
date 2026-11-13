import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'golden.dart';

/// Pumps [home] in the real theme on a phone-sized surface (390x844 at 2x),
/// with the fixed clock. Use it for screen tests; [overrides] replace
/// providers, and [textScale] and [reduceMotion] match the phone settings.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const <Override>[],
  double textScale = 1,
  bool reduceMotion = true,
}) async {
  setPhoneSurface(tester);
  await tester.pumpWidget(
    goldenApp(
      home,
      overrides: overrides,
      textScale: textScale,
      reduceMotion: reduceMotion,
    ),
  );
  await tester.pump();
}
