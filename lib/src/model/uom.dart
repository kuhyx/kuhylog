/// Units of measure a tracker can record in.
///
/// The set is deliberately small and fixed: an open ended unit registry
/// makes aggregation and formatting untestable, and every unit here is
/// one a personal tracker realistically needs.
enum Uom {
  /// A dimensionless count of occurrences.
  count('', 'count'),

  /// Seconds, formatted as `h:mm:ss` when large enough.
  second('s', 'seconds'),

  /// Minutes.
  minute('min', 'minutes'),

  /// Hours.
  hour('h', 'hours'),

  /// Grams.
  gram('g', 'grams'),

  /// Kilograms.
  kilogram('kg', 'kilograms'),

  /// Millilitres.
  millilitre('ml', 'millilitres'),

  /// Litres.
  litre('l', 'litres'),

  /// Kilometres.
  kilometre('km', 'kilometres'),

  /// Steps.
  step('steps', 'steps'),

  /// Kilocalories.
  kcal('kcal', 'kilocalories'),

  /// Polish zloty.
  zloty('zl', 'zloty'),

  /// A percentage.
  percent('%', 'percent'),

  /// Pages.
  page('pp', 'pages');

  const Uom(this.symbol, this.label);

  /// Short suffix shown next to a value.
  final String symbol;

  /// Human readable name of the unit.
  final String label;

  /// Formats [value] for display, including the unit symbol.
  ///
  /// [Uom.second] is rendered as a clock duration; everything else is
  /// rendered as a number with at most two decimal places.
  String format(double value) {
    if (this == Uom.second) {
      return formatDuration(value);
    }
    final rounded = (value * 100).roundToDouble() / 100;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
    return symbol.isEmpty ? text : '$text $symbol';
  }

  /// Formats [seconds] as `h:mm:ss`, or `m:ss` when under an hour.
  static String formatDuration(double seconds) {
    final total = seconds.abs().round();
    final sign = seconds < 0 ? '-' : '';
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$sign$h:$mm:$ss' : '$sign$m:$ss';
  }

  /// Returns the unit whose [name] matches [value], or [Uom.count].
  static Uom parse(String value) {
    for (final unit in Uom.values) {
      if (unit.name == value) {
        return unit;
      }
    }
    return Uom.count;
  }
}
