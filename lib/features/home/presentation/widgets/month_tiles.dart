import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../../shared/wow/haptics.dart';
import '../../../../shared/wow/long_press_preview.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../../shared/wow/tilt_3d.dart';
import 'dashboard_money.dart';
import 'dashboard_preview.dart';

/// The three compact month tiles on Home: Budget, Remaining and Income.
///
/// Plain data in, no providers. [budget] is null when the month has no
/// budget yet (shows "No budget yet"); [remaining] is null in that case too
/// (shows a dash and "Set a budget (coming soon)"). A negative [remaining]
/// is shown in `danger` with "over budget".
///
/// Every amount rolls ([RollingAmount], keys `dash:budget`, `dash:remaining`,
/// `dash:income`). The row tilts in 3D under the finger and plays a light
/// haptic on touch down (also with reduce motion). Each tile springs on
/// touch and shows a long-press preview with the sum. A tap on Budget calls
/// [onBudgetTap]; the other tiles only preview.
class MonthTiles extends StatelessWidget {
  const MonthTiles({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.income,
    this.onBudgetTap,
    super.key,
  });

  /// This month's budget total in paise, or null when there is no budget.
  final int? budget;

  /// This Month Spent in paise (used in the long-press previews).
  final int spent;

  /// Budget minus all spending in paise, or null when there is no budget.
  final int? remaining;

  /// This month's income in paise.
  final int income;

  /// Called when the Budget tile is tapped. Null makes it a preview only.
  final VoidCallback? onBudgetTap;

  @override
  Widget build(BuildContext context) {
    // The three tiles tilt together. Tilt3D uses a LayoutBuilder, which may
    // not sit under IntrinsicHeight, so the tilt wraps the row and the
    // tiles are plain children. The press haptic is on the row too, so it
    // also plays with reduce motion (where Tilt3D does nothing).
    return Tilt3D(
      haptic: false,
      borderRadius: AppRadius.card,
      child: Listener(
        onPointerDown: (_) => AppHaptics.press(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: _budgetTile()),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: _remainingTile()),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: _incomeTile()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetTile() {
    final int? b = budget;
    return _Tile(
      label: 'BUDGET',
      semantics: b == null
          ? 'Budget: no budget yet'
          : 'Budget, ${formatPaise(b)}',
      preview: b == null
          ? 'No budget yet. Budgets come in a later update.'
          : '${formatPaise(b)} budget − ${formatPaise(spent)} spent',
      onTap: b == null ? null : onBudgetTap,
      value: b == null
          ? const Text('No budget yet', style: _valueStyle, maxLines: 2)
          : RollingAmount(
              paise: b,
              rollKey: 'dash:budget',
              builder: (BuildContext c, int p) =>
                  AmountText(paise: p, style: _valueStyle),
            ),
      caption: b == null ? 'Set one soon' : 'this month',
    );
  }

  Widget _remainingTile() {
    final int? r = remaining;
    final bool over = r != null && r < 0;
    return _Tile(
      label: 'REMAINING',
      semantics: r == null
          ? 'Remaining: no budget'
          : over
          ? 'Remaining: ${minusMoney(r)}, over budget'
          : 'Remaining: ${formatPaise(r)}',
      preview: budget == null
          ? 'Set a budget to see what is left.'
          : '${formatPaise(budget!)} budget − ${formatPaise(spent)} spent',
      value: r == null
          ? const Text('—', style: _valueStyle)
          : RollingAmount(
              paise: r,
              rollKey: 'dash:remaining',
              builder: (BuildContext c, int p) => AmountText(
                paise: p,
                style: _valueStyle,
                color: p < 0 ? AppColors.danger : null,
              ),
            ),
      caption: r == null
          ? 'Set a budget (coming soon)'
          : over
          ? 'over budget'
          : 'left',
    );
  }

  Widget _incomeTile() {
    return _Tile(
      label: 'INCOME',
      semantics: 'Income, ${formatPaise(income)}',
      preview: '${formatPaise(income)} income this month',
      value: RollingAmount(
        paise: income,
        rollKey: 'dash:income',
        builder: (BuildContext c, int p) =>
            AmountText(paise: p, kind: AmountKind.income, style: _valueStyle),
      ),
      caption: 'this month',
    );
  }

  static const TextStyle _valueStyle = AppTextStyles.headline;
}

/// One tile: label, amount and caption on the tile colour, with a spring on
/// touch and a long-press preview.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.semantics,
    required this.preview,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final String label;
  final String semantics;
  final String preview;
  final Widget value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LongPressPreview(
      preview: (BuildContext _) => DashboardPreviewCard(text: preview),
      child: SpringPress(
        onTap: onTap,
        haptic: false,
        semanticLabel: semantics,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.tile,
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.shadowLayered,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label, style: AppTextStyles.overline),
                  const SizedBox(height: AppSpacing.space2),
                  value,
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    caption,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
