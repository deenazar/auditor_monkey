import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/clock.dart';
import '../../../../shared/scene/sky_phase.dart';
import '../../../../shared/scene/sky_scene.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../transactions_format.dart';
import 'month_summary_chips.dart';

/// The compact sky on top of the Transactions screen (Home's stage, shorter):
/// the title, the demo menu, and the month summary of [month]. [month] is
/// `YYYY-MM` and follows the topmost day group of the list.
class TransactionsStage extends ConsumerWidget {
  const TransactionsStage({required this.month, super.key});

  final ValueListenable<String> month;

  static const List<Shadow> _shadow = <Shadow>[
    Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(
      ref.watch(clockProvider).nowMs(),
    );
    final double top = MediaQuery.paddingOf(context).top + 12;
    return BackdropGroup(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned.fill(
            child: SkyScene(phase: SkyPhase.at(now), cloudTop: top + 40),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: top,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    label: 'Transactions',
                    excludeSemantics: true,
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'YOUR ACTIVITY',
                            style: AppTextStyles.pageEyebrow.copyWith(
                              fontSize: 11,
                              color: AppColors.glassInk,
                              shadows: _shadow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // One line at every text size: scales down instead.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'Transactions',
                              maxLines: 1,
                              style: AppTextStyles.displayTitle.copyWith(
                                color: AppColors.glassInk,
                                shadows: _shadow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const DemoDataMenuButton(glass: true),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 30,
            child: ValueListenableBuilder<String>(
              valueListenable: month,
              builder: (BuildContext context, String m, Widget? _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      monthTitle(m),
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.glassInk,
                        shadows: _shadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MonthSummaryChips(month: m),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
