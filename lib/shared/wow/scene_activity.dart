import 'package:flutter/foundation.dart';

/// Wakes endless header loops (blobs, mascot) when the user touches the
/// screen. Loops rest [AppDepth.sceneRestAfter] after the last poke, so a
/// still screen costs no battery.
class SceneActivity extends ChangeNotifier {
  void poke() => notifyListeners();
}
