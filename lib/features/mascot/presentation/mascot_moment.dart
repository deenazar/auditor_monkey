import 'package:flutter/material.dart';

import '../domain/mascot_mood.dart';
import 'auditor_monkey.dart';
import 'mascot_controller.dart';

/// An "animated mascot moment" for a state (empty, success, error, a
/// wizard step): the 2.5D Auditor Monkey in [mood] that plays [reaction]
/// and says [say] once, just after it appears. It follows the finger
/// while it is on screen. Moods and speech still show with reduce motion.
class MascotMoment extends StatefulWidget {
  const MascotMoment({
    this.mood = MascotMood.idle,
    this.reaction,
    this.say,
    this.size = 140,
    this.controller,
    this.halo = true,
    super.key,
  });

  final MascotMood mood;
  final MascotReaction? reaction;
  final String? say;

  /// Width in pt.
  final double size;

  /// Optional: lets the screen make the monkey react to its own actions.
  final MascotController? controller;
  final bool halo;

  @override
  State<MascotMoment> createState() => _MascotMomentState();
}

class _MascotMomentState extends State<MascotMoment> {
  late final MascotController _own = MascotController();
  MascotController get _c => widget.controller ?? _own;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final MascotReaction? r = widget.reaction;
      if (r != null) {
        _c.react(r, text: widget.say);
      } else if (widget.say != null) {
        _c.say(widget.say!);
      }
    });
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent e) => _c.follow(e.position),
      onPointerMove: (PointerMoveEvent e) => _c.follow(e.position),
      child: AuditorMonkey(
        controller: _c,
        mood: widget.mood,
        size: widget.size,
        halo: widget.halo,
      ),
    );
  }
}
