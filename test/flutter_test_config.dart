// Runs once before every test file (flutter_test picks this file up by its
// name). It makes widget and golden tests look like the real app:
//  - loads the Outfit font and the Lucide icon font on purpose (do not rely
//    on automatic font loading; without them text and icons are boxes),
//  - loads a test-only fallback font that has the ₹ sign,
//  - uses a golden comparator that allows 0.5% different pixels, to absorb
//    tiny anti-alias noise only.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';

/// The four Outfit weights, as listed in pubspec.yaml.
const List<String> _outfitFiles = <String>[
  'assets/fonts/outfit/Outfit-Light.ttf',
  'assets/fonts/outfit/Outfit-Regular.ttf',
  'assets/fonts/outfit/Outfit-Medium.ttf',
  'assets/fonts/outfit/Outfit-SemiBold.ttf',
];

/// Font family of the Lucide icons as Flutter names it for a package font
/// (`IconData.fontFamily` is "Lucide", `fontPackage` is the package).
const String _lucideFamily = 'packages/lucide_icons_flutter/Lucide';
const String _lucideAsset = 'packages/lucide_icons_flutter/assets/lucide.ttf';

/// Outfit has no ₹ glyph. On a phone the system font draws it; tests have no
/// system font, so this file stands in (see test/fonts/README.md). Use the
/// family through `fontFamilyFallback` (golden.dart does).
const String _rupeeFallbackFamily = 'RupeeFallback';
const String _rupeeFallbackFile = 'test/fonts/Roboto-Regular.ttf';

Future<void> _loadFont(String family, List<String> assets) async {
  final FontLoader loader = FontLoader(family);
  for (final String asset in assets) {
    final Future<ByteData> bytes = rootBundle.load(asset);
    loader.addFont(bytes);
  }
  await loader.load();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Outfit', _outfitFiles);
  await _loadFont(_lucideFamily, <String>[_lucideAsset]);
  final FontLoader rupee = FontLoader(_rupeeFallbackFamily)
    ..addFont(
      File(_rupeeFallbackFile)
          .readAsBytes()
          .then((Uint8List b) => ByteData.sublistView(b)),
    );
  await rupee.load();
  useToleranceComparator();
  await testMain();
}
