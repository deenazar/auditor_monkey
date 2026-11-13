import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';

/// The hero's area chart (DESIGN.md Charts, "Area"): a smooth 2pt `onDark`
/// line over a `primaryLight` → transparent fill, a filled dot on the
/// latest point, no axes. It draws in from left to right
/// ([AppDepth.chartDraw]) and morphs when values change. Reduce motion:
/// drawn at once.
class HeroAreaChart extends StatelessWidget {
  const HeroAreaChart({required this.values, this.height = 96, super.key});

  /// Oldest first (paise or any unit).
  final List<int> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: 'Spending over the last ${values.length} days',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
          duration: reduce ? Duration.zero : AppDepth.chartDraw,
          curve: AppDepth.draw,
          builder: (BuildContext context, double p, Widget? _) =>
              CustomPaint(painter: _AreaPainter(values, p)),
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.values, this.progress);

  final List<int> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final int top = values.reduce(math.max);
    const double pad = 8;
    List<Offset> pts = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          6 + (size.width - 12) * i / (values.length - 1),
          pad +
              (size.height - pad * 2) *
                  (1 - (top <= 0 ? 0.5 : values[i] / top * 0.9 + 0.05)),
        ),
    ];
    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final Offset a = pts[i - 1];
      final Offset b = pts[i];
      final double mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    // Draw-in: clip to the drawn share of the width.
    final double w = size.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w + 6, size.height));
    final Path fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.onDark,
    );
    canvas.restore();
    // Latest point dot once the line reaches it.
    if (progress > 0.97) {
      final Offset last = pts.last;
      canvas.drawCircle(last, 4.5, Paint()..color = AppColors.onDark);
    }
    pts = const <Offset>[];
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.progress != progress || old.values != values;
}
