import 'package:kuhylog/src/parse/math_eval.dart';

/// Turns the text inside `#tag(...)` into a number.
///
/// Three notations are accepted, tried in this order:
///
/// * a clock duration, `6:43` or `1:06:43`, producing seconds;
/// * a plain decimal number, `7.5`;
/// * a small arithmetic expression, `3*0.5`.
abstract final class ValueParser {
  /// Parses [source], returning `null` when nothing sensible is written.
  static double? parse(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains(':')) {
      return parseDuration(trimmed);
    }
    final literal = double.tryParse(trimmed);
    if (literal != null) {
      return literal;
    }
    return MathEval.tryEval(trimmed);
  }

  /// Parses `mm:ss` or `hh:mm:ss` into seconds.
  ///
  /// Returns `null` if the shape is wrong or a component is not an
  /// integer. Components are not range checked, so `0:99` is 99 seconds,
  /// which matches how such values were written in practice.
  static double? parseDuration(String source) {
    final parts = source.split(':');
    if (parts.length < 2 || parts.length > 3) {
      return null;
    }
    final numbers = <int>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed == null) {
        return null;
      }
      numbers.add(parsed);
    }
    if (numbers.length == 2) {
      return (numbers[0] * 60 + numbers[1]).toDouble();
    }
    return (numbers[0] * 3600 + numbers[1] * 60 + numbers[2]).toDouble();
  }
}
