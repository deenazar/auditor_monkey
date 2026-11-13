import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/clock.dart';
import '../../../../shared/scene/sky_phase.dart';
import '../../../../shared/scene/sky_scene.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/auditor_monkey.dart';
import '../../../mascot/presentation/mascot_controller.dart';

/// The wizard's welcome hero: Home's sky for the time of day with the
/// Auditor Monkey, who waves hello once. Demo data button top left (debug builds).
class WizardSkyHero extends ConsumerStatefulWidget {
  const WizardSkyHero({super.key});

  /// Monkey width on the welcome step.
  static const double monkeySize = 164;

  @override
  ConsumerState<WizardSkyHero> createState() => _WizardSkyHeroState();
}

class _WizardSkyHeroState extends ConsumerState<WizardSkyHero> {
  final MascotController _monkey = MascotController();
  final SceneActivity _activity = SceneActivity();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _monkey.react(MascotReaction.hello, text: "Hi! I'll keep the books 📋");
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
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(
      ref.watch(clockProvider).nowMs(),
    );
    final SkyPhase phase = SkyPhase.at(now);
    final double top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: AppRadius.hero,
      child: Listener(
        onPointerDown: (_) => _activity.poke(),
        child: SizedBox(
          height: top + WizardSkyHero.monkeySize * 176 / 160 + 56,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: SkyScene(
                  phase: phase,
                  activity: _activity,
                  cloudTop: top + 24,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: AuditorMonkey(
                    controller: _monkey,
                    mood: MascotMood.idle,
                    size: WizardSkyHero.monkeySize,
                    phase: phase,
                  ),
                ),
              ),
              Positioned(
                top: top + 10,
                left: 14,
                child: const DemoDataMenuButton(glass: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
