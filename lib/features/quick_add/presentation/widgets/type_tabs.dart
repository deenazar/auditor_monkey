import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../transactions/domain/transaction_entry.dart';

/// Expense / Income / Transfer segmented control (DESIGN.md "Segmented tabs").
///
/// A `tile` pill track, `chipHeight` tall. The selected segment is a
/// `primaryDeep` pill with an `onDark` label; the indicator slides with
/// `durationFast` and `curveEnter`. With reduce motion it jumps (zero
/// duration from [AppMotion.resolve]).
///
/// Transfer is disabled when [transferEnabled] is false (fewer than two
/// accounts): it reads "Transfer, needs two accounts". Tapping it keeps the
/// current tab, shows [disabledHint] under the tabs (it fades in) and calls
/// [onDisabledTap].
class TypeTabs extends StatefulWidget {
  const TypeTabs({
    required this.selected,
    required this.onChanged,
    this.transferEnabled = true,
    this.onDisabledTap,
    this.disabledHint = 'Add a second account to move money between accounts.',
    super.key,
  });

  final TransactionType selected;

  /// Called with the tab the user picked (not called for the selected tab).
  final ValueChanged<TransactionType> onChanged;

  /// False when Transfer needs a second account.
  final bool transferEnabled;

  /// Called when the disabled Transfer tab is tapped.
  final VoidCallback? onDisabledTap;

  /// Text shown under the tabs after a tap on the disabled Transfer tab.
  final String disabledHint;

  @override
  State<TypeTabs> createState() => _TypeTabsState();
}

/// Gap between the sliding pill and the track edge (logical pixels).
const double _indicatorInset = 2;

const List<TransactionType> _order = <TransactionType>[
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
];

String _labelOf(TransactionType type) => switch (type) {
  TransactionType.expense => 'Expense',
  TransactionType.income => 'Income',
  TransactionType.transfer => 'Transfer',
};

class _TypeTabsState extends State<TypeTabs> {
  bool _showHint = false;

  @override
  void didUpdateWidget(TypeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new tab or a second account clears the hint.
    if (oldWidget.selected != widget.selected || widget.transferEnabled) {
      _showHint = false;
    }
  }

  void _tap(TransactionType type) {
    final bool disabled =
        type == TransactionType.transfer && !widget.transferEnabled;
    if (disabled) {
      setState(() => _showHint = true);
      widget.onDisabledTap?.call();
      return;
    }
    if (type != widget.selected) widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    final int index = _order.indexOf(widget.selected);
    final Duration duration = AppMotion.resolve(
      context,
      AppMotion.durationFast,
    );

    // The indicator is one slot wide; it slides to the selected slot.
    final Widget indicator = AnimatedAlign(
      alignment: _alignFor(index),
      duration: duration,
      curve: AppMotion.curveEnter,
      child: FractionallySizedBox(
        widthFactor: 1 / _order.length,
        heightFactor: 1,
        child: const Padding(
          padding: EdgeInsets.all(_indicatorInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: AppRadius.pill,
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: AppSizes.chipHeight,
          decoration: const BoxDecoration(
            color: AppColors.tile,
            borderRadius: AppRadius.pill,
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: indicator),
              Row(
                children: <Widget>[
                  for (final TransactionType type in _order)
                    Expanded(child: _segment(type)),
                ],
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          child: _showHint && !widget.transferEnabled
              ? Padding(
                  key: const ValueKey<String>('type-tabs-hint'),
                  padding: const EdgeInsets.only(top: AppSpacing.space2),
                  child: Text(
                    widget.disabledHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey<String>('no-type-hint')),
        ),
      ],
    );
  }

  /// Three equal slots across the track: -1, 0 and 1.
  static Alignment _alignFor(int index) => Alignment(index - 1.0, 0);

  Widget _segment(TransactionType type) {
    final bool selected = type == widget.selected;
    final bool disabled =
        type == TransactionType.transfer && !widget.transferEnabled;
    final String label = _labelOf(type);
    final Color colour = selected
        ? AppColors.onDark
        : disabled
        ? AppColors.iconInactive
        : AppColors.ink;
    final TextStyle style =
        (selected ? AppTextStyles.bodyStrong : AppTextStyles.body).copyWith(
          color: colour,
        );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: !disabled || widget.onDisabledTap != null,
      label: disabled ? '$label, needs two accounts' : label,
      excludeSemantics: true,
      onTap: () => _tap(type),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(type),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: style),
            ),
          ),
        ),
      ),
    );
  }
}
