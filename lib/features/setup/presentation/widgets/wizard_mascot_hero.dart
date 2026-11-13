import 'package:flutter/material.dart';

import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/wow/animated_blobs.dart';
import '../../../../shared/wow/scene_activity.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/auditor_monkey.dart';
import '../../../mascot/presentation/mascot_controller.dart';

/// The wizard's welcome hero: the living mint blob header with the 2.5D
/// Auditor Monkey, who waves hello once and follows your finger.
class WizardMascotHero extends StatefulWidget {
  const WizardMascotHero({super.key});

  /// Monkey width.
  static const double size = 168;

  @override
  State<WizardMascotHero> createState() => _WizardMascotHeroState();
}

class _WizardMascotHeroState extends State<WizardMascotHero> {
  final MascotController _monkey = MascotController();
  final SceneActivity _activity = SceneActivity();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _monkey.react(MascotReaction.hello, text: "Hi! I'll keep the books");
      }
    });
  }

  @override
  void dispose() {
    _monkey.dispose();
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent e) {
        _activity.poke();
        _monkey.follow(e.position);
      },
      onPointerMove: (PointerMoveEvent e) => _monkey.follow(e.position),
      child: AnimatedBlobs(
        activity: _activity,
        borderRadius: AppRadius.hero,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
              child: Center(
                child: AuditorMonkey(
                  controller: _monkey,
                  mood: MascotMood.idle,
                  size: WizardMascotHero.size,
                ),
              ),
            ),
            // Top start, so the monkey's hello bubble never covers it.
            const Align(
              alignment: AlignmentDirectional.topStart,
              child: DemoDataMenuButton(),
            ),
          ],
        ),
      ),
    );
  }
}
