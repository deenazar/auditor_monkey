import 'package:auditor_monkey/shared/scene/keyframes.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing 0% and 100% stops use the rest value', () {
    final Keyframes k = Keyframes(<Stop>[(0.5, 10)], curve: Curves.linear);
    expect(k.at(0), 0);
    expect(k.at(0.25), 5);
    expect(k.at(0.5), 10);
    expect(k.at(0.75), 5);
    expect(k.at(1), 0);
    expect(k.at(2), 0);
  });

  test('rest value and loops with a negative delay', () {
    final Keyframes k = Keyframes(
      <Stop>[(0.5, 2)],
      curve: Curves.linear,
      rest: 1,
    );
    expect(k.at(0), 1);
    expect(k.loop(3.5, 2), 1.5);
    expect(k.loop(0, 2, delay: -1), 2);
  });

  test('pulse is 0 at the ends and 1 in the middle', () {
    expect(pulse(0, 4), closeTo(0, 1e-9));
    expect(pulse(2, 4), closeTo(1, 1e-9));
    expect(pulse(4, 4), closeTo(0, 1e-9));
  });
}
