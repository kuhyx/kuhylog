import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';

void main() {
  LogEntry at(int day, String note) =>
      LogEntry(id: '$day$note', end: DateTime(2026, 8, day, 12), note: note);

  group('Aggregate.byDay', () {
    test('sums by default', () {
      const tracker = Tracker(tag: 'w', label: 'W');
      expect(
        Aggregate.byDay(tracker, <LogEntry>[at(1, '#w(2)'), at(1, '#w(3)')]),
        <DateTime, double>{DateTime(2026, 8): 5},
      );
    });

    test('means when configured to', () {
      const tracker = Tracker(tag: 'm', label: 'M', math: TrackerMath.mean);
      expect(
        Aggregate.byDay(tracker, <LogEntry>[at(1, '#m(2)'), at(1, '#m(4)')]),
        <DateTime, double>{DateTime(2026, 8): 3},
      );
    });

    test('a bare mention contributes the default value', () {
      const tracker = Tracker(tag: 'w', label: 'W', defaultValue: 250);
      expect(
        Aggregate.byDay(tracker, <LogEntry>[at(1, '#w')]),
        <DateTime, double>{DateTime(2026, 8): 250},
      );
    });

    test('ignoreZero drops zeroes from sums and means', () {
      const summed = Tracker(tag: 'z', label: 'Z', ignoreZero: true);
      const meaned = Tracker(
        tag: 'z',
        label: 'Z',
        ignoreZero: true,
        math: TrackerMath.mean,
      );
      final entries = <LogEntry>[at(1, '#z(0)'), at(1, '#z(4)')];
      expect(Aggregate.byDay(summed, entries).values.single, 4);
      expect(Aggregate.byDay(meaned, entries).values.single, 4);
    });

    test('zeroes count when ignoreZero is off', () {
      const tracker = Tracker(tag: 'z', label: 'Z', math: TrackerMath.mean);
      final entries = <LogEntry>[at(1, '#z(0)'), at(1, '#z(4)')];
      expect(Aggregate.byDay(tracker, entries).values.single, 2);
    });

    test('entries without the tracker are skipped', () {
      const tracker = Tracker(tag: 'w', label: 'W');
      expect(Aggregate.byDay(tracker, <LogEntry>[at(1, '#other')]), isEmpty);
    });
  });

  group('Aggregate.fillGaps', () {
    test('produces a dense series with zero for missing days', () {
      final values = <DateTime, double>{DateTime(2026, 8, 2): 5};
      expect(
        Aggregate.fillGaps(values, DateTime(2026, 8), DateTime(2026, 8, 3)),
        <double>[0, 5, 0],
      );
    });

    test('accepts a custom filler', () {
      expect(
        Aggregate.fillGaps(
          <DateTime, double>{},
          DateTime(2026, 8),
          DateTime(2026, 8),
          missing: -1,
        ),
        <double>[-1],
      );
    });
  });

  group('Aggregate totals', () {
    test('total and mean', () {
      final values = <DateTime, double>{
        DateTime(2026, 8): 2,
        DateTime(2026, 8, 2): 4,
      };
      expect(Aggregate.total(values), 6);
      expect(Aggregate.mean(values), 3);
    });

    test('mean of nothing is zero rather than a division by zero', () {
      expect(Aggregate.mean(<DateTime, double>{}), 0);
    });
  });
}
