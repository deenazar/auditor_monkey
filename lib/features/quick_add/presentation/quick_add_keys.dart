import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../application/quick_add_notifier.dart';

final Map<LogicalKeyboardKey, String> _digitKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.digit0: '0',
  LogicalKeyboardKey.digit1: '1',
  LogicalKeyboardKey.digit2: '2',
  LogicalKeyboardKey.digit3: '3',
  LogicalKeyboardKey.digit4: '4',
  LogicalKeyboardKey.digit5: '5',
  LogicalKeyboardKey.digit6: '6',
  LogicalKeyboardKey.digit7: '7',
  LogicalKeyboardKey.digit8: '8',
  LogicalKeyboardKey.digit9: '9',
  LogicalKeyboardKey.numpad0: '0',
  LogicalKeyboardKey.numpad1: '1',
  LogicalKeyboardKey.numpad2: '2',
  LogicalKeyboardKey.numpad3: '3',
  LogicalKeyboardKey.numpad4: '4',
  LogicalKeyboardKey.numpad5: '5',
  LogicalKeyboardKey.numpad6: '6',
  LogicalKeyboardKey.numpad7: '7',
  LogicalKeyboardKey.numpad8: '8',
  LogicalKeyboardKey.numpad9: '9',
};

/// Hardware keyboard for the sheet: `0-9`, `.`, Backspace and Enter (Save).
/// Other keys are not handled (so Tab, Escape and system keys still work).
KeyEventResult handleQuickAddKey(KeyEvent event, QuickAddNotifier notifier) {
  if (event is KeyUpEvent) return KeyEventResult.ignored;
  final LogicalKeyboardKey key = event.logicalKey;
  final String? digit = _digitKeys[key];
  if (digit != null) {
    notifier.pressDigit(digit);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.period ||
      key == LogicalKeyboardKey.numpadDecimal) {
    notifier.pressDot();
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.backspace) {
    notifier.backspace();
    return KeyEventResult.handled;
  }
  if (event is KeyDownEvent &&
      (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter)) {
    notifier.save();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
