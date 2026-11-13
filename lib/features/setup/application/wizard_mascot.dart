import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mascot/presentation/mascot_controller.dart';

/// The setup wizard's Auditor Monkey: one controller shared by the steps,
/// so the monkey reacts to picks, typing and saving (Motion & 3D layer).
/// Lives while the wizard is on screen.
final Provider<MascotController> wizardMascotProvider =
    Provider.autoDispose<MascotController>((Ref ref) {
      final MascotController c = MascotController();
      ref.onDispose(c.dispose);
      return c;
    });
