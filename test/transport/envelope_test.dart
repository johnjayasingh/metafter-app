import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/transport/envelope.dart';

void main() {
  const envelope = Envelope(
    id: 'e3c1b9a0-5d7f-4a2b-9c8d-1f2e3d4c5b6a',
    to: 'sub-recipient-123',
    kind: EnvelopeKind.message,
    ephPub: 'ZXBoZW1lcmFsLXB1Yg==',
    nonce: 'bm9uY2U=',
    ciphertext: 'Y2lwaGVydGV4dA==',
  );

  group('Envelope JSON', () {
    test('toJson uses the wire field names from ARCHITECTURE.md §4.1', () {
      expect(envelope.toJson(), {
        'v': 1,
        'id': 'e3c1b9a0-5d7f-4a2b-9c8d-1f2e3d4c5b6a',
        'to': 'sub-recipient-123',
        'kind': 'message',
        'eph': 'ZXBoZW1lcmFsLXB1Yg==',
        'n': 'bm9uY2U=',
        'ct': 'Y2lwaGVydGV4dA==',
      });
    });

    test('fromJson(toJson) round-trips every field', () {
      final back = Envelope.fromJson(envelope.toJson());
      expect(back.v, envelope.v);
      expect(back.id, envelope.id);
      expect(back.to, envelope.to);
      expect(back.kind, envelope.kind);
      expect(back.ephPub, envelope.ephPub);
      expect(back.nonce, envelope.nonce);
      expect(back.ciphertext, envelope.ciphertext);
    });

    test('decode(encode) round-trips through a JSON string', () {
      final back = Envelope.decode(envelope.encode());
      expect(back.toJson(), envelope.toJson());
      // encode() must itself be valid JSON.
      expect(jsonDecode(envelope.encode()), isA<Map<String, dynamic>>());
    });

    test('fromJson defaults a missing version to 1', () {
      final json = envelope.toJson()..remove('v');
      expect(Envelope.fromJson(json).v, 1);
    });
  });
}
