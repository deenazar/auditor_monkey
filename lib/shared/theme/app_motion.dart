import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A soft spring curve: damping ratio about 0.8, stiffness 200, mass 1.
class SpringCurve extends Curve {
  /// Creates the spring used for the card carousel snap.
  SpringCurve({
    double mass = 1,
    double stiffness = 200,
    double dampingRatio = 0.8,
  }) : _sim = SpringSimulation(
         SpringDescription.withDampingRatio(
           mass: mass,
           stiffness: stiffness,
           ratio: dampingRatio,
         ),
         0,
         1,
         0,
       );

  // Built once; curve time (0..1) maps onto the first second of the spring.
  final SpringSimulation _sim;

  @override
  double transformInternal(double t) => t >= 1 ? 1 : _sim.x(t);
}

/// Design tokens: motion.
abstract final class AppMotion {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationChart = Duration(milliseconds: 400);

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static final Curve curveSpring = SpringCurve();

  /// How long the saved toast (with Undo) stays.
  static const Duration toastDuration = Duration(milliseconds: 4000);

  /// Wait before the loading ring shows, so fast starts show no spinner.
  static const Duration loadingIndicatorDelay = Duration(milliseconds: 300);

  /// Spring of the card carousel snap (same values as [curveSpring]).
  static const double springStiffness = 200;
  static const double springDampingRatio = 0.8;

  /// Delay between items in a staggered entrance.
  static const Duration durationStagger = Duration(milliseconds: 40);

  /// Items up to this count are staggered; the rest appear with the last.
  static const int staggerMaxItems = 8;

  /// Card entrance slide-up distance (pt).
  static const double cardEnterOffset = 12;

  /// Pushed page shared-axis slide distance (pt, = space6).
  static const double pageSlideOffset = 24;

  /// Quick Add sheet open spring: stiffness 380, damping ratio 0.82.
  static final SpringDescription sheetSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.82);

  /// Incoming tab content scale start (to 1).
  static const double tabFadeScaleFrom = 0.98;

  /// Toast check mark scale start (to 1).
  static const double successPopFrom = 0.8;

  /// True when the phone's "reduce motion" setting is on.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], or zero when reduce motion is on (final values instantly).
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}
