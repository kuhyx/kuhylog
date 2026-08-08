/// A tiny arithmetic evaluator for values written inside a note.
///
/// Notes may carry a small calculation instead of a literal, for example
/// `#beer(3*0.5)`. Evaluating that with a real expression engine would
/// mean shipping a dependency and an injection surface, so this handles
/// exactly five operators, parentheses and unary sign, and nothing else.
///
/// Whitespace is stripped before parsing rather than treated as a
/// separator, so `1 2` evaluates to twelve. Values reach this code from
/// inside `#tag(...)`, where a space-separated pair of numbers has no
/// meaning anyway, and the alternative costs a token stream.
abstract final class MathEval {
  /// Evaluates [source], returning `null` when it is not a valid
  /// expression or does not produce a finite number.
  static double? tryEval(String source) {
    final parser = _Parser(source);
    final value = parser.parseExpression();
    if (value == null || !parser.atEnd) {
      return null;
    }
    return value.isFinite ? value : null;
  }
}

class _Parser {
  _Parser(String source) : _source = source.replaceAll(' ', '');

  final String _source;
  int _index = 0;

  bool get atEnd => _index >= _source.length;

  String? get _peek => atEnd ? null : _source[_index];

  double? parseExpression() {
    var left = _parseTerm();
    if (left == null) {
      return null;
    }
    while (_peek == '+' || _peek == '-') {
      final operator = _source[_index];
      _index++;
      final right = _parseTerm();
      if (right == null) {
        return null;
      }
      left = operator == '+' ? left! + right : left! - right;
    }
    return left;
  }

  double? _parseTerm() {
    var left = _parseUnary();
    if (left == null) {
      return null;
    }
    while (_peek == '*' || _peek == '/' || _peek == '%') {
      final operator = _source[_index];
      _index++;
      final right = _parseUnary();
      if (right == null) {
        return null;
      }
      switch (operator) {
        case '*':
          left = left! * right;
        case '/':
          left = left! / right;
        default:
          left = left! % right;
      }
    }
    return left;
  }

  double? _parseUnary() {
    if (_peek == '-') {
      _index++;
      final value = _parseUnary();
      return value == null ? null : -value;
    }
    if (_peek == '+') {
      _index++;
      return _parseUnary();
    }
    return _parsePrimary();
  }

  double? _parsePrimary() {
    if (_peek == '(') {
      _index++;
      final value = parseExpression();
      if (value == null || _peek != ')') {
        return null;
      }
      _index++;
      return value;
    }
    final start = _index;
    while (!atEnd && _isNumberChar(_source[_index])) {
      _index++;
    }
    if (start == _index) {
      return null;
    }
    return double.tryParse(_source.substring(start, _index));
  }

  static bool _isNumberChar(String character) {
    return (character.compareTo('0') >= 0 && character.compareTo('9') <= 0) ||
        character == '.';
  }
}
