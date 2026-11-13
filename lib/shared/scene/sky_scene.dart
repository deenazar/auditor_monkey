import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_motion.dart';
import '../theme/sky_palette.dart';
import 'keyframes.dart';
import 'sky_phase.dart';

/// Wakes the scene's endless loops (clouds, stars). Share one between the
/// sky and anything else on the stage; call [poke] on every touch.
class SceneActivity extends ChangeNotifier {
  void poke() => notifyListeners();
}

/// The illustrated sky behind Home (mimi-world.css `.mw-sky`): a gradient
/// for the time of day, drifting clouds, twinkling stars at night and two
/// soft hills. The phase cross-fades over 1.2 s.
///
/// Clouds drift with a transform-only repaint on one ticker; the ticker
/// rests [AppMotion.sceneRestAfter] after the last [activity] poke, and
/// never runs with reduce motion.
class SkyScene extends StatefulWidget {
  const SkyScene({
    required this.phase,
    this.activity,
    this.cloudTop = 64,
    super.key,
  });

  final SkyPhase phase;
  final SceneActivity? activity;

  /// Where the clouds start (pt from the top; under the date).
  final double cloudTop;

  @override
  State<SkyScene> createState() => _SkySceneState();
}

class _SkySceneState extends State<SkyScene> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.durationSky,
  );
  late SkyColors _from = SkyColors.of(widget.phase);
  late SkyColors _to = _from;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _base = 0;
  double _lastPoke = 0;

  @override
  void initState() {
    super.initState();
    widget.activity?.addListener(_poke);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SkyScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) {
      oldWidget.activity?.removeListener(_poke);
      widget.activity?.addListener(_poke);
    }
    if (oldWidget.phase != widget.phase) {
      _from = SkyColors.lerp(_from, _to, _fade.value);
      _to = SkyColors.of(widget.phase);
      if (MediaQuery.disableAnimationsOf(context)) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    widget.activity?.removeListener(_poke);
    _ticker.dispose();
    _fade.dispose();
    _time.dispose();
    super.dispose();
  }

  static final double _rest = AppMotion.sceneRestAfter.inMilliseconds / 1000;

  void _poke() {
    _lastPoke = _time.value;
    _sync();
  }

  void _sync() {
    final bool run =
        !MediaQuery.disableAnimationsOf(context) &&
        _time.value - _lastPoke < _rest;
    if (run && !_ticker.isActive) {
      _base = _time.value;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _time.value = _base + elapsed.inMicroseconds / 1e6;
    if (_time.value - _lastPoke >= _rest) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SkyPainter(
          time: _time,
          fade: _fade,
          from: () => _from,
          to: () => _to,
          cloudTop: widget.cloudTop,
        ),
        isComplex: true,
        willChange: true,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.time,
    required this.fade,
    required this.from,
    required this.to,
    required this.cloudTop,
  }) : super(repaint: Listenable.merge(<Listenable>[time, fade]));

  final ValueNotifier<double> time;
  final Animation<double> fade;
  final ValueGetter<SkyColors> from;
  final ValueGetter<SkyColors> to;
  final double cloudTop;

  final Paint _paint = Paint()..isAntiAlias = true;

  // 14 stars at fixed spots (seeded, so they do not jump between builds).
  static final List<(double, double, double)> _stars = () {
    final math.Random r = math.Random(14);
    return List<(double, double, double)>.generate(
      14,
      (_) => (
        0.04 + r.nextDouble() * 0.92,
        0.04 + r.nextDouble() * 0.60,
        r.nextDouble() * 3,
      ),
    );
  }();

  // `.mw-cloud.c1..c3`: width, top offset, seconds per crossing, delay,
  // opacity factor.
  static const List<(double, double, double, double, double)> _clouds =
      <(double, double, double, double, double)>[
        (96, 0, 70, -20, 1),
        (52, 54, 95, -60, 1),
        (120, 24, 120, -95, 0.7),
      ];

  static final Keyframes _twinkle = Keyframes(<Stop>[
    (0.5, 1),
  ], curve: Curves.easeInOut);

  @override
  void paint(Canvas canvas, Size size) {
    final SkyColors c = SkyColors.lerp(from(), to(), fade.value);
    final double t = time.value;
    final Rect rect = Offset.zero & size;

    // Gradient.
    _paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[c.top, c.middle, c.bottom],
      stops: const <double>[0, 0.55, 1],
    ).createShader(rect);
    canvas.drawRect(rect, _paint);
    _paint.shader = null;

    // Stars (night): mwTwinkle 3s, each with its own delay.
    if (c.starOpacity > 0) {
      for (final (double x, double y, double delay) in _stars) {
        final double k = _twinkle.loop(t, 3, delay: -delay);
        _paint.color = SkyColors.white.withValues(
          alpha: c.starOpacity * (1 - 0.75 * k),
        );
        canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          1.5 * (1 - 0.4 * k),
          _paint,
        );
      }
    }

    // Clouds: mwDrift from -140 to 110% of the width.
    for (final (double w, double dy, double period, double delay, double o)
        in _clouds) {
      final double p = ((t - delay) / period) % 1;
      final double x = -140 + p * (size.width * 1.1 + 140);
      _paint.color = SkyColors.white.withValues(alpha: c.cloudOpacity * o);
      _drawCloud(canvas, Offset(x, cloudTop + dy), w);
    }

    // Hills: `.mw-hill.h1` (left, back) and `.h2` (right, front).
    _paint.color = c.hillBack;
    canvas.drawOval(
      Rect.fromLTWH(
        -0.18 * size.width,
        size.height - 150 + 60,
        0.78 * size.width,
        150,
      ),
      _paint,
    );
    _paint.color = c.hillFront;
    canvas.drawOval(
      Rect.fromLTWH(
        size.width - 0.66 * size.width,
        size.height - 150 + 74,
        0.90 * size.width,
        150,
      ),
      _paint,
    );
  }

  void _drawCloud(Canvas canvas, Offset at, double w) {
    // A 22pt pill plus two puffs (::before 42% x 30, ::after 36% x 22).
    final Path cloud = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(at.dx, at.dy, w, 22),
          const Radius.circular(22),
        ),
      )
      ..addOval(
        Rect.fromLTWH(at.dx + 0.12 * w, at.dy + 22 - 6 - 30, 0.42 * w, 30),
      )
      ..addOval(
        Rect.fromLTWH(at.dx + 0.42 * w, at.dy + 22 - 6 - 22, 0.36 * w, 22),
      );
    canvas.drawPath(cloud, _paint);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.cloudTop != cloudTop;
}
