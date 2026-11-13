import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import 'account_pill.dart';
import 'press_surface.dart';
import 'quick_add_view_models.dart';

/// Transfer accounts: From pill, swap button, To pill (DESIGN.md Q6).
///
/// The swap button turns 180 degrees with `durationMedium` (no turn with
/// reduce motion) and calls [onSwap]. Pills show the balance under the name.
class TransferAccountsRow extends StatefulWidget {
  const TransferAccountsRow({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
    this.swapEnabled = true,
    super.key,
  });

  /// Null until picked (shows "Pick").
  final AccountOption? from;
  final AccountOption? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;
  final bool swapEnabled;

  @override
  State<TransferAccountsRow> createState() => _TransferAccountsRowState();
}

class _TransferAccountsRowState extends State<TransferAccountsRow> {
  // Each swap adds half a turn (180 degrees).
  double _turns = 0;

  void _swap() {
    setState(() => _turns += 0.5);
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Expanded(child: _Caption('From')),
            SizedBox(width: AppSizes.chipHeight),
            Expanded(child: _Caption('To')),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Row(
          children: <Widget>[
            Expanded(
              child: AccountPill(
                account: widget.from,
                placeholder: 'Pick',
                showBalance: true,
                showChevron: false,
                onTap: widget.onPickFrom,
              ),
            ),
            _SwapButton(
              turns: _turns,
              enabled: widget.swapEnabled,
              onTap: _swap,
            ),
            Expanded(
              child: AccountPill(
                account: widget.to,
                placeholder: 'Pick',
                showBalance: true,
                showChevron: false,
                onTap: widget.onPickTo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: AppTextStyles.overline,
    );
  }
}

/// 44 by 44 swap button between the two pills.
class _SwapButton extends StatelessWidget {
  const _SwapButton({
    required this.turns,
    required this.enabled,
    required this.onTap,
  });

  final double turns;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Swap from and to accounts',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: PressSurface(
        enabled: enabled,
        onTap: onTap,
        builder: (BuildContext context, bool pressed) {
          return SizedBox.square(
            dimension: AppSizes.chipHeight,
            child: Center(
              child: AnimatedRotation(
                turns: turns,
                duration: AppMotion.resolve(context, AppMotion.durationMedium),
                curve: AppMotion.curveEnter,
                child: Icon(
                  LucideIcons.arrowLeftRight,
                  size: AppSizes.iconInline,
                  color: enabled ? AppColors.ink : AppColors.iconInactive,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
