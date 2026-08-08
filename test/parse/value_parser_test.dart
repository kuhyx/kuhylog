import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/parse/value_parser.dart';

void main() {
  group('ValueParser', () {
    test('parses plain numbers', () {
      expect(ValueParser.parse('7.5'), 7.5);
      expect(ValueParser.parse(' 3 '), 3);
    });

    test('parses durations', () {
      expect(ValueParser.parse('1:30'), 90);
      expect(ValueParser.parse('1:00:30'), 3630);
    });

    test('does not range check duration components', () {
      expect(ValueParser.parseDuration('6:43:99'), 6 * 3600 + 43 * 60 + 99);
    });

    test('rejects malformed durations', () {
      expect(ValueParser.parseDuration('1'), isNull);
      expect(ValueParser.parseDuration('1:2:3:4'), isNull);
      expect(ValueParser.parseDuration('a:b'), isNull);
      expect(ValueParser.parse('1:x'), isNull);
    });

    test('falls back to arithmetic', () {
      expect(ValueParser.parse('3*0.5'), 1.5);
    });

    test('empty and unparseable input is null', () {
      expect(ValueParser.parse(''), isNull);
      expect(ValueParser.parse('   '), isNull);
      expect(ValueParser.parse('nope'), isNull);
    });
  });
}
