import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/parallax.dart';
import '../../../../shared/wow/scene_activity.dart';
import '../../../../shared/wow/wow_header.dart';
import '../../../demo_data/presentation/demo_data_menu_button.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_moment.dart';
import '../transactions_format.dart';
import 'month_summary_chips.dart';

/// The living header of the Transactions screen (`WowHeader`: blobs, parallax
/// title, Auditor Monkey) with the month summary of [month] under the title.
/// [month] is `YYYY-MM` and follows the topmost day group of the list.
class TransactionsHeader extends StatelessWidget {
  const TransactionsHeader({
    required this.month,
    required this.scroll,
    required this.activity,
    super.key,
  });

  static const double _monkeySize = 48;

  final ValueListenable<String> month;
  final ScrollOffset scroll;
  final SceneActivity activity;

  @override
  Widget build(BuildContext context) {
    return WowHeader(
      eyebrow: 'Your Activity',
      title: 'Transactions',
      scroll: scroll,
      activity: activity,
      leading: const DemoDataMenuButton(),
      bottom: ValueListenableBuilder<String>(
        valueListenable: month,
        builder: (BuildContext context, String m, Widget? _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The monkey sits beside the month name (a spacer balances it).
            Row(
              children: <Widget>[
                const SizedBox(width: _monkeySize),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      monthTitle(m),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong,
                    ),
                  ),
                ),
                const MascotMoment(
                  reaction: MascotReaction.hello,
                  size: _monkeySize,
                  halo: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            MonthSummaryChips(month: m),
          ],
        ),
      ),
    );
  }
}
