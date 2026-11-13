import 'package:flutter/material.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';

/// A check mark inside a circle. On first show the strokes draw in over
/// `durationSlow` with a scale pop `successPopFrom` to 1 (`curveEnter`).
/// With reduce motion it is drawn complete at once. Decorative.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({required this.color, this.size = 24, super.key});

  final Color color;
  final double size;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) return;
    final AnimationController c = AnimationController(
      vsync: this,
      duration: AppMotion.durationSlow,
    );
    _controller = c;
    _curve = CurvedAnimation(parent: c, curve: AppMotion.curveEnter);
    c.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double>? anim = _curve;
    Widget paint(double p) => CustomPaint(
      size: Size.square(widget.size),
      painter: _CheckPainter(widget.color, p),
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: anim == null
              ? paint(1)
              : AnimatedBuilder(
                  animation: anim,
                  builder: (BuildContext context, Widget? _) => Transform.scale(
                    scale:
                        AppMotion.successPopFrom +
                        (1 - AppMotion.successPopFrom) * anim.value,
                    child: paint(anim.value),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color, this.progress);

  final Color color;

  /// 0..1: the circle draws first (60%), then the tick.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.progressStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double r = size.width / 2 - paint.strokeWidth / 2;
    final Path circle = Path()
      ..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: r));
    final Path tick = Path()
      ..moveTo(size.width * 0.30, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.70, size.height * 0.36);
    canvas
      ..drawPath(_part(circle, (progress / 0.6).clamp(0, 1)), paint)
      ..drawPath(_part(tick, ((progress - 0.5) / 0.5).clamp(0, 1)), paint);
  }

  Path _part(Path path, double fraction) {
    if (fraction >= 1) return path;
    final Path out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
