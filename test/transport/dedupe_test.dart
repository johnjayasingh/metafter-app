import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/transport/relay_transport_client.dart';

void main() {
  group('LruIdSet', () {
    test('first sight returns true, duplicate returns false', () {
      final set = LruIdSet();
      expect(set.add('a'), isTrue);
      expect(set.add('a'), isFalse);
      expect(set.add('b'), isTrue);
      expect(set.add('a'), isFalse);
      expect(set.length, 2);
    });

    test('evicts the least-recently-seen id past capacity', () {
      final set = LruIdSet(capacity: 3);
      set.add('a');
      set.add('b');
      set.add('c');
      set.add('d'); // evicts 'a'
      expect(set.contains('a'), isFalse);
      expect(set.contains('b'), isTrue);
      expect(set.length, 3);
      // 'a' is forgotten, so it reads as new again.
      expect(set.add('a'), isTrue);
    });

    test('re-seeing an id refreshes its recency', () {
      final set = LruIdSet(capacity: 3);
      set.add('a');
      set.add('b');
      set.add('c');
      expect(set.add('a'), isFalse); // refresh: 'b' is now oldest
      set.add('d'); // evicts 'b', not 'a'
      expect(set.contains('a'), isTrue);
      expect(set.contains('b'), isFalse);
    });

    test('holds ~500 ids by default without evicting', () {
      final set = LruIdSet();
      for (var i = 0; i < 500; i++) {
        expect(set.add('id-$i'), isTrue);
      }
      expect(set.length, 500);
      expect(set.add('id-0'), isFalse); // still remembered
      expect(set.add('id-500'), isTrue); // now id-1 (oldest) is evicted
      expect(set.contains('id-1'), isFalse);
      expect(set.length, 500);
    });
  });
}
