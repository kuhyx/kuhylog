import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/insight_scan.dart';

void main() {
  final from = DateTime(2026, 6);
  final to = DateTime(2026, 8, 8);

  const trackers = <Tracker>[
    Tracker(tag: 'sleep', label: 'Sleep'),
    Tracker(tag: 'mood', label: 'Mood'),
  ];

  List<LogEntry> series(
    int days,
    double Function(int) sleep,
    double Function(int) mood,
  ) {
    final entries = <LogEntry>[];
    for (var i = 0; i < days; i++) {
      final day = from.add(Duration(days: i));
      entries.add(
        LogEntry(
          id: 's$i',
          end: day,
          note: '#sleep(${sleep(i)}) #mood(${mood(i)})',
        ),
      );
    }
    return entries;
  }

  group('InsightScan', () {
    test('finds a same day relationship and marks it significant', () {
      final entries = series(40, (i) => i.toDouble(), (i) => i * 2.0);
      final insights = const InsightScan().run(trackers, entries, from, to);
      final match = insights.firstWhere(
        (i) =>
            i.sourceTag == 'sleep' && i.targetTag == 'mood' && i.lagDays == 0,
      );
      expect(match.coefficient, closeTo(1, 1e-6));
      expect(match.significant, isTrue);
      expect(match.isPositive, isTrue);
      expect(match.sampleSize, greaterThan(21));
      expect(match.summary, '#sleep goes with higher #mood the same day');
      expect(match.toString(), 'Insight(sleep -> mood @0)');
    });

    test('describes a negative relationship', () {
      final entries = series(40, (i) => i.toDouble(), (i) => -i.toDouble());
      final insights = const InsightScan().run(trackers, entries, from, to);
      final match = insights.first;
      expect(match.isPositive, isFalse);
      expect(match.summary, contains('lower'));
    });

    test('phrases each lag differently', () {
      final entries = series(40, (i) => i.toDouble(), (i) => i.toDouble());
      final insights = const InsightScan().run(trackers, entries, from, to);
      final phrases = <String>{
        for (final insight in insights) insight.summary.split('#mood ').last,
      };
      expect(phrases, containsAll(<String>['the same day', 'the next day']));
      expect(
        phrases.any((p) => p.contains('2 days later')),
        isTrue,
      );
    });

    test('drops pairs with too few overlapping days', () {
      final entries = series(5, (i) => i.toDouble(), (i) => i.toDouble());
      expect(
        const InsightScan().run(
          trackers,
          entries,
          from,
          from.add(
            const Duration(days: 4),
          ),
        ),
        isEmpty,
      );
    });

    test('skips trackers that were never recorded', () {
      final entries = series(40, (i) => i.toDouble(), (i) => i.toDouble());
      final insights = const InsightScan().run(
        <Tracker>[...trackers, const Tracker(tag: 'ghost', label: 'Ghost')],
        entries,
        from,
        to,
      );
      expect(
        insights.every((i) => i.sourceTag != 'ghost'),
        isTrue,
      );
    });

    test('skips a flat series that has no variance', () {
      final entries = series(40, (i) => 1, (i) => i.toDouble());
      final insights = const InsightScan().run(
        trackers,
        entries,
        from,
        from.add(const Duration(days: 39)),
      );
      expect(
        insights.every((i) => i.sourceTag != 'sleep' || i.targetTag != 'mood'),
        isTrue,
      );
    });

    test('never compares a tracker with itself at lag zero', () {
      final entries = series(40, (i) => i.toDouble(), (i) => i.toDouble());
      final insights = const InsightScan().run(trackers, entries, from, to);
      expect(
        insights.any((i) => i.sourceTag == i.targetTag && i.lagDays == 0),
        isFalse,
      );
    });

    test('noise does not survive the correction', () {
      final random = Random(7);
      final entries = series(
        60,
        (i) => random.nextDouble() * 10,
        (i) => random.nextDouble() * 10,
      );
      final insights = const InsightScan().run(
        trackers,
        entries,
        from,
        from.add(const Duration(days: 59)),
      );
      expect(insights.every((i) => !i.significant), isTrue);
    });

    test('is ordered by strength', () {
      final entries = series(40, (i) => i.toDouble(), (i) => i * 2.0);
      final insights = const InsightScan().run(trackers, entries, from, to);
      for (var i = 1; i < insights.length; i++) {
        expect(
          insights[i - 1].coefficient.abs(),
          greaterThanOrEqualTo(insights[i].coefficient.abs()),
        );
      }
    });
  });
}
