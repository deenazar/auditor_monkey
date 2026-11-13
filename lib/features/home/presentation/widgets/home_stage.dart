import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/scene/sky_phase.dart';
import '../../../../shared/scene/sky_scene.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/sky_palette.dart';
import '../../../../shared/widgets/glass_icon_button.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/auditor_monkey.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../domain/home_format.dart';
import '../../domain/home_summary.dart';
import 'stat_chip.dart';
import 'week_bars.dart';

/// The top of Home (mini_checklist `.stage`): the sky, the big date and
/// glass buttons, the monkey beside the week's bars, and the stat chips.
/// [collapse] (0..1) fades the scene as the panel slides up.
class HomeStage extends StatelessWidget {
  const HomeStage({
    required this.summary,
    required this.budgetTotal,
    required this.selected,
    required this.phase,
    required this.sleepyHour,
    required this.mood,
    required this.monkey,
    required this.activity,
    required this.collapse,
    required this.onPick,
    required this.onClearPick,
    required this.onAccounts,
    super.key,
  });

  final HomeSummary summary;
  final int budgetTotal;
  final String? selected;
  final SkyPhase phase;
  final bool sleepyHour;
  final MascotMood mood;
  final MascotController monkey;
  final SceneActivity activity;
  final ValueListenable<double> collapse;
  final ValueChanged<String> onPick;
  final VoidCallback onClearPick;
  final VoidCallback onAccounts;

  /// Space from the scene's bottom to the stage's bottom (chips + panel).
  static const double sceneBottom = 74;

  /// Space under the date for the scene.
  static const double sceneTopGap = 52;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top + 12;
    final String shown = selected ?? summary.today;
    final int left = summary.monthLeft(budgetTotal);
    final int? savings = summary.savingsPercent;
    return BackdropGroup(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned.fill(
            child: SkyScene(
              phase: phase,
              activity: activity,
              cloudTop: top + 52,
            ),
          ),
          // Scene: the monkey and the week.
          Positioned(
            left: 14,
            right: 14,
            top: top + sceneTopGap,
            bottom: sceneBottom,
            child: ValueListenableBuilder<double>(
              valueListenable: collapse,
              builder: (BuildContext context, double cp, Widget? child) {
                final double o = (1 - cp * 1.7).clamp(0.0, 1.0);
                return IgnorePointer(
                  ignoring: o < 0.4,
                  child: Opacity(
                    opacity: o,
                    child: Transform.translate(
                      offset: Offset(0, -14 * cp),
                      child: child,
                    ),
                  ),
                );
              },
              child: _Scene(
                summary: summary,
                selected: selected,
                phase: phase,
                sleepyHour: sleepyHour,
                mood: mood,
                monkey: monkey,
                onPick: onPick,
              ),
            ),
          ),
          // Top HUD: the date and buttons.
          Positioned(
            left: 14,
            right: 14,
            top: top,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _DateBlock(
                    date: shown,
                    isToday: shown == summary.today,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    if (selected != null)
                      GlassIconButton(
                        label: 'Recent',
                        icon: LucideIcons.history,
                        semanticLabel: 'Show recent entries',
                        onTap: onClearPick,
                      ),
                    GlassIconButton(
                      icon: LucideIcons.landmark,
                      semanticLabel: 'Open accounts',
                      onTap: onAccounts,
                    ),
                    const DemoDataMenuButton(glass: true),
                  ],
                ),
              ],
            ),
          ),
          // Bottom HUD: stat chips.
          Positioned(
            left: 14,
            right: 14,
            bottom: 30,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                StatChip(
                  value: compactRupees(summary.todaySpent),
                  label: 'Today spent',
                ),
                StatChip(
                  value: compactRupees(left),
                  label: budgetTotal > 0 ? 'Budget left' : 'Month left',
                  valueColour: left < 0
                      ? AppColors.todayBarTop
                      : AppColors.glassInk,
                ),
                StatChip(
                  value: savings == null ? '–' : '$savings%',
                  label: 'Savings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.isToday});

  final String date;
  final bool isToday;

  static const List<Shadow> _shadow = <Shadow>[
    Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label:
          '${isToday ? 'Today, ' : ''}${weekdayLong(date)} '
          '${dayNumber(date)} ${monthYear(date)}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            dayNumber(date),
            style: AppTextStyles.dateNumber.copyWith(shadows: _shadow),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    weekdayLong(date).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTextStyles.pageEyebrow.copyWith(
                      height: 1,
                      color: AppColors.glassInk,
                      shadows: _shadow,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    monthYear(date),
                    maxLines: 1,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      height: 1.1,
                      color: AppColors.glassInk.withValues(alpha: 0.9),
                      shadows: _shadow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The monkey on the left, the week bars on the right, centred together.
/// A Stack (not a Row) so the speech bubble paints over the bars.
class _Scene extends StatelessWidget {
  const _Scene({
    required this.summary,
    required this.selected,
    required this.phase,
    required this.sleepyHour,
    required this.mood,
    required this.monkey,
    required this.onPick,
  });

  final HomeSummary summary;
  final String? selected;
  final SkyPhase phase;
  final bool sleepyHour;
  final MascotMood mood;
  final MascotController monkey;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double mh = math.min(c.maxHeight, 172);
        final double mw = mh * 160 / 176;
        final double gap = (c.maxWidth * 0.04).clamp(10, 28);
        final double bw = math.max(0, math.min(236, c.maxWidth - mw - gap));
        final double bh = math.min(c.maxHeight, 150);
        final double start = (c.maxWidth - mw - gap - bw) / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (bw > 120)
              Positioned(
                left: start + mw + gap,
                width: bw,
                bottom: 0,
                height: bh,
                child: WeekBars(
                  days: summary.week,
                  today: summary.today,
                  selected: selected,
                  onPick: onPick,
                  tint: SkyColors.of(phase).glassPanel,
                ),
              ),
            Positioned(
              left: start,
              bottom: 0,
              width: mw,
              height: mh,
              child: AuditorMonkey(
                controller: monkey,
                mood: mood,
                size: mw,
                sleepyHour: sleepyHour,
                phase: phase,
              ),
            ),
          ],
        );
      },
    );
  }
}
