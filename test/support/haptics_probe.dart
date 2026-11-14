import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the haptic types the app plays (for example
/// `HapticFeedbackType.selectionClick`) during a test.
///
/// Call it at the top of a test; it resets itself after the test.
List<String> probeHaptics() {
  final List<String> played = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall call,
      ) async {
        if (call.method == 'HapticFeedback.vibrate') {
          played.add(call.arguments as String);
        }
        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  return played;
}
