import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/transport/relay_transport_client.dart';

void main() {
  group('RelayTransportClient.reconnectDelay', () {
    test('never leaves the 2s..60s window for any attempt/jitter', () {
      final rng = Random(42);
      for (var attempt = 0; attempt < 40; attempt++) {
        for (var i = 0; i < 20; i++) {
          final d =
              RelayTransportClient.reconnectDelay(attempt, rng.nextDouble());
          expect(d.inMilliseconds, greaterThanOrEqualTo(2000),
              reason: 'attempt $attempt');
          expect(d.inMilliseconds, lessThanOrEqualTo(60000),
              reason: 'attempt $attempt');
        }
      }
    });

    test('first attempt is the 2s floor', () {
      expect(RelayTransportClient.reconnectDelay(0, 0.0),
          const Duration(seconds: 2));
      expect(RelayTransportClient.reconnectDelay(0, 1.0),
          const Duration(seconds: 2));
    });

    test('grows exponentially with the attempt count (full jitter = base)',
        () {
      expect(RelayTransportClient.reconnectDelay(1, 1.0),
          const Duration(seconds: 4));
      expect(RelayTransportClient.reconnectDelay(2, 1.0),
          const Duration(seconds: 8));
      expect(RelayTransportClient.reconnectDelay(3, 1.0),
          const Duration(seconds: 16));
      expect(RelayTransportClient.reconnectDelay(4, 1.0),
          const Duration(seconds: 32));
    });

    test('caps at 60s and stays capped for huge attempt counts', () {
      expect(RelayTransportClient.reconnectDelay(5, 1.0),
          const Duration(seconds: 60));
      expect(RelayTransportClient.reconnectDelay(30, 1.0),
          const Duration(seconds: 60));
      expect(RelayTransportClient.reconnectDelay(1000000, 1.0),
          const Duration(seconds: 60));
    });

    test('jitter spreads delays below the base (half at jitter 0)', () {
      expect(RelayTransportClient.reconnectDelay(3, 0.0),
          const Duration(seconds: 8)); // 16s base * 0.5
      expect(RelayTransportClient.reconnectDelay(3, 0.5),
          const Duration(seconds: 12)); // 16s base * 0.75
      // Two different jitters at the cap still differ (no lockstep).
      final a = RelayTransportClient.reconnectDelay(10, 0.1);
      final b = RelayTransportClient.reconnectDelay(10, 0.9);
      expect(a, isNot(equals(b)));
    });
  });
}
