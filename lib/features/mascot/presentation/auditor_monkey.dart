import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../shared/scene/keyframes.dart';
import '../../../shared/scene/sky_phase.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/sky_palette.dart';
import '../domain/mascot_mood.dart';
import 'mascot_controller.dart';
import 'mascot_motion.dart';
import 'painters/monkey_painter.dart';
import 'painters/monkey_pose.dart';
import 'widgets/mascot_burst.dart';
import 'widgets/speech_bubble.dart';

/// The Auditor Monkey: a native port of Mimi (mini_checklist
/// `web/mimi-world.js`) as a monkey with glasses and a clipboard.
///
/// - Endless loops: breathing, head tilt, tail swish, blinking, the halo
///   floating, "zzz" while asleep. They run on one ticker and rest
///   [AppMotion.sceneRestAfter] after the last touch or reaction.
/// - Moods: [mood] is the base mood; reactions add a short happy or sad
///   face on top. An [idle] monkey sleeps in the sleepy hours unless
///   touched in the last 25 s.
/// - Touch: head giggles, belly laughs, tail grumbles, ears twitch,
///   stroking purrs with hearts, double tap dances, six fast taps make it
///   dizzy.
/// - Reduce motion: no loops and no reactions, still moods and bubbles.
class AuditorMonkey extends StatefulWidget {
  const AuditorMonkey({
    this.mood = MascotMood.idle,
    this.controller,
    this.size = 160,
    this.sleepyHour = false,
    this.phase = SkyPhase.day,
    this.halo = true,
    this.showBubble = true,
    this.interactive = true,
    super.key,
  });

  final MascotMood mood;
  final MascotController? controller;

  /// Width; the height follows the 160:176 view box.
  final double size;

  /// True in the sleepy hours (see [isSleepyHour]).
  final bool sleepyHour;

  /// Sun or moon colours for the halo.
  final SkyPhase phase;

  /// Draws the sun / moon halo and ground shadow.
  final bool halo;

  /// Shows the speech bubble itself (false when the screen shows it).
  final bool showBubble;

  /// Reacts to touch.
  final bool interactive;

  @override
  State<AuditorMonkey> createState() => _AuditorMonkeyState();
}

