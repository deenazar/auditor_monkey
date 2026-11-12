import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A soft spring curve: damping ratio about 0.8, stiffness 200, mass 1.
class SpringCurve extends Curve {
  /// Creates the spring used for the card carousel snap.
  const SpringCurve({
    this.mass = 1,
    this.stiffness = 200,
    this.dampingRatio = 0.8,
  });

  final double mass;
  final double stiffness;
  final double dampingRatio;

  @override
  double transformInternal(double t) {
    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: mass,
      stiffness: stiffness,
      ratio: dampingRatio,
    );
    return _SpringSim(spring).x(t);
  }
}

class _SpringSim {
  _SpringSim(SpringDescription spring)
    : _sim = SpringSimulation(spring, 0, 1, 0);

  final SpringSimulation _sim;

  // Map curve time (0..1) onto the first second of the simulation.
  double x(double t) => t >= 1 ? 1 : _sim.x(t);
}

/// Design tokens: motion.
abstract final class AppMotion {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationChart = Duration(milliseconds: 400);

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveSpring = SpringCurve();

  /// True when the phone's "reduce motion" setting is on.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], or zero when reduce motion is on (final values instantly).
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}
