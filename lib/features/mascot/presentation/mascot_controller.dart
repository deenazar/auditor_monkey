import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../domain/mascot_mood.dart';

/// What a screen can ask of the monkey (mimi-world.js `say` / `react` /
/// `look` / `type`). One controller drives one [AuditorMonkey].
class MascotController {
  MascotHost? _host;

  /// The speech bubble's text (null when hidden). A screen that wants the
  /// bubble above other content (the home stage) shows it itself.
  final ValueNotifier<String?> bubble = ValueNotifier<String?>(null);

  /// Shows [text] in the bubble for [duration] and moves the mouth.
  void say(
    String text, {
    Duration duration = const Duration(milliseconds: 2600),
  }) => _host?.say(text, duration);

  /// Plays a one-shot reaction, optionally saying [text].
  void react(MascotReaction reaction, {String? text}) =>
      _host?.react(reaction, text);

  /// Turns the eyes towards [direction] (any length) for 3.5 s.
  void look(Offset direction) => _host?.look(direction);

  /// Wakes the monkey and its loops (call on any touch nearby).
  void poke() => _host?.poke();

  /// Ears perk up for a moment, like when typing.
  void type() => _host?.type();

  void dispose() => bubble.dispose();
}

/// Implemented by the monkey's state.
abstract interface class MascotHost {
  void say(String text, Duration duration);
  void react(MascotReaction reaction, String? text);
  void look(Offset direction);
  void poke();
  void type();

  /// Attaches [host] to [controller] (null detaches).
  static void attach(MascotController controller, MascotHost? host) =>
      controller._host = host;
}
