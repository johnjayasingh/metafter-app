import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/proximity/direction_estimator.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';

void main() {
  test('closing distance while facing one way → bearing settles near ahead',
      () async {
    final meters = StreamController<double>();
    final heading = StreamController<double>();
    final estimator = DirectionEstimator(
      meters: meters.stream,
      heading: heading.stream,
      gradientWindow: const Duration(seconds: 30), // generous for fake time
      slopeThreshold: 0.01,
    );

    final samples = <RangeSample>[];
    final done = estimator.stream.listen(samples.add).asFuture<void>();

    heading.add(0.8); // facing a fixed direction
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Walk toward the peer: distance strictly shrinking.
    for (var i = 0; i < 20; i++) {
      meters.add(10.0 - i * 0.4);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await meters.close();
    await done;
    await heading.close();

    expect(samples, isNotEmpty);
    expect(samples.length, 20);
    // While approaching, "toward" is the current heading → relative bearing
    // should settle near 0 (straight ahead).
    expect(samples.last.bearing.abs(), lessThan(0.5));
    expect(samples.last.meters, closeTo(10.0 - 19 * 0.4, 1e-9));
  });

  test('opening distance → bearing flips toward behind (|bearing| near π)',
      () async {
    final meters = StreamController<double>();
    final heading = StreamController<double>();
    final estimator = DirectionEstimator(
      meters: meters.stream,
      heading: heading.stream,
      gradientWindow: const Duration(seconds: 30),
      slopeThreshold: 0.01,
    );

    final samples = <RangeSample>[];
    final done = estimator.stream.listen(samples.add).asFuture<void>();

    heading.add(-1.2);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Walking away: distance strictly growing.
    for (var i = 0; i < 24; i++) {
      meters.add(2.0 + i * 0.4);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await meters.close();
    await done;
    await heading.close();

    expect(samples, isNotEmpty);
    expect(samples.last.bearing.abs(), greaterThan(math.pi / 2));
  });

  test('bearing output is always within (−π, π]', () async {
    final meters = StreamController<double>();
    final heading = StreamController<double>();
    final estimator = DirectionEstimator(
      meters: meters.stream,
      heading: heading.stream,
      gradientWindow: const Duration(seconds: 30),
      slopeThreshold: 0.01,
    );

    final samples = <RangeSample>[];
    final done = estimator.stream.listen(samples.add).asFuture<void>();

    // Spin while the distance wobbles.
    for (var i = 0; i < 30; i++) {
      heading.add(i * 0.7);
      meters.add(5.0 + math.sin(i / 3) * 2);
      await Future<void>.delayed(const Duration(milliseconds: 4));
    }
    await meters.close();
    await done;
    await heading.close();

    for (final s in samples) {
      expect(s.bearing, greaterThan(-math.pi - 1e-9));
      expect(s.bearing, lessThanOrEqualTo(math.pi + 1e-9));
    }
  });

  test('cancelling the subscription stops the estimator cleanly', () async {
    final meters = StreamController<double>();
    final heading = StreamController<double>();
    final estimator =
        DirectionEstimator(meters: meters.stream, heading: heading.stream);

    final sub = estimator.stream.listen((_) {});
    meters.add(3.0);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await sub.cancel();

    // Both upstream subscriptions are released → controllers can close.
    expect(meters.hasListener, isFalse);
    expect(heading.hasListener, isFalse);
    await meters.close();
    await heading.close();
  });
}
