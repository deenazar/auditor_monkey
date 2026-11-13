import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';

/// Swipe actions on a list row.
///
/// Swipe left past [threshold] deletes: the row collapses (size and fade),
/// then [onDelete] runs. [onDelete] returns `true` when the row is gone; on
/// `false` the row comes back. Swipe right past [threshold] calls [onEdit]
/// and springs back. Both reveal a coloured panel with an icon that grows
/// with the drag, and give one haptic tap at the threshold.
class SwipeRow extends StatefulWidget {
  const SwipeRow({
    required this.child,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Widget child;
  final VoidCallback onEdit;

  /// Deletes the row. `true` once it is removed.
  final Future<bool> Function() onDelete;

  /// Drag distance that counts as a swipe.
  static const double threshold = 96;

  /// The row never moves further than this.
  static const double maxDrag = 140;

  @override
  State<SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<SwipeRow> with TickerProviderStateMixin {
  final ValueNotifier<double> _dx = ValueNotifier<double>(0);
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: AppMotion.durationMedium,
  )..addListener(_onSettle);
  late final AnimationController _collapse = AnimationController(
    vsync: this,
    duration: AppMotion.durationMedium,
    value: 1,
  );
  late final Animation<Offset> _slideOut = Tween<Offset>(
    begin: const Offset(-0.35, 0),
    end: Offset.zero,
  ).animate(_collapse);
  double _from = 0;
  bool _armed = false;
  bool _busy = false;

  @override
  void dispose() {
    _settle.dispose();
    _collapse.dispose();
    _dx.dispose();
    super.dispose();
  }

  void _onSettle() {
    _dx.value = _from * (1 - AppMotion.springy.transform(_settle.value));
  }

  void _settleToRest() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _dx.value = 0;
      return;
    }
    _from = _dx.value;
    _settle.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_busy) return;
    _settle.stop();
    final double next = (_dx.value + details.delta.dx).clamp(
      -SwipeRow.maxDrag,
      SwipeRow.maxDrag,
    );
    _dx.value = next;
    final bool crossed = next.abs() >= SwipeRow.threshold;
    if (crossed && !_armed) {
      _armed = true;
      HapticFeedback.mediumImpact();
    } else if (!crossed) {
      _armed = false;
    }
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_busy) return;
    _armed = false;
    final double x = _dx.value;
    if (x <= -SwipeRow.threshold) {
      await _delete();
    } else if (x >= SwipeRow.threshold) {
      widget.onEdit();
      _settleToRest();
    } else {
      _settleToRest();
    }
  }

  Future<void> _delete() async {
    _busy = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _collapse.value = 0;
    } else {
      await _collapse.reverse();
    }
    if (!mounted) return;
    final bool removed = await widget.onDelete();
    if (!mounted || removed) return;
    // Not removed (for example the delete failed): bring the row back.
    _busy = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _collapse.value = 1;
    } else {
      await _collapse.forward();
    }
    _settleToRest();
  }

  @override
  Widget build(BuildContext context) {
    // Delete: the row fades and slides out (opacity and transform only, no
    // layout change). The list reload then removes it.
    return FadeTransition(
      opacity: _collapse,
      child: SlideTransition(
        position: _slideOut,
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _dx,
                  builder: (BuildContext context, double dx, Widget? _) =>
                      _Reveal(dx: dx),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _dx,
                builder: (BuildContext context, double dx, Widget? child) =>
                    Transform.translate(offset: Offset(dx, 0), child: child),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The coloured panel under a dragged row: teal with a pencil on the left
/// (edit), red with a trash icon on the right (delete).
class _Reveal extends StatelessWidget {
  const _Reveal({required this.dx});

  final double dx;

  @override
  Widget build(BuildContext context) {
    if (dx == 0) return const SizedBox.shrink();
    final bool deleting = dx < 0;
    final double progress = (dx.abs() / SwipeRow.threshold).clamp(0.0, 1.0);
    return ColoredBox(
      color: deleting ? AppColors.danger : AppColors.teal,
      child: Align(
        alignment: deleting
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
          child: Transform.scale(
            scale: 0.5 + 0.5 * progress,
            child: Icon(
              deleting ? LucideIcons.trash2 : LucideIcons.pencil,
              size: AppSizes.iconInline,
              color: AppColors.onDark,
            ),
          ),
        ),
      ),
    );
  }
}
