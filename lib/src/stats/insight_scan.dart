import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';
import 'package:kuhylog/src/stats/correlation.dart';

/// One relationship the scan considered worth reporting.
class Insight {
  /// Creates an insight.
  const Insight({
    required this.sourceTag,
    required this.targetTag,
    required this.lagDays,
    required this.coefficient,
    required this.pValue,
    required this.sampleSize,
    required this.significant,
  });

  /// Tag of the tracker on the left of the relationship.
  final String sourceTag;

  /// Tag of the tracker on the right of the relationship.
  final String targetTag;

  /// How many days the target was shifted forward.
  final int lagDays;

  /// The Spearman coefficient, between -1 and 1.
  final double coefficient;

  /// Two-sided p-value before correction.
  final double pValue;

  /// Number of day pairs the coefficient was computed from.
  final int sampleSize;

  /// Whether this survived the false-discovery correction.
  final bool significant;

  /// Whether the relationship points the same way for both trackers.
  bool get isPositive => coefficient > 0;

  /// A one line description in plain words.
  String get summary {
    final direction = isPositive ? 'higher' : 'lower';
    final when = lagDays == 0
        ? 'the same day'
        : lagDays == 1
        ? 'the next day'
        : '$lagDays days later';
    return '#$sourceTag goes with $direction #$targetTag $when';
  }

  @override
  String toString() => 'Insight($sourceTag -> $targetTag @$lagDays)';
}

/// Searches every tracker pair for a lagged relationship.
///
/// The three guards below are what separate this from a random number
/// generator, and none of them are optional:
///
/// * a minimum sample size, because ten days of data cannot support a
///   claim about your sleep;
/// * a Benjamini-Hochberg correction, because scanning many pairs makes
///   a spurious hit near certain;
/// * ranks rather than raw values, because self-tracked scales are
///   ordinal and full of outliers.
///
/// Even with all three, day-to-day self-tracking is autocorrelated,
/// which inflates significance. Treat output as a prompt to run an
/// experiment, never as evidence on its own.
class InsightScan {
  /// Creates a scan.
  const InsightScan({
    this.minimumDays = 21,
    this.lags = const <int>[0, 1, 2],
    this.alpha = 0.05,
  });

  /// The fewest overlapping days a pair needs to be considered.
  final int minimumDays;

  /// The day shifts to test for each ordered pair.
  final List<int> lags;

  /// The false discovery rate the correction targets.
  final double alpha;

  /// Runs the scan over [trackers] between [from] and [to].
  ///
  /// Results are ordered strongest first. Pairs that fail the minimum
  /// sample size are dropped silently; a pair with no variance yields no
  /// coefficient and is likewise dropped.
  List<Insight> run(
    List<Tracker> trackers,
    List<LogEntry> entries,
    DateTime from,
    DateTime to,
  ) {
    final series = <String, List<double>>{};
    for (final tracker in trackers) {
      final byDay = Aggregate.byDay(tracker, entries);
      if (byDay.isEmpty) {
        continue;
      }
      series[tracker.tag] = Aggregate.fillGaps(byDay, from, to);
    }
    final tags = series.keys.toList();
    final found = <Insight>[];
    for (final source in tags) {
      for (final target in tags) {
        for (final lag in lags) {
          if (source == target && lag == 0) {
            continue;
          }
          final xs = series[source]!;
          final ys = series[target]!;
          final size = xs.length - lag;
          if (size < minimumDays) {
            continue;
          }
          final coefficient = Correlation.lagged(xs, ys, lag);
          if (coefficient == null) {
            continue;
          }
          found.add(
            Insight(
              sourceTag: source,
              targetTag: target,
              lagDays: lag,
              coefficient: coefficient,
              pValue: Correlation.pValue(coefficient, size),
              sampleSize: size,
              significant: false,
            ),
          );
        }
      }
    }
    final cutoff = Correlation.falseDiscoveryCutoff(
      <double>[for (final insight in found) insight.pValue],
      alpha: alpha,
    );
    final results =
        <Insight>[
          for (final insight in found)
            Insight(
              sourceTag: insight.sourceTag,
              targetTag: insight.targetTag,
              lagDays: insight.lagDays,
              coefficient: insight.coefficient,
              pValue: insight.pValue,
              sampleSize: insight.sampleSize,
              significant: cutoff != null && insight.pValue <= cutoff,
            ),
        ]..sort(
          (a, b) => b.coefficient.abs().compareTo(a.coefficient.abs()),
        );
    return results;
  }
}
