import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/streaks.dart';

void main() {
  const tracker = Tracker(tag: 'gym', label: 'Gym');
  final today = DateTime(2026, 8, 8);

  LogEntry on(int day, [String note = '#gym']) =>
      LogEntry(id: '$day$note', end: DateTime(2026, 8, day, 8), note: note);

  group('Streaks', () {
    test('no data yields no streak', () {
      expect(Streaks.of(tracker, const <LogEntry>[], today), Streak.none);
    });

    test('data that never meets the threshold yields no streak', () {
      expect(
        Streaks.of(
          tracker,
          <LogEntry>[on(8, '#gym(0)')],
          today,
        ),
        Streak.none,
      );
    });

    test('counts a run ending today', () {
      final streak = Streaks.of(
        tracker,
        <LogEntry>[on(6), on(7), on(8)],
        today,
      );
      expect(streak.current, 3);
      expect(streak.longest, 3);
    });

    test('an unlogged today does not break yesterday of a streak', () {
      final streak = Streaks.of(tracker, <LogEntry>[on(6), on(7)], today);
      expect(streak.current, 2);
    });

    test('a gap resets the current streak but keeps the longest', () {
      final streak = Streaks.of(
        tracker,
        <LogEntry>[on(1), on(2), on(3), on(8)],
        today,
      );
      expect(streak.current, 1);
      expect(streak.longest, 3);
    });

    test('a streak that ended long ago has no current run', () {
      final streak = Streaks.of(tracker, <LogEntry>[on(1), on(2)], today);
      expect(streak.current, 0);
      expect(streak.longest, 2);
    });

    test('honours a custom threshold', () {
      final streak = Streaks.of(
        tracker,
        <LogEntry>[on(6, '#gym(3)'), on(7, '#gym(3)')],
        today,
        threshold: 3,
      );
      expect(streak.current, 2);
      expect(streak.longest, 2);
    });

    test('a day logged below the threshold breaks the streak', () {
      final streak = Streaks.of(
        tracker,
        <LogEntry>[on(6, '#gym(3)'), on(7, '#gym(3)'), on(8, '#gym(1)')],
        today,
        threshold: 3,
      );
      expect(streak.current, 0);
      expect(streak.longest, 2);
    });

    test('equality, hashCode and toString', () {
      const a = Streak(current: 1, longest: 2);
      const b = Streak(current: 1, longest: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == Streak.none, isFalse);
      expect(a == Object(), isFalse);
      expect(a.toString(), 'Streak(current: 1, longest: 2)');
    });
  });
}
