import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../../../../shared/scene/keyframes.dart';
import '../../../../shared/theme/sky_palette.dart';
import 'monkey_pose.dart';

/// Colours of the monkey artwork (one place, like Mimi's inline SVG).
abstract final class MonkeyInk {
  static const Color outline = Color(0xFF2A2420);
  static const Color furLight = Color(0xFFC08A5E);
  static const Color furDark = Color(0xFF8A5634);
  static const Color face = Color(0xFFF8DDBF);
  static const Color earInner = Color(0xFFF2B49A);
  static const Color blush = Color(0xFFFF8FA8);
  static const Color mouth = Color(0xFFE8556E);
  static const Color tie = Color(0xFFFF6B4A);
  static const Color board = Color(0xFFA9683C);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color clip = Color(0xFFC9D3D8);
  static const Color tick = Color(0xFF5DB82E);
  static const Color lens = Color(0x40FFFFFF);
  static const Color sweat = Color(0xFF7CC6FF);
  static const Color star = Color(0xFFFFC24D);
  static const Color zz = Color(0xFFFFFFFF);
}

/// Draws the Auditor Monkey in Mimi's flat SVG style: thick dark outline,
/// soft fur gradient, round glasses and a clipboard. Works in a 160 x 176
/// view box (Mimi's), scaled to fit. All motion comes from [pose].
class MonkeyPainter extends CustomPainter {
  MonkeyPainter({required this.pose, required this.sky, super.repaint});

  /// Filled by the widget every frame.
  final MonkeyPose pose;

  /// Halo colours (sun by day, moon at night) and whether it is night.
  final ValueGetter<(SkyColors, bool)> sky;

  static const double viewW = 160;
  static const double viewH = 176;

  // Paints reused every frame (no allocations while animating).
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Shader? _fur;
  final Path _path = Path();

  static final Path _tailPath = Path()
    ..moveTo(116, 146)
    ..cubicTo(152, 142, 158, 104, 138, 92)
    ..cubicTo(126, 86, 118, 98, 128, 104);

  static final Path _star = _starPath();

  static Path _starPath() {
    final Path p = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? 1 : 0.45;
      final double a = -math.pi / 2 + i * math.pi / 5;
      final Offset o = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(size.width / viewW, size.height / viewH);
    canvas.save();
    canvas.translate(
      (size.width - viewW * scale) / 2,
      (size.height - viewH * scale) / 2,
    );
    canvas.scale(scale);
    _fur ??= const RadialGradient(
      center: Alignment(-0.2, -0.4),
      radius: 0.9,
      colors: <Color>[MonkeyInk.furLight, MonkeyInk.furDark],
    ).createShader(const Rect.fromLTWH(0, 0, viewW, viewH));

    if (pose.halo) _paintHalo(canvas);
    _paintGroundShadow(canvas);

    // Whole figure: reactions (jump, hop, shake, dance, spin) from the
    // bottom centre, like `.mw-figure{transform-origin:50% 100%}`.
    canvas.save();
    canvas.translate(viewW / 2, viewH);
    canvas.translate(0, pose.figureDy);
    canvas.rotate(pose.figureRotation);
    canvas.scale(pose.figureScaleX, pose.figureScaleY);
    canvas.translate(-viewW / 2, -viewH);

    _paintTail(canvas);
    _paintBody(canvas);
    _paintHead(canvas);
    canvas.restore();

    if (pose.sleep > 0) _paintZz(canvas);
    if (pose.dizzy > 0) _paintDizzy(canvas);
    canvas.restore();
  }

  // ---- Sky bits ----

