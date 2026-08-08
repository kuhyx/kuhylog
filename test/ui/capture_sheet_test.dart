import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/ui/capture_sheet.dart';

import 'harness.dart';

void main() {
  group('CaptureSheet', () {
    testWidgets('shows a chip for every kind of mention', (tester) async {
      final state = buildState();
      await pumpScoped(
        tester,
        state,
        Scaffold(body: CaptureSheet(state: state)),
      );
      await tester.enterText(
        find.byKey(const Key('capture-field')),
        'ran #run(5) with @ola +park ^goal /warsaw',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('capture-chip-tracker-run')), findsOneWidget);
      expect(find.byKey(const Key('capture-chip-person-ola')), findsOneWidget);
      expect(
        find.byKey(const Key('capture-chip-context-park')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('capture-chip-pointer-goal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('capture-chip-place-warsaw')),
        findsOneWidget,
      );
      expect(find.text('#run 5.0'), findsOneWidget);
      expect(find.text('@ola'), findsOneWidget);
    });

    testWidgets('saving is disabled until something is typed', (tester) async {
      final state = buildState();
      await pumpScoped(
        tester,
        state,
        Scaffold(body: CaptureSheet(state: state)),
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('capture-save')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('saving records the note and closes', (tester) async {
      final state = buildState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => CaptureSheet(state: state),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('capture-field')),
        'coffee #coffee',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture-save')));
      await tester.pumpAndSettle();
      expect(state.store.allEntries.single.note, 'coffee #coffee');
      expect(find.byType(CaptureSheet), findsNothing);
    });
  });
}
