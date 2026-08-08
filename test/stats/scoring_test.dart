import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/scoring.dart';

void main() {
  final scoring = Scoring(const <Tracker>[
    Tracker(tag: 'gym', label: 'Gym', positivity: 5),
    Tracker(tag: 'coffee', label: 'Coffee', positivity: -1),
    Tracker(tag: 'water', label: 'Water'),
  ]);

  LogEntry at(int day, String note) =>
      LogEntry(id: '$day$note', end: DateTime(2026, 8, day, 12), note: note);

  group('Scoring', () {
    test('sums the positivity of each mention', () {
      expect(scoring.scoreOf(at(1, '#gym #coffee')), 4);
      expect(scoring.scoreOf(at(1, '#coffee #coffee')), -2);
    });

    test('ignores people, context and unknown trackers', () {
      expect(scoring.scoreOf(at(1, '@ola +home #unknown #water')), 0);
    });

    test('groups by day', () {
      final scores = scoring.dailyScores(<LogEntry>[
        at(1, '#gym'),
        at(1, '#coffee'),
        at(2, '#gym'),
      ]);
      expect(scores, <DateTime, int>{
        DateTime(2026, 8): 4,
        DateTime(2026, 8, 2): 5,
      });
    });

    test('splits entries into positive, neutral and negative', () {
      final split = scoring.split(<LogEntry>[
        at(1, '#gym'),
        at(1, '#water'),
        at(1, '#coffee'),
        at(1, '#coffee'),
      ]);
      expect(split.positive, 1);
      expect(split.neutral, 1);
      expect(split.negative, 2);
      expect(split.total, 4);
      expect(split.positiveShare, 0.25);
      expect(split.toString(), 'ScoreSplit(+1 ~1 -2)');
    });

    test('an empty split has no share rather than dividing by zero', () {
      final split = scoring.split(const <LogEntry>[]);
      expect(split.total, 0);
      expect(split.positiveShare, 0);
    });
  });
}
