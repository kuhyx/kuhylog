import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/ui/data_page.dart';

import 'harness.dart';

void main() {
  group('DataPage', () {
    testWidgets('imports a JSON backup and reports it', (tester) async {
      final state = buildState();
      await pumpScoped(tester, state, DataPage(state: state));
      await tester.enterText(
        find.byKey(const Key('data-input')),
        '{"logs":[{"_id":"1","end":1000,"note":"#a"}]}',
      );
      await tester.tap(find.byKey(const Key('data-import-json')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries, hasLength(1));
      expect(find.byKey(const Key('data-import-summary')), findsOneWidget);
      expect(find.textContaining('1 entries'), findsOneWidget);
      expect(find.textContaining('- 1 trackers were not'), findsOneWidget);
    });

    testWidgets('imports a CSV export', (tester) async {
      final state = buildState();
      await pumpScoped(tester, state, DataPage(state: state));
      await tester.enterText(
        find.byKey(const Key('data-input')),
        'date,note\n2026-08-08T09:00:00,#a\n',
      );
      await tester.tap(find.byKey(const Key('data-import-csv')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.single.note, '#a');
    });

    testWidgets('renders each export on demand', (tester) async {
      final state = buildState()
        ..saveTracker(const Tracker(tag: 'a', label: 'A'))
        ..record('#a(2)', at: DateTime(2026, 8));
      await pumpScoped(tester, state, DataPage(state: state));
      expect(find.byKey(const Key('data-output')), findsNothing);

      await tester.tap(find.byKey(const Key('data-export-json')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('data-output')), findsOneWidget);

      await tester.tap(find.byKey(const Key('data-export-journal')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const Key('data-output')),
            )
            .data,
        startsWith('date,note,lat,lng,location'),
      );

      await tester.tap(find.byKey(const Key('data-export-time')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const Key('data-output')),
            )
            .data,
        startsWith('date,a'),
      );

      await tester.tap(find.byKey(const Key('data-export-tag')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const Key('data-output')),
            )
            .data,
        startsWith('tag,uses\n#a,1'),
      );
    });
  });
}
