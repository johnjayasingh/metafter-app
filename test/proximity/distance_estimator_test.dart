import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/proximity/distance_estimator.dart';

void main() {
  test('log-distance model: rssi == txPower → 1 m', () {
    expect(DistanceEstimator.estimate(-59, -59), closeTo(1.0, 1e-9));
  });

  test('log-distance model: −20 dB at n=2 → 10 m', () {
    expect(DistanceEstimator.estimate(-79, -59), closeTo(10.0, 1e-6));
  });

  test('estimates clamp to [minMeters, maxMeters]', () {
    expect(DistanceEstimator.estimate(0, -59), 0.1);
    expect(DistanceEstimator.estimate(-120, -59), 50.0);
  });

  test('EMA smooths spikes', () {
    final est = DistanceEstimator(alpha: 0.3);
    final first = est.update(-59, -59); // 1 m
    expect(first, closeTo(1.0, 1e-9));

    // Sudden noisy spike to ~10 m only moves the smoothed value 30% of the way.
    final second = est.update(-79, -59);
    expect(second, closeTo(0.3 * 10 + 0.7 * 1, 1e-6));
    expect(est.meters, second);
  });

  test('reset forgets the EMA state', () {
    final est = DistanceEstimator();
    est.update(-59, -59);
    est.reset();
    expect(est.meters, isNull);
    expect(est.update(-79, -59), closeTo(10.0, 1e-6));
  });
}
