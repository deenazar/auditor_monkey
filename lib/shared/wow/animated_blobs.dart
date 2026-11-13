import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';
import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import 'scene_activity.dart';

/// The living mint header: the `primary` fill with soft glowing blobs
/// (lighter / deeper mint, lime, sun) drifting on slow Lissajous paths,
/// and a gentle diagonal light sweep. One ticker, one painter, one
/// RepaintBoundary. Rests [AppDepth.sceneRestAfter] after the last
/// [activity] poke; still with reduce motion.
class AnimatedBlobs extends StatefulWidget {
  const AnimatedBlobs({
    this.activity,
    this.base = AppColors.primary,
    this.borderRadius = BorderRadius.zero,
    this.child,
    super.key,
  });

  final SceneActivity? activity;
  final Color base;
  final BorderRadius borderRadius;
  final Widget? child;

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  double _base = 0;
  double _lastPoke = 0;

  static final double _rest = AppDepth.sceneRestAfter.inMilliseconds / 1000;

  @override
  void initState() {
    super.initState();
    widget.activity?.addListener(_poke);
  }

  @override
  void didUpdateWidget(AnimatedBlobs old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) {
      old.activity?.removeListener(_poke);
      widget.activity?.addListener(_poke);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    widget.activity?.removeListener(_poke);
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  void _poke() {
    _lastPoke = _t.value;
    _sync();
  }

  void _sync() {
    final bool run =
        !AppMotion.reduceMotion(context) && _t.value - _lastPoke < _rest;
    if (run && !_ticker.isActive) {
      _base = _t.value;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    _t.value = _base + elapsed.inMicroseconds / 1e6;
    if (_t.value - _lastPoke >= _rest) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: CustomPaint(
          painter: _BlobPainter(_t, widget.base),
          isComplex: true,
          willChange: true,
          child: widget.child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t, this.base) : super(repaint: t);

  final ValueListenable<double> t;
  final Color base;
  final Paint _p = Paint();

  // (colour, radius share, x speed, y speed, phase)
  static const List<(Color, double, double, double, double)> _blobs =
      <(Color, double, double, double, double)>[
        (AppColors.blobMintLight, 0.55, 0.9, 0.7, 0),
        (AppColors.blobLime, 0.42, 0.6, 1.1, 1.7),
        (AppColors.blobMintDeep, 0.6, 1.2, 0.5, 3.1),
        (AppColors.blobSun, 0.3, 0.7, 0.9, 4.4),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final double s =
        t.value * 2 * math.pi / (AppDepth.blobLoop.inMilliseconds / 1000);
    _p
      ..shader = null
      ..color = base;
    canvas.drawRect(Offset.zero & size, _p);
    final double r0 = math.max(size.width, size.height);
    for (final (Color c, double rs, double sx, double sy, double ph)
        in _blobs) {
      final Offset centre = Offset(
        size.width * (0.5 + 0.38 * math.sin(s * sx + ph)),
        size.height * (0.45 + 0.35 * math.cos(s * sy + ph * 0.7)),
      );
      final double r = r0 * rs;
      _p.shader = RadialGradient(colors: <Color>[c, c.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: centre, radius: r));
      canvas.drawCircle(centre, r, _p);
    }
    // Slow light sweep.
    final double sweep = (math.sin(s * 0.5) + 1) / 2;
    _p.shader = LinearGradient(
      begin: Alignment(-1 + 2 * sweep, -1),
      end: Alignment(sweep, 1),
      colors: const <Color>[
        Color(0x00FFFFFF),
        Color(0x1FFFFFFF),
        Color(0x00FFFFFF),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, _p);
    _p.shader = null;
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.base != base;
}
