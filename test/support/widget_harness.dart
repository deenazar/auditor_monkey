import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone width used by the widget tests (logical pixels).
const double testPhoneWidth = 390;

/// Phone height used by the widget tests (logical pixels).
const double testPhoneHeight = 844;

/// Pumps [child] inside the real app theme on a phone-sized surface.
///
/// [textScale] sets the system text scale (use 2.0 for the large-text check).
/// [reduceMotion] sets "disable animations", as the phone's reduce-motion
/// setting does. [width] narrows the child for overflow checks. [height]
/// gives the child a fixed height (screens need one); null leaves the height
/// to the child (cards, chips and swatches).
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  bool reduceMotion = false,
  double width = testPhoneWidth,
  double? height = testPhoneHeight,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(testPhoneWidth, testPhoneHeight);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? widget) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: widget!,
        );
      },
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  );
}

/// Like [pumpThemed] but the child keeps its own height (for cards, chips
/// and swatches that size themselves).
Future<void> pumpCompact(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  bool reduceMotion = false,
  double width = testPhoneWidth,
}) => pumpThemed(
  tester,
  child,
  textScale: textScale,
  reduceMotion: reduceMotion,
  width: width,
  height: null,
);
