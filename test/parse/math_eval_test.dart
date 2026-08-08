import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/parse/math_eval.dart';

void main() {
  group('MathEval', () {
    test('evaluates the four operators and precedence', () {
      expect(MathEval.tryEval('1+2'), 3);
      expect(MathEval.tryEval('5-2'), 3);
      expect(MathEval.tryEval('3*4'), 12);
      expect(MathEval.tryEval('9/2'), 4.5);
      expect(MathEval.tryEval('7%4'), 3);
      expect(MathEval.tryEval('2+3*4'), 14);
    });

    test('honours parentheses and ignores whitespace entirely', () {
      expect(MathEval.tryEval('(2+3) * 4'), 20);
      expect(MathEval.tryEval('1 2'), 12);
    });

    test('handles unary signs', () {
      expect(MathEval.tryEval('-3'), -3);
      expect(MathEval.tryEval('+3'), 3);
      expect(MathEval.tryEval('2 - -3'), 5);
    });

    test('rejects malformed input', () {
      expect(MathEval.tryEval(''), isNull);
      expect(MathEval.tryEval('1+'), isNull);
      expect(MathEval.tryEval('1*'), isNull);
      expect(MathEval.tryEval('(1+2'), isNull);
      expect(MathEval.tryEval('()'), isNull);
      expect(MathEval.tryEval('abc'), isNull);
      expect(MathEval.tryEval('-'), isNull);
      expect(MathEval.tryEval('1.2.3'), isNull);
    });

    test('rejects results that are not finite', () {
      expect(MathEval.tryEval('1/0'), isNull);
    });
  });
}
