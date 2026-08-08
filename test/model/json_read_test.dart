import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/json_read.dart';

void main() {
  group('JsonRead', () {
    test('string reads text, numbers and booleans', () {
      final json = <String, dynamic>{'a': 'x', 'b': 2, 'c': true, 'd': null};
      expect(JsonRead.string(json, 'a'), 'x');
      expect(JsonRead.string(json, 'b'), '2');
      expect(JsonRead.string(json, 'c'), 'true');
      expect(JsonRead.string(json, 'd', fallback: 'z'), 'z');
      expect(JsonRead.string(json, 'missing'), '');
    });

    test('number reads numerics and numeric strings', () {
      final json = <String, dynamic>{'a': 3, 'b': '4.5', 'c': 'no'};
      expect(JsonRead.number(json, 'a'), 3);
      expect(JsonRead.number(json, 'b'), 4.5);
      expect(JsonRead.number(json, 'c', fallback: 9), 9);
      expect(JsonRead.number(json, 'missing'), 0);
    });

    test('maybeNumber distinguishes absent from zero', () {
      final json = <String, dynamic>{'a': 0, 'b': '1', 'c': 'no'};
      expect(JsonRead.maybeNumber(json, 'a'), 0);
      expect(JsonRead.maybeNumber(json, 'b'), 1);
      expect(JsonRead.maybeNumber(json, 'c'), isNull);
      expect(JsonRead.maybeNumber(json, 'missing'), isNull);
    });

    test('boolean reads bools, numbers and strings', () {
      final json = <String, dynamic>{
        'a': true,
        'b': 1,
        'c': 0,
        'd': 'true',
        'e': 'nope',
      };
      expect(JsonRead.boolean(json, 'a'), isTrue);
      expect(JsonRead.boolean(json, 'b'), isTrue);
      expect(JsonRead.boolean(json, 'c'), isFalse);
      expect(JsonRead.boolean(json, 'd'), isTrue);
      expect(JsonRead.boolean(json, 'e'), isFalse);
      expect(JsonRead.boolean(json, 'missing', fallback: true), isTrue);
    });

    test('stringList keeps strings and numbers only', () {
      final json = <String, dynamic>{
        'a': <dynamic>['x', 2, null, <String>[]],
        'b': 'not a list',
      };
      expect(JsonRead.stringList(json, 'a'), <String>['x', '2']);
      expect(JsonRead.stringList(json, 'b'), isEmpty);
    });

    test('object returns nested maps or an empty map', () {
      final json = <String, dynamic>{
        'a': <String, dynamic>{'x': 1},
        'b': 5,
      };
      expect(JsonRead.object(json, 'a'), <String, dynamic>{'x': 1});
      expect(JsonRead.object(json, 'b'), isEmpty);
    });

    test('objectList keeps maps only', () {
      final json = <String, dynamic>{
        'a': <dynamic>[
          <String, dynamic>{'x': 1},
          'skip',
        ],
        'b': 7,
      };
      expect(JsonRead.objectList(json, 'a'), hasLength(1));
      expect(JsonRead.objectList(json, 'b'), isEmpty);
    });

    test('firstKey finds the first present candidate', () {
      final json = <String, dynamic>{'second': 1};
      expect(JsonRead.firstKey(json, <String>['first', 'second']), 'second');
      expect(JsonRead.firstKey(json, <String>['nope']), isNull);
    });
  });
}
