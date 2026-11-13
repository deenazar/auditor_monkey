import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mascot_player.dart';

/// When true the mascot always shows its still poster.
///
/// It is true under `flutter test` (the 3D WebView cannot render there, and
/// whole-app tests must not build it). A mascot test that wants the viewer
/// overrides this with false and gives a fake [mascotViewerFactoryProvider].
final Provider<bool> mascotPosterOnlyProvider = Provider<bool>(
  (Ref ref) => Platform.environment.containsKey('FLUTTER_TEST'),
);

/// Builds the 3D viewer. Tests override it with a fake.
final Provider<MascotViewerFactory> mascotViewerFactoryProvider =
    Provider<MascotViewerFactory>((Ref ref) => defaultMascotViewer);
