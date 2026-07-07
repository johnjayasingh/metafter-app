import 'dart:math' as math;

/// RSSI → meters estimation for BLE sightings (ARCHITECTURE.md §2.4).
///
/// Uses the classic log-distance path-loss model:
///
///     meters = 10 ^ ((txPowerAt1m − rssi) / (10 · n))
///
/// where `txPowerAt1m` is the calibrated RSSI at one meter carried in the
/// advertisement (byte 10 of the service data) and `n` is the path-loss
/// exponent (≈2.0 free space, higher indoors). Raw BLE RSSI is noisy, so the
/// per-peer estimate is smoothed with an exponential moving average.
///
/// One instance per sighted peer — the EMA state is per-device.
class DistanceEstimator {
  DistanceEstimator({
    this.alpha = 0.3,
    this.pathLossExponent = 2.0,
    this.minMeters = 0.1,
    this.maxMeters = 50.0,
  });

  /// EMA weight of the newest raw sample (0 < alpha ≤ 1). Higher = snappier,
  /// lower = smoother.
  final double alpha;

  /// Environment path-loss exponent `n` (2.0 free space, 2.5–4 indoors).
  final double pathLossExponent;

  /// Clamp floor for the estimate — BLE can't resolve closer than this.
  final double minMeters;

  /// Clamp ceiling for the estimate.
  final double maxMeters;

  double? _smoothed;

  /// Latest smoothed estimate, or null before the first [update].
  double? get meters => _smoothed;

  /// Feed one advertisement sighting; returns the new smoothed estimate.
  double update(int rssi, int txPowerAt1m) {
    final raw = estimate(
      rssi,
      txPowerAt1m,
      pathLossExponent: pathLossExponent,
      minMeters: minMeters,
      maxMeters: maxMeters,
    );
    final prev = _smoothed;
    _smoothed = prev == null ? raw : alpha * raw + (1 - alpha) * prev;
    return _smoothed!;
  }

  /// Forget the EMA state (e.g. after the peer expired and reappeared).
  void reset() => _smoothed = null;

  /// One-shot (unsmoothed) log-distance estimate.
  static double estimate(
    int rssi,
    int txPowerAt1m, {
    double pathLossExponent = 2.0,
    double minMeters = 0.1,
    double maxMeters = 50.0,
  }) {
    final ratio = (txPowerAt1m - rssi) / (10 * pathLossExponent);
    final raw = math.pow(10.0, ratio).toDouble();
    return raw.clamp(minMeters, maxMeters);
  }
}
