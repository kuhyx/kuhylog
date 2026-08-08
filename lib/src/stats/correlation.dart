import 'dart:math';

/// Correlation utilities for self-tracked series.
///
/// These exist so the stats screen can say something more useful than
/// "here is a bar chart". They are also the easiest place in the app to
/// mislead yourself, so every result carries the sample size it was
/// computed from and the scan applies a false-discovery correction.
abstract final class Correlation {
  /// Pearson product-moment correlation of two equal-length series.
  ///
  /// Returns `null` when the series are too short or either has no
  /// variance, both of which make the coefficient undefined rather than
  /// zero.
  static double? pearson(List<double> xs, List<double> ys) {
    if (xs.length != ys.length || xs.length < 3) {
      return null;
    }
    final n = xs.length;
    var sumX = 0.0;
    var sumY = 0.0;
    for (var i = 0; i < n; i++) {
      sumX += xs[i];
      sumY += ys[i];
    }
    final meanX = sumX / n;
    final meanY = sumY / n;
    var covariance = 0.0;
    var varianceX = 0.0;
    var varianceY = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - meanX;
      final dy = ys[i] - meanY;
      covariance += dx * dy;
      varianceX += dx * dx;
      varianceY += dy * dy;
    }
    if (varianceX == 0 || varianceY == 0) {
      return null;
    }
    return covariance / sqrt(varianceX * varianceY);
  }

  /// Spearman rank correlation, which tolerates non-linear but
  /// monotonic relationships and ordinal scales such as a mood slider.
  static double? spearman(List<double> xs, List<double> ys) {
    if (xs.length != ys.length || xs.length < 3) {
      return null;
    }
    return pearson(rank(xs), rank(ys));
  }

  /// Returns the fractional ranks of [values], averaging ties.
  static List<double> rank(List<double> values) {
    final order = List<int>.generate(values.length, (i) => i)
      ..sort((a, b) => values[a].compareTo(values[b]));
    final ranks = List<double>.filled(values.length, 0);
    var i = 0;
    while (i < order.length) {
      var j = i;
      while (j + 1 < order.length && values[order[j + 1]] == values[order[i]]) {
        j++;
      }
      final average = (i + j) / 2 + 1;
      for (var k = i; k <= j; k++) {
        ranks[order[k]] = average;
      }
      i = j + 1;
    }
    return ranks;
  }

  /// Correlates [xs] against [ys] shifted forward by [lag] days.
  ///
  /// A positive [lag] answers "does today's x go with x days later y",
  /// which is the shape most self-tracking questions actually have.
  static double? lagged(List<double> xs, List<double> ys, int lag) {
    if (lag < 0 || lag >= xs.length || xs.length != ys.length) {
      return null;
    }
    final left = xs.sublist(0, xs.length - lag);
    final right = ys.sublist(lag);
    return spearman(left, right);
  }

  /// A two-sided p-value for a correlation coefficient.
  ///
  /// Uses the normal approximation to Fisher's z transform, which is
  /// adequate above roughly ten samples and avoids shipping a t
  /// distribution.
  static double pValue(double coefficient, int n) {
    if (n < 4) {
      return 1;
    }
    final bounded = coefficient.clamp(-0.999999, 0.999999);
    final z = 0.5 * log((1 + bounded) / (1 - bounded)) * sqrt(n - 3);
    return 2 * (1 - _standardNormalCdf(z.abs()));
  }

  static double _standardNormalCdf(double z) {
    return 0.5 * (1 + _erf(z / sqrt2));
  }

  /// Abramowitz and Stegun 7.1.26, accurate to about 1.5e-7.
  static double _erf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final sign = x < 0 ? -1.0 : 1.0;
    final value = x.abs();
    final t = 1.0 / (1.0 + p * value);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            exp(-value * value);
    return sign * y;
  }

  /// Benjamini-Hochberg step-up procedure.
  ///
  /// Returns the largest p-value that is still significant at [alpha]
  /// after correcting for [pValues].length comparisons, or `null` when
  /// nothing survives. Without this, scanning twenty tracker pairs is
  /// expected to produce one "finding" from pure noise.
  static double? falseDiscoveryCutoff(
    List<double> pValues, {
    double alpha = 0.05,
  }) {
    if (pValues.isEmpty) {
      return null;
    }
    final sorted = List<double>.from(pValues)..sort();
    double? cutoff;
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i] <= alpha * (i + 1) / sorted.length) {
        cutoff = sorted[i];
      }
    }
    return cutoff;
  }
}
