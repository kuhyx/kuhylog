import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';

/// A run of consecutive days on which a goal was met.
@immutable
class Streak {
  /// Creates a streak.
  const Streak({required this.current, required this.longest});

  /// A streak of length zero.
  static const Streak none = Streak(current: 0, longest: 0);

  /// Days met up to and including today.
  final int current;

  /// The longest run ever recorded.
  final int longest;

  @override
  bool operator ==(Object other) =>
      other is Streak && other.current == current && other.longest == longest;

  @override
  int get hashCode => Object.hash(current, longest);

  @override
  String toString() => 'Streak(current: $current, longest: $longest)';
}

/// Computes streaks for a tracker against a daily threshold.
abstract final class Streaks {
  /// Returns the streak for [tracker] as of [today].
  ///
  /// A day counts when the aggregated value is at least [threshold].
  /// The current streak is measured backwards from [today]. A day that
  /// has not been logged at all does not break it, so checking your
  /// streak in the morning does not zero it; a day that *was* logged but
  /// fell short of [threshold] does break it, because that is a miss.
  static Streak of(
    Tracker tracker,
    List<LogEntry> entries,
    DateTime today, {
    double threshold = 1,
  }) {
    final byDay = Aggregate.byDay(tracker, entries);
    if (byDay.isEmpty) {
      return Streak.none;
    }
    final met = <DateTime>{};
    for (final entry in byDay.entries) {
      if (entry.value >= threshold) {
        met.add(entry.key);
      }
    }
    if (met.isEmpty) {
      return Streak.none;
    }
    final sorted = met.toList()..sort((a, b) => a.compareTo(b));
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (_isNextDay(sorted[i - 1], sorted[i])) {
        run++;
        if (run > longest) {
          longest = run;
        }
      } else {
        run = 1;
      }
    }
    final start = DateTime(today.year, today.month, today.day);
    if (!met.contains(start) && byDay.containsKey(start)) {
      return Streak(current: 0, longest: longest);
    }
    var cursor = met.contains(start)
        ? start
        : DateTime(start.year, start.month, start.day - 1);
    var current = 0;
    while (met.contains(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return Streak(current: current, longest: longest);
  }

  static bool _isNextDay(DateTime a, DateTime b) {
    final next = DateTime(a.year, a.month, a.day + 1);
    return next == b;
  }
}
