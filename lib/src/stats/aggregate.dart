import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';

/// Collapses entries into one number per day for a single tracker.
///
/// Honours the tracker's own rules: [TrackerMath] decides whether a day
/// is a sum or a mean, [Tracker.defaultValue] supplies the value for a
/// bare mention, and [Tracker.ignoreZero] drops zeroes so they neither
/// count towards a mean nor create a false "logged" day.
abstract final class Aggregate {
  /// Values per calendar day, keyed by local midnight.
  ///
  /// Days with no mention of the tracker are absent rather than zero;
  /// use [fillGaps] when a dense series is needed.
  static Map<DateTime, double> byDay(
    Tracker tracker,
    List<LogEntry> entries,
  ) {
    final sums = <DateTime, double>{};
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      final values = NoteTokenizer.trackerValues(
        entry.note,
        fallback: tracker.defaultValue,
      );
      final value = values[tracker.tag];
      if (value == null) {
        continue;
      }
      if (tracker.ignoreZero && value == 0) {
        continue;
      }
      sums[entry.day] = (sums[entry.day] ?? 0) + value;
      counts[entry.day] = (counts[entry.day] ?? 0) + 1;
    }
    if (tracker.math == TrackerMath.sum) {
      return sums;
    }
    return <DateTime, double>{
      for (final day in sums.keys) day: sums[day]! / counts[day]!,
    };
  }

  /// Returns a dense day-by-day series between [from] and [to].
  ///
  /// Missing days become [missing], which is zero by default because a
  /// day you did not log a habit is a day you did not do it.
  static List<double> fillGaps(
    Map<DateTime, double> values,
    DateTime from,
    DateTime to, {
    double missing = 0,
  }) {
    final series = <double>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final last = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(last)) {
      series.add(values[cursor] ?? missing);
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return series;
  }

  /// The total across every day.
  static double total(Map<DateTime, double> values) {
    var sum = 0.0;
    for (final value in values.values) {
      sum += value;
    }
    return sum;
  }

  /// The mean across days that have a value, zero when there are none.
  static double mean(Map<DateTime, double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return total(values) / values.length;
  }
}
