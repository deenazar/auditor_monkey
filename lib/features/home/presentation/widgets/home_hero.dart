import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../../shared/wow/animated_blobs.dart';
import '../../../../shared/wow/parallax.dart';
import '../../../../shared/wow/scene_activity.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/auditor_monkey.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import 'hero_area_chart.dart';

/// The mint hero (reference screen 1): greeting, `overline` label, the net
/// worth in `displayAmount` (rolls), and the spending area chart, on a
/// living blob gradient. The Auditor Monkey stands at the bottom right.
/// Its layers move at different speeds when the page scrolls (parallax).
class HomeHero extends StatelessWidget {
  const HomeHero({
    required this.netWorth,
    required this.chart,
    required this.mood,
    required this.sleepyHour,
    required this.monkey,
    required this.activity,
    required this.scroll,
    super.key,
  });

  final int? netWorth;
  final List<int> chart;
  final MascotMood mood;
  final bool sleepyHour;
  final MascotController monkey;
  final SceneActivity activity;
  final ScrollOffset scroll;

  /// Hero height below the status bar.
  static const double height = 330;

  /// How far the summary card overlaps the hero's bottom edge.
  static const double overlap = 44;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBlobs(
              activity: activity,
              borderRadius: AppRadius.hero,
            ),
          ),
          Positioned(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: top + AppSpacing.space4,
            child: Parallax(
              offset: scroll,
              factor: AppDepth.parallaxMid,
              fadeOver: 220,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(width: 44),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              const TextSpan(text: 'Hello '),
                              TextSpan(
                                text: 'there',
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title,
                        ),
                      ),
                      const SizedBox(width: 44, child: DemoDataMenuButton()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space5),
                  Text(
                    'NET WORTH',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  if (netWorth == null)
                    const SizedBox(height: 44)
                  else
                    RollingAmount.text(
                      paise: netWorth!,
                      style: AppTextStyles.displayAmount,
                      rollKey: 'home-net-worth',
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: overlap + 6,
            child: Parallax(
              offset: scroll,
              factor: AppDepth.parallaxBack,
              child: HeroAreaChart(values: chart),
            ),
          ),
          Positioned(
            right: AppSpacing.space4,
            bottom: overlap - 8,
            child: AuditorMonkey(
              controller: monkey,
              mood: mood,
              size: 92,
              sleepyHour: sleepyHour,
              halo: false,
            ),
          ),
        ],
      ),
    );
  }
}
