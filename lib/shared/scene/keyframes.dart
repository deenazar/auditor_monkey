import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';

/// One CSS keyframe stop: at [at] (0..1) the value is [value].
typedef Stop = (double at, double value);

/// A CSS `@keyframes` track for one number, eased per segment like CSS
/// (`animation-timing-function` applies between each pair of stops).
///
/// Missing 0% and 100% stops default to [rest], as in CSS where an omitted
/// end keyframe uses the element's normal value.
class Keyframes {
  Keyframes(List<Stop> stops, {this.curve = Curves.ease, this.rest = 0})
    : _stops = _withEnds(stops, rest);

  final List<Stop> _stops;
  final Curve curve;
  final double rest;

  static List<Stop> _withEnds(List<Stop> stops, double rest) {
    final List<Stop> s = <Stop>[...stops]
      ..sort((Stop a, Stop b) => a.$1.compareTo(b.$1));
    if (s.isEmpty || s.first.$1 > 0) s.insert(0, (0, rest));
    if (s.last.$1 < 1) s.add((1, rest));
    return s;
  }

  /// The value at progress [t] (0..1, clamped).
  double at(double t) {
    final double p = t.clamp(0.0, 1.0);
    for (int i = 1; i < _stops.length; i++) {
      final Stop b = _stops[i];
      if (p <= b.$1) {
        final Stop a = _stops[i - 1];
        final double span = b.$1 - a.$1;
        final double local = span <= 0 ? 1 : (p - a.$1) / span;
        return lerpDouble(a.$2, b.$2, curve.transform(local))!;
      }
    }
    return _stops.last.$2;
  }

  /// The value of an endless loop with [period] seconds at time [seconds]
  /// (plus an optional [delay], negative to start part-way, as in CSS).
  double loop(double seconds, double period, {double delay = 0}) {
    final double t = (seconds - delay) / period;
    return at(t - t.floorToDouble());
  }
}

/// `ease-in-out` sine wave: 0 at the start and end of each [period], 1 in
/// the middle. Cheap stand-in for a two-stop `50%{…}` keyframe.
double pulse(double seconds, double period, {double delay = 0}) {
  final double t = (seconds - delay) / period;
  return 0.5 - 0.5 * math.cos((t - t.floorToDouble()) * 2 * math.pi);
}

/// Degrees to radians.
double deg(double d) => d * math.pi / 180;