  void _paintHalo(Canvas canvas) {
    final (SkyColors c, bool night) = sky();
    // `.mw-halo`: 74% wide circle, top -6%, floating 6px every 8 s.
    const double r = viewW * 0.74 / 2;
    final Offset centre = Offset(
      viewW / 2,
      -viewH * 0.06 + r - 6 * pulse(pose.seconds, 8),
    );
    _fill
      ..shader = null
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..color = c.orbGlow;
    canvas.drawCircle(centre, r + 20, _fill);
    _fill
      ..maskFilter = null
      ..color = c.orb.withValues(alpha: 0.10);
    canvas.drawCircle(centre, r + 26, _fill);
    _fill.color = c.orb.withValues(alpha: 0.25);
    canvas.drawCircle(centre, r + 12, _fill);
    _fill.color = c.orb.withValues(alpha: 0.95);
    canvas.drawCircle(centre, r, _fill);
    if (night) {
      // The moon's shaded edge (`inset -14px -6px 0 #D9D3BD`).
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: centre, radius: r)),
      );
      _path
        ..reset()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: centre, radius: r))
        ..addOval(
          Rect.fromCircle(center: centre.translate(-14, -6), radius: r),
        );
      _fill.color = SkyColors.moonShade;
      canvas.drawPath(_path, _fill);
      _path.fillType = PathFillType.nonZero;
      canvas.restore();
    }
  }

  void _paintGroundShadow(Canvas canvas) {
    _fill
      ..shader = null
      ..color = SkyColors.groundShadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final double shrink = (pose.figureDy / -40).clamp(0.0, 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(viewW / 2, viewH * 1.0),
        width: viewW * 0.6 * (1 - shrink),
        height: viewH * 0.09 * (1 - shrink),
      ),
      _fill,
    );
    _fill.maskFilter = null;
  }

  // ---- Monkey ----

  void _outline(Canvas canvas, Path path, [double width = 3]) {
    _stroke
      ..shader = null
      ..color = MonkeyInk.outline
      ..strokeWidth = width;
    canvas.drawPath(path, _stroke);
  }

  void _furFill(Canvas canvas, Path path) {
    _fill
      ..color = MonkeyInk.furDark
      ..shader = _fur;
    canvas.drawPath(path, _fill);
    _fill.shader = null;
  }

  void _solid(Canvas canvas, Path path, Color colour) {
    _fill
      ..shader = null
      ..color = colour;
    canvas.drawPath(path, _fill);
  }

  Path _oval(double cx, double cy, double rx, double ry) => _path
    ..reset()
    ..addOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    );

  void _paintTail(Canvas canvas) {
    canvas.save();
    canvas.translate(116, 146);
    canvas.rotate(pose.tailRotation);
    canvas.translate(-116, -146);
    _stroke
      ..shader = null
      ..color = MonkeyInk.outline
      ..strokeWidth = 15;
    canvas.drawPath(_tailPath, _stroke);
    _stroke
      ..color = MonkeyInk.furDark
      ..shader = _fur
      ..strokeWidth = 9;
    canvas.drawPath(_tailPath, _stroke);
    _stroke.shader = null;
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    canvas.save();
    canvas.translate(pose.purr.dx, pose.purr.dy);
    // mwBreath from (80,166).
    canvas.translate(80, 166);
    canvas.scale(pose.breathX, pose.breathY);
    canvas.translate(-80, -166);

    _furFill(canvas, _oval(80, 130, 42, 36));
    _outline(canvas, _path);
    _solid(canvas, _oval(80, 138, 26, 22), MonkeyInk.face);

    // Feet.
    _furFill(canvas, _oval(62, 162, 13, 8));
    _outline(canvas, _path);

    // Right paw: waves (mwWave lifts it up beside the head).
    canvas.save();
    canvas.translate(98, 162);
    canvas.translate(4 * pose.waveLift, -46 * pose.waveLift);
    canvas.rotate(pose.waveRotation);
    canvas.translate(-98, -162);
    _furFill(canvas, _oval(98, 162, 13, 8));
    _outline(canvas, _path);
    canvas.restore();

    _paintClipboard(canvas);
    _paintBowTie(canvas);
    canvas.restore();
  }

  void _paintClipboard(Canvas canvas) {
    canvas.save();
    canvas.translate(58, 134);
    canvas.rotate(deg(-10));
    // Board.
    final RRect board = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-17, -21, 34, 42),
      const Radius.circular(4),
    );
    _fill
      ..shader = null
      ..color = MonkeyInk.board;
    canvas.drawRRect(board, _fill);
    _stroke
      ..color = MonkeyInk.outline
      ..strokeWidth = 2.5;
    canvas.drawRRect(board, _stroke);
    // Paper and its lines.
    _fill.color = MonkeyInk.paper;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -15, 26, 33),
        const Radius.circular(2),
      ),
      _fill,
    );
    _stroke
      ..color = MonkeyInk.outline.withValues(alpha: 0.35)
      ..strokeWidth = 1.6;
    for (final double y in <double>[-6, 0, 6, 12]) {
      canvas.drawLine(Offset(-2, y), Offset(9, y), _stroke);
    }
    // A green tick on the first lines (audited).
    _stroke
      ..color = MonkeyInk.tick
      ..strokeWidth = 2.2;
    _path
      ..reset()
      ..moveTo(-10, -1)
      ..lineTo(-7.5, 1.6)
      ..lineTo(-4, -4);
    canvas.drawPath(_path, _stroke);
    _path
      ..reset()
      ..moveTo(-10, 10)
      ..lineTo(-7.5, 12.6)
      ..lineTo(-4, 7);
    canvas.drawPath(_path, _stroke);
    // Metal clip.
    final RRect clip = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, -25, 16, 8),
      const Radius.circular(2.5),
    );
    _fill.color = MonkeyInk.clip;
    canvas.drawRRect(clip, _fill);
    _stroke
      ..color = MonkeyInk.outline
      ..strokeWidth = 2;
    canvas.drawRRect(clip, _stroke);
    // The paw holding it.
    _furFill(canvas, _oval(14, 4, 8, 10));
    _outline(canvas, _path, 2.5);
    canvas.restore();
  }

  void _paintBowTie(Canvas canvas) {
    _path
      ..reset()
      ..moveTo(80, 108)
      ..lineTo(68, 101)
      ..lineTo(68, 115)
      ..close()
      ..moveTo(80, 108)
      ..lineTo(92, 101)
      ..lineTo(92, 115)
      ..close();
    _solid(canvas, _path, MonkeyInk.tie);
    _stroke
      ..color = MonkeyInk.outline
      ..strokeWidth = 2;
    canvas.drawPath(_path, _stroke);
    _fill.color = MonkeyInk.tie;
    canvas.drawCircle(const Offset(80, 108), 3.6, _fill);
    canvas.drawCircle(const Offset(80, 108), 3.6, _stroke);
  }

  void _paintHead(Canvas canvas) {
    canvas.save();
    // mwTilt / mwNod from (80,104).
    canvas.translate(80, 104 + pose.headDy);
    canvas.rotate(pose.headRotation);
    canvas.translate(-80, -104);

    _paintEar(canvas, 34, 64, pose.earLeft, const Offset(44, 64));
    _paintEar(canvas, 126, 64, pose.earRight, const Offset(116, 64));

    // Head.
    _furFill(canvas, _oval(80, 62, 46, 40));
    // Hair tuft.
    _path
      ..reset()
      ..moveTo(70, 26)
      ..quadraticBezierTo(76, 12, 86, 18)
      ..quadraticBezierTo(80, 18, 80, 25)
      ..close();
    _furFill(canvas, _path);
    _outline(canvas, _path, 2.5);
    _outline(canvas, _oval(80, 62, 46, 40));

    // Face mask: two eye circles and a muzzle (Mimi's patch, in peach).
    _path
      ..reset()
      ..addOval(Rect.fromCircle(center: const Offset(64, 60), radius: 19))
      ..addOval(Rect.fromCircle(center: const Offset(96, 60), radius: 19))
      ..addOval(
        Rect.fromCenter(center: const Offset(80, 82), width: 66, height: 40),
      );
    _solid(canvas, _path, MonkeyInk.face);

    // Cheeks.
    _fill.color = MonkeyInk.blush.withValues(alpha: pose.blush);
    canvas.drawCircle(const Offset(49, 82), 7, _fill);
    canvas.drawCircle(const Offset(111, 82), 7, _fill);

    _paintEyes(canvas);
    _paintGlasses(canvas);
    _paintBrows(canvas);

    // Nose.
    _fill.color = MonkeyInk.outline;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(76.5, 79), width: 3.4, height: 2.6),
      _fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(83.5, 79), width: 3.4, height: 2.6),
      _fill,
    );
    _paintMouth(canvas);
    if (pose.worry > 0) _paintSweat(canvas);
    canvas.restore();
  }

  void _paintEar(
    Canvas canvas,
    double cx,
    double cy,
    double angle,
    Offset pivot,
  ) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _furFill(canvas, _oval(cx, cy, 15, 16));
    _outline(canvas, _path);
    _solid(canvas, _oval(cx, cy + 1, 8.5, 10), MonkeyInk.earInner);
    canvas.restore();
  }

  void _paintEyes(Canvas canvas) {
    switch (pose.eyes) {
      case MonkeyEyes.open:
        canvas.save();
        canvas.translate(pose.look.dx, pose.look.dy);
        for (final double cx in <double>[64, 96]) {
          canvas.save();
          canvas.translate(cx, 61);
          canvas.scale(1, pose.blink);
          _fill.color = MonkeyInk.outline;
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 13, height: 16),
            _fill,
          );
          _fill.color = const Color(0xFFFFFFFF);
          canvas.drawCircle(const Offset(2.6, -3.8), 2.6, _fill);
          _fill.color = const Color(0xB3FFFFFF);
          canvas.drawCircle(const Offset(-2, 4), 1.1, _fill);
          canvas.restore();
        }
        canvas.restore();
      case MonkeyEyes.happy:
        _stroke
          ..color = MonkeyInk.outline
          ..strokeWidth = 4;
        for (final double cx in <double>[64, 96]) {
          _path
            ..reset()
            ..moveTo(cx - 7, 64)
            ..quadraticBezierTo(cx, 53, cx + 7, 64);
          canvas.drawPath(_path, _stroke);
        }
      case MonkeyEyes.sleep:
        _stroke
          ..color = MonkeyInk.outline
          ..strokeWidth = 3.5;
        for (final double cx in <double>[64, 96]) {
          _path
            ..reset()
            ..moveTo(cx - 7, 61)
            ..quadraticBezierTo(cx, 67, cx + 7, 61);
          canvas.drawPath(_path, _stroke);
        }
    }
  }

  void _paintGlasses(Canvas canvas) {
    _fill.color = MonkeyInk.lens;
    canvas.drawCircle(const Offset(64, 61), 14, _fill);
    canvas.drawCircle(const Offset(96, 61), 14, _fill);
    _stroke
      ..color = MonkeyInk.outline
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(64, 61), 14, _stroke);
    canvas.drawCircle(const Offset(96, 61), 14, _stroke);
    _path
      ..reset()
      ..moveTo(78, 59)
      ..quadraticBezierTo(80, 55.5, 82, 59)
      ..moveTo(50, 58)
      ..lineTo(37, 55)
      ..moveTo(110, 58)
      ..lineTo(123, 55);
    canvas.drawPath(_path, _stroke);
    // Lens glint.
    _stroke
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 2;
    _path
      ..reset()
      ..addArc(
        Rect.fromCircle(center: const Offset(64, 61), radius: 10),
        deg(200),
        deg(50),
      )
      ..addArc(
        Rect.fromCircle(center: const Offset(96, 61), radius: 10),
        deg(200),
        deg(50),
      );
    canvas.drawPath(_path, _stroke);
  }

  void _paintBrows(Canvas canvas) {
    if (pose.worry <= 0) return;
    _stroke
      ..color = MonkeyInk.outline.withValues(alpha: pose.worry)
      ..strokeWidth = 3;
    // Worried: inner ends raised.
    _path
      ..reset()
      ..moveTo(52, 44)
      ..lineTo(68, 39)
      ..moveTo(108, 44)
      ..lineTo(92, 39);
    canvas.drawPath(_path, _stroke);
  }

  void _paintMouth(Canvas canvas) {
    _stroke
      ..color = MonkeyInk.outline
      ..strokeWidth = 2.5;
    final bool open = pose.talking || pose.mouth == MonkeyMouth.grin;
    if (open) {
      _path
        ..reset()
        ..moveTo(71, 86)
        ..quadraticBezierTo(80, 101, 89, 86)
        ..close();
      _solid(canvas, _path, MonkeyInk.mouth);
      _stroke.strokeWidth = 2.2;
      canvas.drawPath(_path, _stroke);
      return;
    }
    _path.reset();
    if (pose.mouth == MonkeyMouth.sad) {
      _path
        ..moveTo(72, 92)
        ..quadraticBezierTo(80, 84, 88, 92);
    } else {
      _path
        ..moveTo(70, 87)
        ..quadraticBezierTo(75, 93, 80, 88)
        ..quadraticBezierTo(85, 93, 90, 87);
    }
    canvas.drawPath(_path, _stroke);
  }

  void _paintSweat(Canvas canvas) {
    _path
      ..reset()
      ..moveTo(120, 32)
      ..quadraticBezierTo(126, 42, 120, 45)
      ..quadraticBezierTo(114, 42, 120, 32)
      ..close();
    _fill.color = MonkeyInk.sweat.withValues(alpha: pose.worry);
    canvas.drawPath(_path, _fill);
    _stroke
      ..color = MonkeyInk.outline.withValues(alpha: pose.worry)
      ..strokeWidth = 1.6;
    canvas.drawPath(_path, _stroke);
  }

  // ---- Extras ----

  static final Keyframes _zFloat = Keyframes(<Stop>[
    (0, 0),
    (0.25, 0.25),
    (1, 1),
  ], curve: Curves.easeIn);

  void _paintZz(Canvas canvas) {
    // mwZ: three z's floating up-right, 1 s apart.
    for (int i = 0; i < 3; i++) {
      final double p = _zFloat.loop(pose.seconds, 3, delay: i.toDouble());
      final double fade = p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75;
      final double size = <double>[16, 13, 10][i];
      final TextPainter tp = _zPainters[i];
      if (tp.text == null) {
        tp
          ..text = TextSpan(
            text: 'z',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              fontSize: size,
              color: MonkeyInk.zz,
              shadows: const <Shadow>[
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          )
          ..layout();
      }
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, fade * pose.sleep),
      );
      tp.paint(canvas, Offset(viewW * 0.92 + 14 * p, viewH * 0.02 - 30 * p));
      canvas.restore();
    }
  }

  final List<TextPainter> _zPainters = List<TextPainter>.generate(
    3,
    (_) => TextPainter(textDirection: TextDirection.ltr),
  );

  void _paintDizzy(Canvas canvas) {
    // mwSpinStars: three stars circling above the head.
    final double a = pose.seconds / 0.8 * 2 * math.pi;
    _fill.color = MonkeyInk.star.withValues(alpha: pose.dizzy);
    for (int i = 0; i < 3; i++) {
      final double t = a + i * 2 * math.pi / 3;
      canvas.save();
      canvas.translate(80 + math.cos(t) * 44, 20 + math.sin(t) * 10);
      canvas.scale(7);
      canvas.drawPath(_star, _fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MonkeyPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.sky != sky;
}
