import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/model/tracker.dart';

/// Turns entries into a signed "was today good" number.
///
/// Every tracker carries a positivity from -5 to 5. An entry's score is
/// the sum of the positivity of each tracker it mentions, counted once
/// per mention. This is deliberately a tally and not a model: the number
/// is only meaningful relative to other days of the same person.
class Scoring {
  /// Creates a scorer over a fixed tracker configuration.
  Scoring(List<Tracker> trackers)
    : _positivity = <String, int>{
        for (final tracker in trackers) tracker.tag: tracker.positivity,
      };

  final Map<String, int> _positivity;

  /// The score of a single entry.
  int scoreOf(LogEntry entry) {
    var total = 0;
    for (final ref in entry.refs) {
      if (ref.type == TrackableType.tracker) {
        total += _positivity[ref.id] ?? 0;
      }
    }
    return total;
  }

  /// Scores per calendar day, keyed by local midnight.
  Map<DateTime, int> dailyScores(List<LogEntry> entries) {
    final scores = <DateTime, int>{};
    for (final entry in entries) {
      scores[entry.day] = (scores[entry.day] ?? 0) + scoreOf(entry);
    }
    return scores;
  }

  /// Counts of positive, neutral and negative entries.
  ///
  /// Feeds the pie on the stats screen; the three counts always sum to
  /// `entries.length`.
  ScoreSplit split(List<LogEntry> entries) {
    var positive = 0;
    var neutral = 0;
    var negative = 0;
    for (final entry in entries) {
      final score = scoreOf(entry);
      if (score > 0) {
        positive++;
      } else if (score < 0) {
        negative++;
      } else {
        neutral++;
      }
    }
    return ScoreSplit(
      positive: positive,
      neutral: neutral,
      negative: negative,
    );
  }
}

/// How many entries fell on each side of neutral.
class ScoreSplit {
  /// Creates a split.
  const ScoreSplit({
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  /// Entries whose score was above zero.
  final int positive;

  /// Entries whose score was exactly zero.
  final int neutral;

  /// Entries whose score was below zero.
  final int negative;

  /// The number of entries considered.
  int get total => positive + neutral + negative;

  /// The share of entries that were positive, zero when there are none.
  double get positiveShare => total == 0 ? 0 : positive / total;

  @override
  String toString() => 'ScoreSplit(+$positive ~$neutral -$negative)';
}
