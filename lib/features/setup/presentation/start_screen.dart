import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/widgets/error_state.dart';

/// Start screen (shown while the app opens its data).
///
/// - No [error]: a white screen with a small `primary` ring. The ring only
///   appears after 300ms, so fast starts show no flash.
/// - [error] set: a `danger` icon, a short title and message, and a
///   "Try again" button when [onRetry] is given. It never wipes data. The
///   error object is not shown to the person.
class StartScreen extends StatefulWidget {
  const StartScreen({this.error, this.onRetry, super.key});

  /// Why the app could not open its data. Null while loading.
  final Object? error;

  /// Called by "Try again". Null hides the button.
  final VoidCallback? onRetry;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  /// Wait this long before showing the ring, so fast starts show no spinner.
  static const Duration _ringDelay = Duration(milliseconds: 300);

  Timer? _ringTimer;
  bool _ringDue = false;

  @override
  void initState() {
    super.initState();
    _ringTimer = Timer(_ringDelay, () {
      if (mounted) setState(() => _ringDue = true);
    });
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: hasError
            ? ErrorState(
                title: "We can't open your data",
                message: 'Your data is safe. Update or restart the app.',
                onRetry: widget.onRetry,
              )
            : Center(child: _ringDue ? const _FadingRing() : null),
      ),
    );
  }
}

/// The small primary ring, fading in once it is mounted.
class _FadingRing extends StatelessWidget {
  const _FadingRing();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.durationFast),
      curve: AppMotion.curveEnter,
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: const SizedBox(
        width: AppSizes.progressRing,
        height: AppSizes.progressRing,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStroke,
          color: AppColors.primaryDeep,
          semanticsLabel: 'Loading',
        ),
      ),
    );
  }
}
