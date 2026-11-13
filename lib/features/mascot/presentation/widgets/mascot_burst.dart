import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/scene/keyframes.dart';
import '../../../../shared/theme/app_colors.dart';

/// Short-lived overlay effects: the star burst (mwBurst) and hearts where
/// the monkey is stroked (mwHeart). Each removes itself when done.
abstract final class MascotBurst {
  /// [count] stars flying out from [global] (a tap or the monkey).
  static void stars(
    BuildContext context,
    Offset global,
    int count,
    math.Random random,
  ) {
    final List<_Particle> parts = List<_Particle>.generate(count, (int i) {
      final double a = i / count * math.pi * 2 + random.nextDouble() * 0.5;
      final double r = 26 + random.nextDouble() * 34;
      return _Particle(
        Offset(math.cos(a) * r, math.sin(a) * r),
        AppColors.confetti[i % AppColors.confetti.length],
      );
    });
    _show(
      context,
      const Duration(milliseconds: 800),
      (double t) => Positioned.fill(
        child: CustomPaint(painter: _StarsPainter(global, parts, t)),
      ),
    );
  }

  /// One emoji heart floating up from [global].
  static void heart(
    BuildContext context,
    Offset global,
    String glyph,
    math.Random random,
  ) {
    final double dx = (random.nextDouble() - 0.5) * 60;
    _show(context, const Duration(milliseconds: 1300), (double t) {
      // mwHeart: pop in by 15%, then drift up 90 and fade.
      final double pop = t < 0.15 ? 0.4 + 0.6 * (t / 0.15) : 1 + 0.1 * t;
      final double fade = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
      final double rise = Curves.easeOut.transform(t);
      return Positioned(
        left: global.dx - 11 + dx * rise,
        top: global.dy - 11 - 90 * rise,
        child: Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: pop,
            child: Text(glyph, style: const TextStyle(fontSize: 20)),
          ),
        ),
      );
    });
  }

  static void _show(
    BuildContext context,
    Duration duration,
    Widget Function(double t) builder,
  ) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _OneShot(
          duration: duration,
          builder: builder,
          onDone: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _Particle {
  const _Particle(this.to, this.colour);
  final Offset to;
  final Color colour;
}

class _OneShot extends StatefulWidget {
  const _OneShot({
    required this.duration,
    required this.builder,
    required this.onDone,
  });

  final Duration duration;

  /// Must return a [Positioned] (it goes straight into a [Stack]).
  final Widget Function(double t) builder;
  final VoidCallback onDone;

  @override
  State<_OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<_OneShot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward().whenComplete(() => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (BuildContext context, Widget? _) =>
        Stack(children: <Widget>[widget.builder(_c.value)]),
  );
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.origin, this.parts, this.t);

  final Offset origin;
  final List<_Particle> parts;
  final double t;

  static final Path _star = () {
    final Path p = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? 7 : 3.2;
      final double a = -math.pi / 2 + i * math.pi / 5;
      final Offset o = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }();

  @override
  void paint(Canvas canvas, Size size) {
    // mwBurst .8s cubic-bezier(.2,.8,.3,1): from scale .3 to the target,
    // spinning 160°, fading after 60%.
    final double e = const Cubic(0.2, 0.8, 0.3, 1).transform(t);
    final double alpha = t < 0.6 ? 1 : 1 - (t - 0.6) / 0.4;
    final Paint paint = Paint();
    for (final _Particle p in parts) {
      paint.color = p.colour.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(origin.dx + p.to.dx * e, origin.dy + p.to.dy * e);
      canvas.rotate(deg(160) * e);
      canvas.scale(0.3 + 0.7 * e);
      canvas.drawPath(_star, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.t != t;
}
