import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/trackable_type.dart';

void main() {
  group('TrackableType', () {
    test('round trips through its sigil', () {
      for (final type in TrackableType.values) {
        expect(TrackableType.fromSigil(type.sigil), type);
      }
    });

    test('unknown sigils are null', () {
      expect(TrackableType.fromSigil('%'), isNull);
    });
  });
}
