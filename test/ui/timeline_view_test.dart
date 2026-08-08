import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/ui/timeline_view.dart';

import 'harness.dart';

void main() {
  group('TimelineView', () {
    testWidgets('shows an empty message', (tester) async {
      await pumpScoped(
        tester,
        buildState(),
        const Scaffold(body: TimelineView()),
      );
      expect(find.text('Nothing recorded yet.'), findsOneWidget);
    });

    testWidgets('groups entries under one header per day', (tester) async {
      final state = buildState()
        ..record('#a apple', at: DateTime(2026, 8, 7, 9))
        ..record('#b banana', at: DateTime(2026, 8, 8, 9))
        ..record('#c cherry', at: DateTime(2026, 8, 8, 10));
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: TimelineView()),
      );
      expect(find.text('2026-08-08'), findsOneWidget);
      expect(find.text('2026-08-07'), findsOneWidget);
    });

    testWidgets('search filters the list', (tester) async {
      final state = buildState()
        ..record('#a apple', at: DateTime(2026, 8, 7, 9))
        ..record('#b banana', at: DateTime(2026, 8, 8, 9));
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: TimelineView()),
      );
      await tester.enterText(
        find.byKey(const Key('timeline-search')),
        'apple',
      );
      await tester.pumpAndSettle();
      expect(find.text('#a apple'), findsOneWidget);
      expect(find.text('#b banana'), findsNothing);
    });

    testWidgets('deleting removes the entry', (tester) async {
      final state = buildState();
      final entry = state.record('#a', at: DateTime(2026, 8, 8, 9))!;
      await pumpScoped(
        tester,
        state,
        const Scaffold(body: TimelineView()),
      );
      await tester.tap(find.byKey(Key('entry-delete-${entry.id}')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries, isEmpty);
      expect(find.text('Nothing recorded yet.'), findsOneWidget);
    });

    test('formatDay zero pads', () {
      expect(TimelineView.formatDay(DateTime(2026, 1, 2)), '2026-01-02');
    });
  });
}
