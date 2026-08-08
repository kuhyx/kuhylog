import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/trackable_ref.dart';
import 'package:kuhylog/src/model/trackable_type.dart';

void main() {
  group('TrackableRef', () {
    const withValue = TrackableRef(
      type: TrackableType.tracker,
      id: 'sleep',
      raw: '#sleep(7)',
      rawValue: '7',
      value: 7,
    );
    const bare = TrackableRef(
      type: TrackableType.person,
      id: 'ola',
      raw: '@ola',
    );

    test('tag, hasValue and toString', () {
      expect(withValue.tag, '#sleep');
      expect(withValue.hasValue, isTrue);
      expect(withValue.toString(), '#sleep(7.0)');
      expect(bare.tag, '@ola');
      expect(bare.hasValue, isFalse);
      expect(bare.toString(), '@ola');
    });

    test('equality and hashCode', () {
      const same = TrackableRef(
        type: TrackableType.tracker,
        id: 'sleep',
        raw: '#sleep(7)',
        rawValue: '7',
        value: 7,
      );
      expect(withValue, same);
      expect(withValue.hashCode, same.hashCode);
      expect(withValue == bare, isFalse);
      expect(withValue == Object(), isFalse);
    });
  });
}
