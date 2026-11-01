import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/ui/app.dart';

import 'harness.dart';

/// Pixel 6a geometry: 1080x2400 px at 2.625, real status bar and nav inset.
void usePixel6a(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.625
    ..padding = const FakeViewPadding(top: 132, bottom: 63);
  addTearDown(tester.view.reset);
}

/// A busy install: 20 trackers and 12 days of entries, 25 of them today.
AppState busyState() {
  final state = buildState();
  for (var i = 0; i < 20; i++) {
    state.saveTracker(Tracker(tag: 't$i', label: 'Tracker $i'));
  }
  for (var d = 0; d < 12; d++) {
    final day = testNow.subtract(Duration(days: d));
    final count = d == 0 ? 25 : 4;
    for (var n = 0; n < count; n++) {
      state.record(
        '#t${(d + n) % 20}(${n + 1}) a longer note to wrap',
        at: DateTime(day.year, day.month, day.day, 6, n),
      );
    }
  }
  return state;
}

/// Fails with the offenders when a vertical scrollable can still scroll.
void expectNoVerticalScroll(WidgetTester tester) {
  final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
  final offenders = <String>[];
  for (final element in find.byType(Scrollable).evaluate()) {
    final scrollable = element.widget as Scrollable;
    if (scrollable.axis != Axis.vertical) {
      continue;
    }
    final position = Scrollable.of(element).position;
    if (position.maxScrollExtent > 0) {
      offenders.add('max=${position.maxScrollExtent}');
    }
  }
  expect(scrollables, isNotEmpty);
  expect(offenders, isEmpty);
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('fit to one phone screen', () {
    testWidgets('Track fits without scrolling', (tester) async {
      usePixel6a(tester);
      await tester.pumpWidget(KuhylogApp(state: busyState()));
      await tester.pumpAndSettle();
      expectNoVerticalScroll(tester);
      expect(find.byKey(const Key('tracker-button-t0')), findsOneWidget);
      expect(
        find.byKey(const Key('tracker-button-t0')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tracker-add-button')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home-capture-button')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('Track pages the overflow sideways', (tester) async {
      usePixel6a(tester);
      await tester.pumpWidget(KuhylogApp(state: busyState()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tracker-button-t19')), findsNothing);
      await tester.fling(
        find.byKey(const Key('tracker-button-t0')),
        const Offset(-400, 0),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tracker-button-t19')), findsOneWidget);
    });

    testWidgets('Timeline fits without scrolling', (tester) async {
      usePixel6a(tester);
      final state = busyState();
      await tester.pumpWidget(KuhylogApp(state: state));
      await tester.pumpAndSettle();
      await openTab(tester, 'Timeline');
      expectNoVerticalScroll(tester);
      final today = state.timeline.first;
      expect(
        find.byKey(Key('entry-cell-${today.id}')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('timeline-search')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('timeline-day-0')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('Timeline tile opens a sheet with the delete action', (
      tester,
    ) async {
      usePixel6a(tester);
      final state = busyState();
      await tester.pumpWidget(KuhylogApp(state: state));
      await tester.pumpAndSettle();
      await openTab(tester, 'Timeline');
      final entry = state.timeline.first;
      final before = state.store.allEntries.length;
      await tester.tap(find.byKey(Key('entry-cell-${entry.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('entry-delete-${entry.id}')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.length, before - 1);
    });

    testWidgets('Stats fits without scrolling', (tester) async {
      usePixel6a(tester);
      await tester.pumpWidget(KuhylogApp(state: busyState()));
      await tester.pumpAndSettle();
      await openTab(tester, 'Stats');
      expectNoVerticalScroll(tester);
      expect(
        find.byKey(const Key('stats-range-30')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('stats-insights-tile')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('stats-total-t0')).hitTestable(),
        findsOneWidget,
      );
    });
  });
}
