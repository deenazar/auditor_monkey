import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../wow/haptics.dart';
import 'quick_add_button.dart';

/// Bottom bar: white, no labels, icons only. Five slots in order:
/// Home, Insights, Quick Add (centre), Transactions, Accounts.
///
/// [currentIndex] and [onSelect] use tab indexes 0..3 (the four branches),
/// not slot positions. Quick Add is an action, not a tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelect,
    required this.onQuickAdd,
    super.key,
  });

  /// Bar height without the system bottom inset.
  static const double height = AppSizes.navBarHeight;

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Row(
              children: <Widget>[
                _slot(0, 'Home', LucideIcons.house),
                _slot(1, 'Insights', LucideIcons.chartPie),
                Expanded(
                  child: Center(child: QuickAddButton(onPressed: onQuickAdd)),
                ),
                _slot(2, 'Transactions', LucideIcons.list),
                _slot(3, 'Accounts', LucideIcons.wallet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(int index, String label, IconData icon) {
    return Expanded(
      child: _NavSlot(
        label: label,
        icon: icon,
        indicatorKey: ValueKey<String>('nav-indicator-${label.toLowerCase()}'),
        selected: index == currentIndex,
        onTap: () {
          AppHaptics.tap();
          onSelect(index);
        },
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.label,
    required this.icon,
    required this.indicatorKey,
    required this.selected,
    required this.onTap,
  });

  final Key indicatorKey;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.ink : AppColors.iconInactive;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.space6 + AppSpacing.space2,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          height: AppBottomNav.height,
          width: double.infinity,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Fades always; scales only when reduce motion is off.
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: AppMotion.durationFast,
                  curve: AppMotion.curveEnter,
                  child: AnimatedScale(
                    scale: selected || AppMotion.reduceMotion(context)
                        ? 1
                        : AppSizes.navIndicatorStartScale,
                    duration: AppMotion.resolve(
                      context,
                      AppMotion.durationFast,
                    ),
                    curve: AppMotion.curveEnter,
                    child: DecoratedBox(
                      key: indicatorKey,
                      decoration: const BoxDecoration(
                        color: AppColors.navIndicator,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.radiusPill),
                        ),
                      ),
                      child: const SizedBox(
                        width: AppSizes.navIndicatorWidth,
                        height: AppSizes.navIndicatorHeight,
                      ),
                    ),
                  ),
                ),
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: AppMotion.resolve(context, AppMotion.durationFast),
                  curve: AppMotion.curveEnter,
                  builder: (
                    BuildContext context,
                    Color? value,
                    Widget? child,
                  ) => Icon(icon, size: AppSizes.iconNav, color: value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
