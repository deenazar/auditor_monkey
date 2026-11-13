import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../shared/theme/app_motion.dart';
import '../application/mascot_player.dart';
import '../application/mascot_providers.dart';
import '../domain/mascot_mood.dart';

const String _tag = 'mascot';

/// Poster shown while loading, on error, in tests and with reduce motion.
const String mascotPosterAsset = 'assets/illustrations/mascot_poster.svg';

/// How long the one-shot `happy` clip plays after a tap.
const Duration mascotHappyDuration = Duration(milliseconds: 1800);

/// The 3D Auditor Monkey.
///
/// The 3D view is built only after the first frame, only while on-screen
/// and only while the app is resumed; otherwise it is unmounted and the
/// poster shows. Tap plays `happy` once, then back to [mood].
class MascotView extends ConsumerStatefulWidget {
  /// Creates the mascot at [size] x [size].
  const MascotView({required this.mood, required this.size, super.key});

  /// The mood (clip) to play.
  final MascotMood mood;

  /// Width and height in pt.
  final double size;

  @override
  ConsumerState<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends ConsumerState<MascotView>
    with WidgetsBindingObserver {
  final Key _detectorKey = UniqueKey();
  bool _firstFrameDone = false;
  bool _visible = false;
  bool _resumed = true;
  bool _failed = false;
  bool _ready = false;
  MascotPlayer? _player;
  List<String> _clips = const <String>[];
  Timer? _happyTimer;
  int _viewerGen = 0;

  /// Built once per mount: rebuilds must not recreate the 3D view.
  Widget? _viewer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstFrameDone = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _happyTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool resumed = state == AppLifecycleState.resumed;
    if (resumed == _resumed) return;
    setState(() {
      _resumed = resumed;
      if (!resumed) _dropViewer();
    });
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood && _happyTimer == null) _playMood();
  }

  void _dropViewer() {
    _player = null;
    _ready = false;
    _viewer = null;
    _viewerGen++;
    _happyTimer?.cancel();
    _happyTimer = null;
  }

  void _onVisibility(VisibilityInfo info) {
    final bool visible = info.visibleFraction > 0;
    if (visible == _visible || !mounted) return;
    setState(() {
      _visible = visible;
      if (!visible) _dropViewer();
    });
  }

  void _onReady(MascotPlayer player, int gen) async {
    List<String> clips;
    try {
      clips = await player.availableClips();
    } catch (_) {
      clips = const <String>[];
    }
    if (!mounted || gen != _viewerGen) return;
    ref.read(loggerProvider).info(_tag, 'model loaded, clips=${clips.length}');
    setState(() {
      _player = player;
      _clips = clips;
      _ready = true;
    });
    _playMood();
  }

  void _onError(String error) {
    if (!mounted) return;
    ref.read(loggerProvider).warning(_tag, 'model failed to load');
    setState(() => _failed = true);
  }

  /// Plays [mood]; a missing clip falls back to `idle`.
  void _play(MascotMood mood) {
    final MascotPlayer? player = _player;
    if (player == null) return;
    String clip = mood.clipName;
    if (!_clips.contains(clip)) clip = MascotMood.idle.clipName;
    // A model without even `idle` stays on its first pose.
    if (!_clips.contains(clip)) return;
    final bool oneShot =
        mood == MascotMood.happy || mood == MascotMood.celebrating;
    try {
      player.play(clip, loops: oneShot ? 1 : 0);
    } catch (_) {
      ref.read(loggerProvider).warning(_tag, 'play failed');
    }
  }

  void _playMood() => _play(widget.mood);

  void _onTap() {
    HapticFeedback.lightImpact();
    if (_player == null) return;
    _play(MascotMood.happy);
    _happyTimer?.cancel();
    _happyTimer = Timer(mascotHappyDuration, () {
      _happyTimer = null;
      if (mounted) _playMood();
    });
  }

  Widget _poster() => SvgPicture.asset(
    mascotPosterAsset,
    width: widget.size,
    height: widget.size,
    placeholderBuilder: (_) => SizedBox.square(dimension: widget.size),
    errorBuilder: (_, _, _) => SizedBox.square(dimension: widget.size),
  );

  @override
  Widget build(BuildContext context) {
    final bool posterOnly =
        ref.watch(mascotPosterOnlyProvider) || AppMotion.reduceMotion(context);
    final bool wantViewer =
        !posterOnly && _firstFrameDone && _visible && _resumed && !_failed;

    Widget content = _poster();
    if (!posterOnly) {
      final int gen = _viewerGen;
      if (wantViewer) {
        _viewer ??= ref.read(mascotViewerFactoryProvider)(
          onReady: (MascotPlayer p) => _onReady(p, gen),
          onError: _onError,
        );
      } else {
        _viewer = null;
      }
      content = Stack(
        children: <Widget>[
          Positioned.fill(child: content),
          if (wantViewer && _viewer != null)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _ready ? 1 : 0,
                duration: AppMotion.durationMedium,
                child: IgnorePointer(child: _viewer),
              ),
            ),
        ],
      );
      content = VisibilityDetector(
        key: _detectorKey,
        onVisibilityChanged: _onVisibility,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: 'Auditor Monkey, tap to say hi',
      excludeSemantics: true,
      onTap: _onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: RepaintBoundary(
          child: SizedBox.square(dimension: widget.size, child: content),
        ),
      ),
    );
  }
}
