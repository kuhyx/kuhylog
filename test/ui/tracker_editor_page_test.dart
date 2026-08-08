import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/model/uom.dart';
import 'package:kuhylog/src/ui/tracker_editor_page.dart';

import 'harness.dart';

void main() {
  group('TrackerEditorPage', () {
    testWidgets('creates a tracker from a label', (tester) async {
      final state = buildState();
      await pumpScoped(
        tester,
        state,
        TrackerEditorPage(state: state),
      );
      expect(find.text('New tracker'), findsOneWidget);
      expect(find.byKey(const Key('editor-delete')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('editor-label')),
        'Deep Work',
      );
      await tester.enterText(find.byKey(const Key('editor-emoji')), '🎯');
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      final tracker = state.trackers.single;
      expect(tracker.tag, 'deep_work');
      expect(tracker.label, 'Deep Work');
      expect(tracker.emoji, '🎯');
    });

    testWidgets('will not save without a label', (tester) async {
      final state = buildState();
      await pumpScoped(tester, state, TrackerEditorPage(state: state));
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      expect(state.trackers, isEmpty);
    });

    testWidgets('changes the type, unit and positivity', (tester) async {
      final state = buildState();
      await pumpScoped(tester, state, TrackerEditorPage(state: state));
      await tester.enterText(find.byKey(const Key('editor-label')), 'Sleep');

      await tester.tap(find.byKey(const Key('editor-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('range').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-uom')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hours').last);
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('editor-positivity')),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      final tracker = state.trackers.single;
      expect(tracker.type, TrackerType.range);
      expect(tracker.uom, Uom.hour);
      expect(tracker.positivity, 5);
    });

    testWidgets('edits an existing tracker without changing its tag', (
      tester,
    ) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'));
      await pumpScoped(
        tester,
        state,
        TrackerEditorPage(state: state, tracker: state.trackers.single),
      );
      expect(find.text('Edit gym'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('editor-label')),
        'Weights',
      );
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      expect(state.trackers.single.tag, 'gym');
      expect(state.trackers.single.label, 'Weights');
    });

    testWidgets('deletes an existing tracker', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym'));
      await pumpScoped(
        tester,
        state,
        TrackerEditorPage(state: state, tracker: state.trackers.single),
      );
      await tester.tap(find.byKey(const Key('editor-delete')));
      await tester.pumpAndSettle();
      expect(state.trackers, isEmpty);
    });
  });
}
