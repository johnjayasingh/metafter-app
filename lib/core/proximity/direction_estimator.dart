import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'proximity_engine.dart';

/// Hot/cold direction estimator for the Find Person screen (DESIGN_SPEC §8).
///
/// ## How it works — and how honest it is
///
/// Phones cannot measure BLE angle-of-arrival, so there is **no real bearing
/// measurement** here. Instead we fuse two weak signals:
///
///  1. A short sliding window (~3 s) of distance estimates. Its slope tells
///     us whether the user is getting *warmer* (closing) or *colder*
///     (opening) — nothing more.
///  2. The compass heading from the magnetometer (tilt-uncompensated
///     `atan2(y, x)` — coarse, but adequate for a guided experience).
///
/// The heuristic: while the distance is clearly shrinking, the direction the
/// user is currently facing is remembered as "toward the peer"; while it is
/// clearly growing, the opposite of the current heading is. Between those
/// two states the last belief is kept. The belief and the emitted bearing are
/// both low-pass filtered so the arrow eases rather than jumping.
///
/// Expected accuracy is "which quadrant, eventually" — the UI copy ("to your
/// right" / "ahead" / "behind you") is deliberately coarse and the flow is a
/// warmer/colder game, not turn-by-turn navigation. Standing still gives no
/// gradient, so the arrow simply holds its last estimate.
class DirectionEstimator {
  /// [meters] — smoothed distance stream for the peer (from the engine).
  /// [heading] — device compass heading in radians; defaults to a
  /// magnetometer-derived heading (tests inject a fake stream).
  DirectionEstimator({
    required Stream<double> meters,
    Stream<double>? heading,
    this.gradientWindow = const Duration(seconds: 3),
    this.slopeThreshold = 0.05,
  })  : _meters = meters,
        _heading = heading ?? _magnetometerHeading();

  final Stream<double> _meters;
  final Stream<double> _heading;

  /// Sliding window over which the distance slope is evaluated.
  final Duration gradientWindow;

  /// Minimum |slope| in m/s before we trust the warmer/colder signal.
  final double slopeThreshold;

  static const double _headingAlpha = 0.25;
  static const double _towardAlpha = 0.2;
  static const double _bearingAlpha = 0.3;

  /// Coarse compass heading (radians) from the raw magnetic field. This is
  /// not tilt-compensated: it assumes the phone is held roughly flat, which
  /// matches how people hold a phone while following an arrow.
  static Stream<double> _magnetometerHeading() {
    try {
      return magnetometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).map((e) => math.atan2(e.y, e.x));
    } catch (_) {
      // No magnetometer (simulator) — a constant heading degrades the
      // estimator to distance-only, which is still a usable hot/cold UI.
      return Stream<double>.periodic(
          const Duration(milliseconds: 200), (_) => 0.0);
    }
  }

  /// Fused range samples. Emits once per distance sample; completes when the
  /// distance stream completes. Single-subscription.
  Stream<RangeSample> get stream {
    late StreamController<RangeSample> ctrl;
    StreamSubscription<double>? metersSub;
    StreamSubscription<double>? headingSub;

    // Circular low-pass state for the current compass heading.
    double hx = 1.0, hy = 0.0;
    var haveHeading = false;

    // Belief about the world-frame direction toward the peer.
    double tx = 1.0, ty = 0.0;
    var haveToward = false;

    double? smoothedBearing;
    final window = <(DateTime, double)>[];

    double currentHeading() => math.atan2(hy, hx);

    void updateToward(double angle, double alpha) {
      if (!haveToward) {
        tx = math.cos(angle);
        ty = math.sin(angle);
        haveToward = true;
      } else {
        tx = (1 - alpha) * tx + alpha * math.cos(angle);
        ty = (1 - alpha) * ty + alpha * math.sin(angle);
      }
    }

    double? slope() {
      if (window.length < 3) return null;
      // Least-squares slope of meters over seconds within the window.
      final t0 = window.first.$1;
      var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
      for (final (t, m) in window) {
        final x = t.difference(t0).inMilliseconds / 1000.0;
        sx += x;
        sy += m;
        sxx += x * x;
        sxy += x * m;
      }
      final n = window.length;
      final denom = n * sxx - sx * sx;
      if (denom.abs() < 1e-9) return null;
      return (n * sxy - sx * sy) / denom;
    }

    void onMeters(double m) {
      final now = DateTime.now();
      window.add((now, m));
      window.removeWhere((s) => now.difference(s.$1) > gradientWindow);

      final s = slope();
      if (s != null && haveHeading) {
        if (s < -slopeThreshold) {
          // Getting warmer — I'm walking toward the peer.
          updateToward(currentHeading(), _towardAlpha);
        } else if (s > slopeThreshold) {
          // Getting colder — the peer is behind me.
          updateToward(currentHeading() + math.pi, _towardAlpha);
        }
      }

      var bearing = 0.0;
      if (haveToward && haveHeading) {
        bearing = _wrap(math.atan2(ty, tx) - currentHeading());
      }
      final prev = smoothedBearing;
      smoothedBearing = prev == null
          ? bearing
          : prev + _bearingAlpha * _wrap(bearing - prev);

      if (!ctrl.isClosed) {
        ctrl.add(RangeSample(meters: m, bearing: _wrap(smoothedBearing!)));
      }
    }

    ctrl = StreamController<RangeSample>(
      onListen: () {
        headingSub = _heading.listen((h) {
          if (!haveHeading) {
            hx = math.cos(h);
            hy = math.sin(h);
            haveHeading = true;
          } else {
            hx = (1 - _headingAlpha) * hx + _headingAlpha * math.cos(h);
            hy = (1 - _headingAlpha) * hy + _headingAlpha * math.sin(h);
          }
        }, onError: (Object _) {
          // Sensor unavailable — keep going distance-only.
        });
        metersSub = _meters.listen(
          onMeters,
          onError: ctrl.addError,
          onDone: ctrl.close,
        );
      },
      onCancel: () async {
        await metersSub?.cancel();
        await headingSub?.cancel();
      },
    );
    return ctrl.stream;
  }

  /// Wrap an angle to (−π, π].
  static double _wrap(double a) {
    var r = a % (2 * math.pi);
    if (r > math.pi) r -= 2 * math.pi;
    if (r <= -math.pi) r += 2 * math.pi;
    return r;
  }
}
