import 'package:flutter/widgets.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// Path of the mascot model (see DESIGN.md, Mascot).
const String mascotModelAsset = 'assets/3d/monkey.glb';

/// Tiny wrapper over the 3D controller, so the view can be tested.
abstract class MascotPlayer {
  /// Clip names found in the model.
  Future<List<String>> availableClips();

  /// Plays [clip]; [loops] 0 means loop forever.
  void play(String clip, {int loops});
}

/// Builds the 3D viewer. Calls [onReady] once the model has loaded and
/// [onError] if it fails. Tests override this with a fake.
typedef MascotViewerFactory = Widget Function({
  required void Function(MascotPlayer player) onReady,
  required void Function(String error) onError,
});

class _ControllerPlayer implements MascotPlayer {
  _ControllerPlayer(this._controller);

  final Flutter3DController _controller;

  @override
  Future<List<String>> availableClips() => _controller.getAvailableAnimations();

  @override
  void play(String clip, {int loops = 0}) =>
      _controller.playAnimation(animationName: clip, loopCount: loops);
}

/// The real viewer (a WebView inside; mobile only).
Widget defaultMascotViewer({
  required void Function(MascotPlayer player) onReady,
  required void Function(String error) onError,
}) {
  final Flutter3DController controller = Flutter3DController();
  return Flutter3DViewer(
    src: mascotModelAsset,
    controller: controller,
    // Taps are handled by MascotView, not the model.
    enableTouch: false,
    onLoad: (_) => onReady(_ControllerPlayer(controller)),
    onError: onError,
  );
}
