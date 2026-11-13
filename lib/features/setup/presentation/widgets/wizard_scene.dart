import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_illustration.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../../mascot/presentation/mascot_moment.dart';

/// A wizard step's picture: the step's illustration (pops in with depth)
/// with the Auditor Monkey at its corner, waving and saying [say].
class WizardScene extends StatelessWidget {
  const WizardScene({
    required this.illustration,
    required this.say,
    this.mascot,
    super.key,
  });

  final String illustration;
  final String say;
  final MascotController? mascot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AppIllustration(illustration, size: AppIllustrationSize.wizard),
          Positioned(
            right: -12,
            bottom: -4,
            child: MascotMoment(
              controller: mascot,
              reaction: MascotReaction.hello,
              say: say,
              size: 76,
              halo: false,
            ),
          ),
        ],
      ),
    );
  }
}
