import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import 'haptics.dart';

/// Confetti for a reached goal: [AppDepth.confettiPieces] palette pieces
/// burst up from [origin] (global), tumble in 3D (flip as they spin) and
/// fall with gravity, then the overlay removes itself. Nothing with
/// reduce motion (a success haptic still plays).
abstract final class Confetti {
  static void burst(BuildContext context, {Offset? origin, int? seed}) {
    AppHaptics.success();
    if (AppMotion.reduceMotion(context)) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final Size screen = MediaQuery.sizeOf(context);
    final Offset from =
        origin ?? Offset(screen.width / 2, screen.height * 0.35);
    final math.Random r = math.Random(seed);
    final List<_Piece> pieces = List<_Piece>.generate(AppDepth.confettiPieces, (
      int i,
    ) {
      final double a = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 0.9;
      final double v = 380 + r.nextDouble() * 520;
      return _Piece(
        velocity: Offset(math.cos(a) * v, math.sin(a) * v),
        colour: AppColors.confetti[i % AppColors.confetti.length],
        spin: (r.nextDouble() - 0.5) * 18,
        flip: 4 + r.nextDouble() * 10,
        size: Size(6 + r.nextDouble() * 6, 9 + r.nextDouble() * 8),
        round: i % 5 == 0,
      );
    });
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _ConfettiRun(
          origin: from,
          pieces: pieces,
          onDone: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _Piece {
  const _Piece({
    required this.velocity,
    required this.colour,
    required this.spin,
    required this.flip,
    required this.size,
    required this.round,
  });
  final Offset velocity;
  final Color colour;
  final double spin;
  final double flip;
  final Size size;
  final bool round;
}

class _ConfettiRun extends StatefulWidget {
  const _ConfettiRun({
    required this.origin,
    required this.pieces,
    required this.onDone,
  });
  final Offset origin;
  final List<_Piece> pieces;
  final VoidCallback onDone;

  @override
  State<_ConfettiRun> createState() => _ConfettiRunState();
}

class _ConfettiRunState extends State<_ConfettiRun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDepth.confetti,
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(_c, widget.origin, widget.pieces),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.a, this.origin, this.pieces) : super(repaint: a);
  final Animation<double> a;
  final Offset origin;
  final List<_Piece> pieces;
  final Paint _p = Paint();

  static const double _gravity = 1400;
  static const double _drag = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = a.value * AppDepth.confetti.inMilliseconds / 1000;
    final double fade = a.value < 0.75 ? 1 : 1 - (a.value - 0.75) / 0.25;
    final double damp = (1 - math.exp(-_drag * t)) / _drag;
    for (final _Piece p in pieces) {
      final Offset pos =
          origin + p.velocity * damp + Offset(0, 0.5 * _gravity * t * t * 0.6);
      final double flipScale = math.cos(t * p.flip);
      _p.color = p.colour.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(t * p.spin);
      canvas.scale(1, flipScale.abs() < 0.15 ? 0.15 : flipScale);
      final Rect rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size.width,
        height: p.size.height,
      );
      if (p.round) {
        canvas.drawOval(rect, _p);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          _p,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
