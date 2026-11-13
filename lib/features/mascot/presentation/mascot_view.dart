import 'package:flutter/widgets.dart';

import '../domain/mascot_mood.dart';
import 'auditor_monkey.dart';

/// The Auditor Monkey at a fixed width, for screens other than Home (the
/// setup wizard). No sky halo; reacts to touch; rests when idle.
class MascotView extends StatelessWidget {
  /// Creates the mascot [size] wide (the height follows the artwork).
  const MascotView({required this.mood, required this.size, super.key});

  final MascotMood mood;

  /// Width in pt.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      child: AuditorMonkey(mood: mood, size: size, halo: false),
    ),
  );
}
