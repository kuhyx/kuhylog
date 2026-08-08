import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/ui/app.dart';
import 'package:kuhylog/src/ui/capture_sheet.dart';
import 'package:kuhylog/src/ui/data_page.dart';
import 'package:kuhylog/src/ui/stats_view.dart';
import 'package:kuhylog/src/ui/timeline_view.dart';
import 'package:kuhylog/src/ui/track_view.dart';

import 'harness.dart';

void main() {
  group('KuhylogApp', () {
    testWidgets('opens on the track tab', (tester) async {
      await tester.pumpWidget(KuhylogApp(state: buildState()));
      await tester.pumpAndSettle();
      expect(find.text('Track'), findsWidgets);
      expect(find.byType(TrackView), findsOneWidget);
    });

    testWidgets('switches between the three views', (tester) async {
      await tester.pumpWidget(KuhylogApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.byType(TimelineView), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Timeline'), findsOneWidget);

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.byType(StatsView), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Stats'), findsOneWidget);
    });

    testWidgets('shows the day score and updates it', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 5));
      await tester.pumpWidget(KuhylogApp(state: state));
      await tester.pumpAndSettle();
      expect(find.text('today +0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tracker-button-gym')));
      await tester.pumpAndSettle();
      expect(find.text('today +5'), findsOneWidget);
    });

    testWidgets('shows a negative day score without a plus', (tester) async {
      final state = buildState()
        ..saveTracker(
          const Tracker(tag: 'beer', label: 'Beer', positivity: -2),
        )
        ..record('#beer');
      await tester.pumpWidget(KuhylogApp(state: state));
      await tester.pumpAndSettle();
      expect(find.text('today -2'), findsOneWidget);
    });

    testWidgets('the button opens the capture sheet', (tester) async {
      final state = buildState();
      await tester.pumpWidget(KuhylogApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-capture-button')));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureSheet), findsOneWidget);

      await tester.enterText(find.byKey(const Key('capture-field')), '#x');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture-save')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.single.note, '#x');
    });

    testWidgets('the toolbar opens the data page', (tester) async {
      await tester.pumpWidget(KuhylogApp(state: buildState()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-data-button')));
      await tester.pumpAndSettle();
      expect(find.byType(DataPage), findsOneWidget);
    });
  });
}
