import 'package:flutter/widgets.dart';

import '../domain/mascot_mood.dart';
import 'auditor_monkey.dart';
import 'mascot_controller.dart';

/// The 2.5D Auditor Monkey at a fixed square size (wizard, empty states).
/// Reacts to touch; endless loops rest when nothing happens.
class MascotView extends StatelessWidget {
  /// Creates the mascot [size] x [size].
  const MascotView({
    required this.mood,
    required this.size,
    this.controller,
    this.halo = true,
    super.key,
  });

  final MascotMood mood;

  /// Width and height in pt.
  final double size;
  final MascotController? controller;
  final bool halo;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      child: AuditorMonkey(
        mood: mood,
        size: size,
        halo: halo,
        controller: controller,
      ),
    ),
  );
}