class _AuditorMonkeyState extends State<AuditorMonkey>
    with SingleTickerProviderStateMixin
    implements MascotHost {
  late final Ticker _ticker = createTicker(_onTick);
  final MonkeyPose _pose = MonkeyPose();
  final _Repaint _repaint = _Repaint();
  late final MonkeyPainter _painter = MonkeyPainter(
    pose: _pose,
    sky: () => (SkyColors.of(widget.phase), widget.phase == SkyPhase.night),
    repaint: _repaint,
  );
  late MascotController _controller = widget.controller ?? MascotController();
  final math.Random _random = math.Random();

  // Time: [_base] + the running ticker's elapsed time, in seconds.
  double _base = 0;
  double _now = 0;
  double _lastActive = 0;

  // A one-shot figure motion and when it started.
  FigureMotion? _motion;
  double _motionStart = 0;

  // Ear twitch: -1 left, 1 right, 0 none.
  int _twitch = 0;
  double _twitchStart = 0;

  // Transient mood from a reaction, and when the monkey was last woken.
  MascotReaction? _flash;
  bool _flashHappy = false;
  Timer? _flashTimer;
  DateTime _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _awakeTimer;

  bool _talking = false;
  Timer? _talkTimer;
  Timer? _bubbleTimer;
  Offset _look = Offset.zero;
  Timer? _lookTimer;
  bool _typing = false;
  Timer? _typeTimer;

  bool _purring = false;
  bool _dizzy = false;
  Timer? _dizzyTimer;

  // Touch tracking (pointer down → up).
  Offset? _downAt;
  double _downTime = 0;
  double _dragDistance = 0;
  Offset _lastPointer = Offset.zero;
  double _lastHeart = 0;
  final List<double> _taps = <double>[];
  double _lastTapAt = -10;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  double get _height => widget.size * MonkeyPainter.viewH / MonkeyPainter.viewW;

  @override
  void initState() {
    super.initState();
    MascotHost.attach(_controller, this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
    _updatePose();
  }

  @override
  void didUpdateWidget(AuditorMonkey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      MascotHost.attach(_controller, null);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? MascotController();
      MascotHost.attach(_controller, this);
    }
    if (oldWidget.mood != widget.mood) {
      if (widget.mood == MascotMood.celebrating) {
        react(MascotReaction.win, null);
      } else {
        poke();
      }
    }
    _updatePose();
  }

  @override
  void dispose() {
    for (final Timer? t in <Timer?>[
      _flashTimer,
      _awakeTimer,
      _talkTimer,
      _bubbleTimer,
      _lookTimer,
      _typeTimer,
      _dizzyTimer,
    ]) {
      t?.cancel();
    }
    MascotHost.attach(_controller, null);
    if (widget.controller == null) _controller.dispose();
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ---- Ticker and rest ----

  bool get _busy =>
      _motion != null || _twitch != 0 || _purring || _dizzy || _talking;

  void _syncTicker() {
    final bool run = !_reduce && (_now - _lastActive < _restSeconds || _busy);
    if (run && !_ticker.isActive) {
      _base = _now;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  static final double _restSeconds =
      AppMotion.sceneRestAfter.inMilliseconds / 1000;

  void _onTick(Duration elapsed) {
    _now = _base + elapsed.inMicroseconds / 1e6;
    _updatePose();
    if (_now - _lastActive >= _restSeconds && !_busy) {
      _ticker.stop();
    }
  }

  @override
  void poke() {
    _lastActive = _now;
    if (mounted) _syncTicker();
  }

  void _wake() {
    _awakeUntil = DateTime.now().add(const Duration(seconds: 25));
    _awakeTimer?.cancel();
    _awakeTimer = Timer(const Duration(seconds: 25), _refresh);
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    _updatePose();
    _syncTicker();
  }

  // ---- Moods ----

  bool get _asleep {
    if (_flash != null || _purring) return false;
    if (widget.mood == MascotMood.sleeping) return true;
    return widget.mood == MascotMood.idle &&
        widget.sleepyHour &&
        DateTime.now().isAfter(_awakeUntil);
  }

  void _setFlash(bool happy, int ms) {
    _flash = MascotReaction.check;
    _flashHappy = happy;
    _flashTimer?.cancel();
    _flashTimer = Timer(Duration(milliseconds: ms), () {
      _flash = null;
      _refresh();
    });
    _refresh();
  }

  void _play(FigureMotion motion) {
    if (_reduce) return;
    _motion = motion;
    _motionStart = _now;
    poke();
  }

  @override
  void react(MascotReaction reaction, String? text) {
    _wake();
    poke();
    switch (reaction) {
      case MascotReaction.check:
        _play(FigureMotion.jump);
        _setFlash(true, 1500);
        _burstAtFigure(9);
      case MascotReaction.add:
        _play(FigureMotion.hop);
        _setFlash(true, 1200);
      case MascotReaction.del:
        _play(FigureMotion.shake);
      case MascotReaction.win:
        _play(FigureMotion.dance);
        _setFlash(true, 2600);
        _burstAtFigure(16);
      case MascotReaction.sad:
        _play(FigureMotion.nod);
        _setFlash(false, 1600);
      case MascotReaction.hello:
        _play(FigureMotion.wave);
        _setFlash(true, 1300);
      case MascotReaction.spin:
        _play(FigureMotion.spin);
    }
    if (text != null) {
      say(
        text,
        reaction == MascotReaction.win
            ? const Duration(milliseconds: 4000)
            : const Duration(milliseconds: 2600),
      );
    }
  }

  @override
  void say(String text, Duration duration) {
    if (text.isEmpty || !mounted) return;
    poke();
    _controller.bubble.value = text;
    _talking = true;
    _talkTimer?.cancel();
    _talkTimer = Timer(
      Duration(milliseconds: math.min(duration.inMilliseconds, 1600)),
      () {
        _talking = false;
        _refresh();
      },
    );
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(duration, () {
      if (mounted) _controller.bubble.value = null;
    });
    _refresh();
  }

  @override
  void look(Offset direction) {
    final double d = math.max(1, direction.distance);
    _look = Offset(direction.dx / d * 3.2, direction.dy / d * 3);
    _lookTimer?.cancel();
    _lookTimer = Timer(const Duration(milliseconds: 3500), () {
      _look = Offset.zero;
      _refresh();
    });
    _refresh();
  }

  @override
  void type() {
    _wake();
    _typing = true;
    _typeTimer?.cancel();
    _typeTimer = Timer(const Duration(milliseconds: 900), () {
      _typing = false;
      _refresh();
    });
  }

  // ---- Pose ----

  void _updatePose() {
    if (!mounted) return;
    final MonkeyPose p = _pose;
    final double t = _now;
    final bool still = _reduce;
    final bool asleep = _asleep;
    p
      ..seconds = t
      ..halo = widget.halo
      ..figureDy = 0
      ..figureScaleX = 1
      ..figureScaleY = 1
      ..figureRotation = 0
      ..waveLift = 0
      ..waveRotation = 0;

    // Loops.
    final double breath = still ? 0 : pulse(t, 3.4);
    p
      ..breathX = 1 + 0.025 * breath
      ..breathY = 1 + 0.035 * breath
      ..tailRotation = still
          ? 0
          : deg(-14) * pulse(t, widget.mood == MascotMood.sleeping ? 5 : 2.8)
      ..blink = still || asleep ? 1 : AmbientMotion.blink.loop(t, 5.2);
    if (asleep) {
      final double nod = still ? 0 : pulse(t, 4);
      p
        ..headRotation = deg(4) * nod
        ..headDy = 2 * nod;
    } else {
      p
        ..headRotation = still ? 0 : deg(AmbientMotion.tilt.loop(t, 7))
        ..headDy = 0;
    }

    // One-shot reaction.
    final FigureMotion? m = _motion;
    if (m != null) {
      final double total = m.seconds * m.repeat;
      final double run = t - _motionStart;
      if (run >= total) {
        _motion = null;
      } else {
        final double local = (run % m.seconds) / m.seconds;
        if (m.movesPaw) {
          p
            ..waveLift = m.dy?.at(local) ?? 0
            ..waveRotation = deg(m.rotate?.at(local) ?? 0);
        } else {
          p
            ..figureDy = (m.dy?.at(local) ?? 0) * MonkeyPainter.viewH
            ..figureScaleX = m.scaleX?.at(local) ?? 1
            ..figureScaleY = m.scaleY?.at(local) ?? 1
            ..figureRotation = deg(m.rotate?.at(local) ?? 0);
        }
      }
    }

    // Ears: twitch, droop when worried / sad, perk when typing.
    final bool sad =
        (_flash != null && !_flashHappy) ||
        (_flash == null && widget.mood == MascotMood.worried);
    double earL = sad ? deg(-18) : (_typing ? deg(-6) : 0);
    double earR = sad ? deg(18) : (_typing ? deg(6) : 0);
    if (_twitch != 0) {
      final double run = (t - _twitchStart) / 0.5;
      if (run >= 1 || still) {
        _twitch = 0;
      } else {
        final double a = deg(AmbientMotion.earTwitch.at(run));
        if (_twitch < 0) {
          earL = a;
        } else {
          earR = -a;
        }
      }
    }
    p
      ..earLeft = earL
      ..earRight = earR
      ..look = _look
      ..purr = _purring && !still
          ? Offset(0.6 * pulse(t, 0.11), -0.4 * pulse(t, 0.11))
          : Offset.zero;

    // Face.
    final bool flashHappy = _flash != null && _flashHappy;
    p
      ..eyes = asleep
          ? MonkeyEyes.sleep
          : (flashHappy || _purring || widget.mood == MascotMood.celebrating)
          ? MonkeyEyes.happy
          : MonkeyEyes.open
      ..mouth = sad
          ? MonkeyMouth.sad
          : (widget.mood == MascotMood.happy ||
                widget.mood == MascotMood.celebrating ||
                flashHappy)
          ? MonkeyMouth.grin
          : MonkeyMouth.smile
      ..talking = _talking && !still ? (t * 1000 ~/ 130).isEven : _talking
      ..worry = sad ? 1 : 0
      ..blush = widget.mood == MascotMood.happy || flashHappy ? 0.7 : 0.45
      ..sleep = asleep ? 1 : 0
      ..dizzy = _dizzy ? 1 : 0;
    _repaint.ping();
  }

  // ---- Touch (mimi-world.js zoneAt / touchReact) ----

  String _zoneAt(Offset local) {
    final double fx = local.dx / widget.size;
    final double fy = local.dy / _height;
    if (fy < 0.31 && ((fx > 0.12 && fx < 0.3) || (fx > 0.7 && fx < 0.88))) {
      return fx < 0.5 ? 'earL' : 'earR';
    }
    if (fx > 0.70 && fy > 0.46 && fy < 0.88) return 'tail';
    if (fy < 0.6 && fx > 0.18 && fx < 0.82) return 'head';
    if (fy >= 0.6 && fx > 0.3 && fx < 0.7) return 'belly';
    return 'body';
  }

  String _pick(List<String> options) =>
      options[_random.nextInt(options.length)];

  void _touch(String zone, Offset global) {
    _wake();
    poke();
    switch (zone) {
      case 'head':
        _play(FigureMotion.hop);
        _setFlash(true, 1300);
        HapticFeedback.selectionClick();
        say(
          _pick(<String>['Hehe 🙈', 'Books look good!', 'More head pats!']),
          const Duration(milliseconds: 1800),
        );
        _heart(global, '💕');
      case 'belly':
        _play(FigureMotion.jump);
        _setFlash(true, 1500);
        HapticFeedback.lightImpact();
        say(
          _pick(<String>['Hahaha! That tickles! 🤭', 'Not the tummy! 🙉']),
          const Duration(milliseconds: 1800),
        );
        _heart(global, '✨');
      case 'tail':
        _play(FigureMotion.shake);
        _setFlash(false, 1500);
        HapticFeedback.mediumImpact();
        say(
          _pick(<String>['Hey! Not my tail! 🙊', 'Hmph!', 'Mind the tail!']),
          const Duration(milliseconds: 1800),
        );
      case 'earL':
      case 'earR':
        if (!_reduce) {
          _twitch = zone == 'earL' ? -1 : 1;
          _twitchStart = _now;
        }
        _play(FigureMotion.nod);
        HapticFeedback.selectionClick();
        say(
          _pick(<String>['Hm? 👂', 'I heard that!', 'Ook?']),
          const Duration(milliseconds: 1600),
        );
      default:
        _play(FigureMotion.hop);
        HapticFeedback.selectionClick();
        say(
          _pick(<String>['Ook ook!', 'Hi there!', 'Audit time? 📋']),
          const Duration(milliseconds: 1600),
        );
    }
  }

  void _dizzyNow() {
    _play(FigureMotion.spin);
    HapticFeedback.heavyImpact();
    _dizzy = true;
    _dizzyTimer?.cancel();
    _dizzyTimer = Timer(const Duration(milliseconds: 2600), () {
      _dizzy = false;
      _refresh();
    });
    say('Whoa… so dizzy 😵‍💫', const Duration(milliseconds: 2600));
  }

  void _heart(Offset global, String glyph) {
    if (_reduce) return;
    MascotBurst.heart(context, global, glyph, _random);
  }

  void _burstAtFigure(int count) {
    if (_reduce || !mounted) return;
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    MascotBurst.stars(
      context,
      box.localToGlobal(box.size.center(Offset.zero)),
      count,
      _random,
    );
  }

  void _onDown(PointerDownEvent e) {
    _downAt = e.localPosition;
    _lastPointer = e.localPosition;
    _downTime = _now;
    _dragDistance = 0;
    poke();
  }

  void _onMove(PointerMoveEvent e) {
    if (_downAt == null) return;
    _dragDistance += (e.localPosition - _lastPointer).distance;
    _lastPointer = e.localPosition;
    if (!_purring && _dragDistance > 50 && _now - _downTime > 0.16) {
      _purring = true;
      _wake();
      say('Purrr… 💕', const Duration(milliseconds: 2600));
    }
    if (_purring && _now - _lastHeart > 0.3) {
      _lastHeart = _now;
      _heart(e.position, _pick(<String>['💕', '💗', '💖']));
      HapticFeedback.selectionClick();
      poke();
    }
  }

  void _onUp(PointerUpEvent e) {
    final Offset? down = _downAt;
    _downAt = null;
    if (_purring) {
      _purring = false;
      _setFlash(true, 900);
      say(
        _pick(<String>['I love that 💕', 'More pets please 🥰']),
        const Duration(milliseconds: 2000),
      );
      return;
    }
    if (down == null || _dragDistance > 24) return;
    final double now = _now;
    _taps
      ..removeWhere((double t) => now - t > 2.5)
      ..add(now);
    if (_taps.length >= 6) {
      _taps.clear();
      _lastTapAt = -10;
      _dizzyNow();
      return;
    }
    if (now - _lastTapAt < 0.33) {
      _lastTapAt = -10;
      _play(FigureMotion.dance);
      _setFlash(true, 2400);
      say('Audit dance! 💃', const Duration(milliseconds: 2400));
      return;
    }
    _lastTapAt = now;
    _touch(_zoneAt(e.localPosition), e.position);
  }

  void _onCancel(PointerCancelEvent e) {
    _downAt = null;
    if (_purring) {
      _purring = false;
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget art = RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, _height),
        painter: _painter,
        isComplex: true,
      ),
    );
    final Widget figure = !widget.interactive
        ? art
        : Semantics(
            button: true,
            label:
                'Auditor Monkey. Tap the head, belly, ears or tail, or '
                'stroke it. Double-tap for a dance.',
            onTap: () => _touch('head', Offset.zero),
            excludeSemantics: true,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onDown,
              onPointerMove: _onMove,
              onPointerUp: _onUp,
              onPointerCancel: _onCancel,
              child: art,
            ),
          );
    if (!widget.showBubble) return figure;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        figure,
        Positioned(
          left: widget.size * 0.62,
          top: -_height * 0.06,
          child: SpeechBubble(text: _controller.bubble),
        ),
      ],
    );
  }
}

/// Repaints the painter without rebuilding widgets.
class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}
