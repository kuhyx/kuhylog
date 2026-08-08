import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/store/memory_store.dart';
import 'package:kuhylog/src/ui/stats_view.dart';

import 'harness.dart';

void main() {
  group('StatsView', () {
    testWidgets('says so when there is no data', (tester) async {
      await pumpScoped(
        tester,
        buildState(),
        const Scaffold(body: StatsView()),
      );
      expect(find.text('No data in the last 90 days.'), findsOneWidget);
    });

    testWidgets('summarises totals and streaks', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 5))
        ..record('#gym', at: testNow.subtract(const Duration(days: 1)))
        ..record('#gym', at: testNow);
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: StatsView()),
      );
      expect(find.byKey(const Key('stats-summary')), findsOneWidget);
      expect(find.text('2 entries, 100% positive'), findsOneWidget);
      expect(find.byKey(const Key('stats-total-gym')), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
    });

    testWidgets('explains when there is not enough data to scan', (
      tester,
    ) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'))
        ..record('#gym', at: testNow);
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: StatsView()),
      );
      expect(find.byKey(const Key('stats-no-insights')), findsOneWidget);
    });

    testWidgets('lists insights once there is enough data', (tester) async {
      final store = MemoryStore();
      for (var i = 0; i < 40; i++) {
        final day = testNow.subtract(Duration(days: 39 - i));
        store.putEntry(
          LogEntry(
            id: 'e$i',
            end: day,
            note: '#sleep($i) #mood(${i * 2})',
          ),
        );
      }
      final state = AppState(store, now: () => testNow)
        ..saveTracker(const Tracker(tag: 'sleep', label: 'Sleep'))
        ..saveTracker(const Tracker(tag: 'mood', label: 'Mood'));
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: StatsView()),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('insight-sleep-mood-0')),
        200,
      );
      expect(find.byKey(const Key('insight-sleep-mood-0')), findsOneWidget);
      expect(find.textContaining('survives correction'), findsWidgets);
    });

    testWidgets('shows a downward icon for an inverse relationship', (
      tester,
    ) async {
      final store = MemoryStore();
      for (var i = 0; i < 90; i++) {
        store.putEntry(
          LogEntry(
            id: 'e$i',
            end: testNow.subtract(Duration(days: 89 - i)),
            note: '#sleep(${i + 1}) #mood(${100 - i})',
          ),
        );
      }
      final state = AppState(store, now: () => testNow)
        ..saveTracker(const Tracker(tag: 'sleep', label: 'Sleep'))
        ..saveTracker(const Tracker(tag: 'mood', label: 'Mood'));
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: StatsView()),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('insight-sleep-mood-0')),
        200,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('insight-sleep-mood-0')),
          matching: find.byIcon(Icons.trending_down),
        ),
        findsOneWidget,
      );
    });
  });
}
