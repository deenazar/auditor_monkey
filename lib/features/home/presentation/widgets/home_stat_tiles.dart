import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../../shared/wow/tilt_3d.dart';

/// Home's two stat tiles (reference screen 2): "SPENDINGS" as pill bars
/// for the last days (latest in `sun`, others `primary` / `lime`) and
/// "SAVINGS" as a ring with the share of income kept. Bars grow and the
/// ring draws in ([AppDepth.chartDraw]); both tilt under the finger.
class HomeStatTiles extends StatelessWidget {
  const HomeStatTiles({
    required this.days,
    required this.savingsPercent,
    super.key,
  });

  /// Spending per day, oldest first.
  final List<int> days;
  final int? savingsPercent;

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final int saved = (savingsPercent ?? 0).clamp(0, 100);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Tilt3D(
            child: Semantics(
              label: 'Spendings, last ${days.length} days',
              excludeSemantics: true,
              child: StatTile(
                label: 'SPENDINGS',
                child: SizedBox(
                  height: 72,
                  child: _Grow(
                    reduce: reduce,
                    builder: (double p) =>
                        CustomPaint(painter: _BarsPainter(days, p)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Tilt3D(
            child: Semantics(
              label: savingsPercent == null
                  ? 'Savings: no income yet'
                  : 'Savings: $savingsPercent percent of income',
              excludeSemantics: true,
              child: StatTile(
                label: 'SAVINGS',
                child: SizedBox(
                  height: 72,
                  child: _Grow(
                    reduce: reduce,
                    builder: (double p) => CustomPaint(
                      painter: _RingPainter(saved / 100 * p),
                      child: Center(
                        child: Text(
                          savingsPercent == null ? '–' : '$savingsPercent%',
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Grow extends StatelessWidget {
  const _Grow({required this.reduce, required this.builder});
  final bool reduce;
  final Widget Function(double progress) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
    duration: reduce ? Duration.zero : AppDepth.chartDraw,
    curve: AppDepth.draw,
    builder: (BuildContext context, double p, Widget? _) => builder(p),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.progress);
  final List<int> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final int top = values.reduce(math.max);
    const double w = AppSizes.chartBarWidth;
    final double gap = values.length < 2
        ? 0
        : (size.width - w * values.length) / (values.length - 1);
    final Paint p = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < values.length; i++) {
      final double share = top <= 0 ? 0.08 : math.max(0.08, values[i] / top);
      final double h = size.height * share * progress;
      final double x = i * (w + gap) + w / 2;
      p
        ..color = i == values.length - 1
            ? AppColors.sun
            : (i.isEven ? AppColors.primary : AppColors.lime)
        ..strokeWidth = w;
      final double mid = size.height / 2;
      canvas.drawLine(
        Offset(x, mid - h / 2 + w / 2),
        Offset(x, mid + h / 2 - w / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress || old.values != values;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.share);
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = math.min(size.width, size.height) / 2 - 6;
    final Offset c = size.center(Offset.zero);
    final double thickness = r * 0.25 * 2;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AppColors.divider;
    canvas.drawCircle(c, r, track);
    if (share <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * share,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.share != share;
}
