import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/app_illustration.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../../shared/wow/long_press_preview.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../../shared/wow/tilt_3d.dart';
import 'dashboard_preview.dart';

/// One row of the Top spending card. Plain data, built by the screen from
/// the Dashboard summary (`TopCategoryShare` plus the category's name and
/// icon).
class TopSpendingItem {
  const TopSpendingItem({
    required this.categoryId,
    required this.name,
    required this.iconName,
    required this.colourGroup,
    required this.amount,
    required this.percent,
  });

  /// Passed back to [TopSpendingCard.onOpenCategory].
  final String categoryId;

  /// Category name, e.g. `Groceries`.
  final String name;

  /// Lucide icon name in kebab case, e.g. `shopping-cart`.
  final String iconName;

  /// Stored colour group, e.g. `essentials`.
  final String colourGroup;

  /// Spending in the category this month (paise).
  final int amount;

  /// Whole percent of this month's spending, 0 to 100.
  final int percent;
}

/// "Top spending": the three biggest categories of this month.
///
/// Each row shows the category icon, name, amount and percent, and a pill
/// bar that grows in, one row after the other (transform only, the bar
/// length is its share of spending). Tap calls [onOpenCategory] with the
/// category id; long-press shows a preview. With no items it shows the
/// `empty_top_spending` illustration and a short line.
///
/// Reduce motion: the bars are full at once. The card tilts under the
/// finger like the other Home cards.
/// Delay between two rows' bar starts, as a share of the sweep.
const double _staggerShare = 0.2;

/// Height of a pill bar, in pt.
const double _barHeight = 8;

class TopSpendingCard extends StatefulWidget {
  const TopSpendingCard({
    required this.items,
    required this.onOpenCategory,
    super.key,
  });

  /// At most three rows, biggest first.
  final List<TopSpendingItem> items;

  /// Called with the category id when a row is tapped.
  final ValueChanged<String> onOpenCategory;

  @override
  State<TopSpendingCard> createState() => _TopSpendingCardState();
}

class _TopSpendingCardState extends State<TopSpendingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: AppDepth.chartDraw,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _grow.value = 1;
    } else {
      _grow.forward();
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tilt3D(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.tile,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.shadowLayered,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Top spending', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.space3),
              if (widget.items.isEmpty)
                _empty()
              else
                for (int i = 0; i < widget.items.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.space3),
                  _row(context, i, widget.items[i]),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => const Column(
    children: <Widget>[
      AppIllustration('empty_top_spending'),
      SizedBox(height: AppSpacing.space2),
      Text(
        'No spending this month yet',
        style: AppTextStyles.caption,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _row(BuildContext context, int index, TopSpendingItem item) {
    final String label =
        '${item.name}, ${formatPaise(item.amount)}, ${item.percent}% of spending';
    return SpringPress(
      onTap: () => widget.onOpenCategory(item.categoryId),
      onLongPress: () => LongPressPreview.show(
        context,
        (BuildContext _) => DashboardPreviewCard(text: label),
      ),
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            CategoryIconCircle(
              iconName: item.iconName,
              colourGroup: item.colourGroup,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.bodyStrong,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      AmountText(
                        paise: item.amount,
                        style: AppTextStyles.bodyStrong,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Row(
                    children: <Widget>[
                      Expanded(child: _bar(index, item.percent)),
                      const SizedBox(width: AppSpacing.space2),
                      Text('${item.percent}%', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A pill track with a fill of [percent] of its length. The fill grows
  /// from the left with a transform (scaleX), staggered by [index].
  Widget _bar(int index, int percent) {
    final double share = (percent / 100).clamp(0.0, 1.0);
    final double start = (index * _staggerShare).clamp(0.0, 0.6);
    final Animation<double> grow = CurvedAnimation(
      parent: _grow,
      curve: Interval(start, 1, curve: AppDepth.draw),
    );
    return SizedBox(
      height: _barHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.divider,
          borderRadius: AppRadius.pill,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: share,
          child: AnimatedBuilder(
            animation: grow,
            builder: (BuildContext context, Widget? child) => Transform.scale(
              scaleX: grow.value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.pill,
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
