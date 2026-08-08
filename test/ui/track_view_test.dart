import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/ui/track_view.dart';
import 'package:kuhylog/src/ui/tracker_editor_page.dart';

import 'harness.dart';

void main() {
  group('TrackView', () {
    testWidgets('an empty board offers the starter set', (tester) async {
      final state = buildState();
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      expect(find.text('No trackers on this board yet.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('track-seed-button')));
      await tester.pumpAndSettle();
      expect(state.trackers, isNotEmpty);
      expect(find.text('Coffee'), findsOneWidget);
    });

    testWidgets('an empty board can jump to the editor', (tester) async {
      await pumpScoped(tester, buildState(), const Scaffold(body: TrackView()));
      await tester.tap(find.byKey(const Key('track-empty-add-button')));
      await tester.pumpAndSettle();
      expect(find.byType(TrackerEditorPage), findsOneWidget);
    });

    testWidgets('tapping a tally records immediately', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'coffee', label: 'Coffee'));
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      await tester.tap(find.byKey(const Key('tracker-button-coffee')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.single.note, '#coffee(1.0)');
      expect(find.byKey(const Key('tracker-button-value')), findsOneWidget);
    });

    testWidgets('tapping a valued tracker asks first', (tester) async {
      final state = buildState()
        ..saveTracker(
          const Tracker(tag: 'sleep', label: 'Sleep', type: TrackerType.value),
        );
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      await tester.tap(find.byKey(const Key('tracker-button-sleep')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('value-dialog-field')), '7');
      await tester.tap(find.byKey(const Key('value-dialog-save')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.single.note, '#sleep(7.0)');
    });

    testWidgets('dismissing the dialog records nothing', (tester) async {
      final state = buildState()
        ..saveTracker(
          const Tracker(tag: 'sleep', label: 'Sleep', type: TrackerType.value),
        );
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      await tester.tap(find.byKey(const Key('tracker-button-sleep')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.store.allEntries, isEmpty);
    });

    testWidgets('long pressing opens the editor', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'));
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      await tester.longPress(find.byKey(const Key('tracker-button-gym')));
      await tester.pumpAndSettle();
      expect(find.text('Edit gym'), findsOneWidget);
    });

    testWidgets('the add button opens an empty editor', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'));
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      await tester.tap(find.byKey(const Key('tracker-add-button')));
      await tester.pumpAndSettle();
      expect(find.text('New tracker'), findsOneWidget);
    });

    testWidgets('board chips switch the visible trackers', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'))
        ..saveTracker(const Tracker(tag: 'coffee', label: 'Coffee'))
        ..saveBoard(
          const Board(
            id: 'health',
            label: 'Health',
            trackerTags: <String>['gym'],
          ),
        );
      await pumpScoped(tester, state, const Scaffold(body: TrackView()));
      expect(find.byKey(const Key('tracker-button-coffee')), findsOneWidget);
      await tester.tap(find.byKey(const Key('board-chip-health')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tracker-button-coffee')), findsNothing);
      expect(find.byKey(const Key('tracker-button-gym')), findsOneWidget);
    });
  });
}
