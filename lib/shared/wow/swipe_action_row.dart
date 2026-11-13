import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'haptics.dart';

/// One swipe action: what shows behind the row and what it does.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.colour,
    required this.onTrigger,
    this.removesRow = false,
  });

  final IconData icon;
  final String label;
  final Color colour;
  final VoidCallback onTrigger;

  /// True for delete: the row slides away. False (edit, preview): the row
  /// springs back after the action runs.
  final bool removesRow;
}

/// A list row with swipe actions (Motion & 3D layer): swipe left for
/// [end] (e.g. delete), right for [start] (e.g. edit). A `warning`
/// haptic fires as the threshold is crossed. Both actions are also
/// offered to screen readers as custom actions.
class SwipeActionRow extends StatelessWidget {
  const SwipeActionRow({
    required this.id,
    required this.child,
    this.start,
    this.end,
    super.key,
  });

  /// Stable id of the row (used for the Dismissible key).
  final String id;
  final Widget child;
  final SwipeAction? start;
  final SwipeAction? end;

  @override
  Widget build(BuildContext context) {
    final SwipeAction? s = start;
    final SwipeAction? e = end;
    if (s == null && e == null) return child;
    return Dismissible(
      key: ValueKey<String>('swipe-$id'),
      direction: s != null && e != null
          ? DismissDirection.horizontal
          : (e != null
                ? DismissDirection.endToStart
                : DismissDirection.startToEnd),
      dismissThresholds: const <DismissDirection, double>{
        DismissDirection.endToStart: 0.35,
        DismissDirection.startToEnd: 0.35,
      },
      onUpdate: (DismissUpdateDetails d) {
        if (d.reached && !d.previousReached) AppHaptics.warning();
      },
      confirmDismiss: (DismissDirection d) async {
        final SwipeAction? a = d == DismissDirection.endToStart ? e : s;
        if (a == null) return false;
        if (!a.removesRow) {
          a.onTrigger();
          return false;
        }
        return true;
      },
      onDismissed: (DismissDirection d) {
        final SwipeAction? a = d == DismissDirection.endToStart ? e : s;
        a?.onTrigger();
      },
      background: s == null ? const SizedBox.shrink() : _Back(s, start: true),
      secondaryBackground: e == null ? null : _Back(e, start: false),
      child: Semantics(
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          if (s != null) CustomSemanticsAction(label: s.label): s.onTrigger,
          if (e != null) CustomSemanticsAction(label: e.label): e.onTrigger,
        },
        child: child,
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back(this.action, {required this.start});
  final SwipeAction action;
  final bool start;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: action.colour,
    child: Align(
      alignment: start
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Icon(action.icon, color: AppColors.onDark),
      ),
    ),
  );
}
