import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/model/uom.dart';
import 'package:kuhylog/src/ui/widgets/entry_tile.dart';
import 'package:kuhylog/src/ui/widgets/tracker_button.dart';
import 'package:kuhylog/src/ui/widgets/value_dialog.dart';

import 'harness.dart';

Future<List<double?>> openDialog(
  WidgetTester tester,
  Tracker tracker,
) async {
  final captured = <double?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            captured.add(
              await showDialog<double>(
                context: context,
                builder: (_) => ValueDialog(tracker: tracker),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  group('TrackerButton', () {
    testWidgets('shows the glyph, label and today value', (tester) async {
      var taps = 0;
      var presses = 0;
      await pumpScoped(
        tester,
        buildState(),
        Scaffold(
          body: TrackerButton(
            tracker: const Tracker(
              tag: 'sleep',
              label: 'Sleep',
              emoji: '😴',
              uom: Uom.hour,
            ),
            todayValue: 7.5,
            onTap: () => taps++,
            onLongPress: () => presses++,
          ),
        ),
      );
      expect(find.text('😴'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('7.5 h'), findsOneWidget);

      await tester.tap(find.byType(TrackerButton));
      await tester.longPress(find.byType(TrackerButton));
      expect(taps, 1);
      expect(presses, 1);
    });

    testWidgets('hides the value when there is none', (tester) async {
      await pumpScoped(
        tester,
        buildState(),
        Scaffold(
          body: TrackerButton(
            tracker: const Tracker(tag: 'a', label: 'A'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('tracker-button-value')), findsNothing);
    });
  });

  group('EntryTile', () {
    testWidgets('shows the note, the text and a delete button', (tester) async {
      var deleted = 0;
      await pumpScoped(
        tester,
        buildState(),
        Scaffold(
          body: EntryTile(
            entry: LogEntry(
              id: 'x',
              end: DateTime(2026, 8, 8, 9, 5),
              note: 'walked #walk(2)',
            ),
            score: 2,
            onDelete: () => deleted++,
          ),
        ),
      );
      expect(find.text('walked #walk(2)'), findsOneWidget);
      expect(find.text('walked'), findsOneWidget);
      expect(find.text('9:05'), findsOneWidget);
      await tester.tap(find.byKey(const Key('entry-delete-x')));
      expect(deleted, 1);
    });

    testWidgets('omits the subtitle when the note is only tags', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        buildState(),
        Scaffold(
          body: EntryTile(
            entry: LogEntry(id: 'y', end: DateTime(2026, 8, 8), note: '#a'),
            score: 0,
            onDelete: () {},
          ),
        ),
      );
      expect(find.byType(ListTile), findsOneWidget);
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.subtitle, isNull);
    });
  });

  group('ValueDialog', () {
    testWidgets('numeric field returns the typed value', (tester) async {
      final captured = await openDialog(
        tester,
        const Tracker(tag: 'a', label: 'A', type: TrackerType.value),
      );
      await tester.enterText(
        find.byKey(const Key('value-dialog-field')),
        '12.5',
      );
      await tester.tap(find.byKey(const Key('value-dialog-save')));
      await tester.pumpAndSettle();
      expect(captured.single, 12.5);
    });

    testWidgets('submitting the field closes the dialog', (tester) async {
      await openDialog(
        tester,
        const Tracker(
          tag: 'a',
          label: 'A',
          type: TrackerType.value,
          defaultValue: 2.5,
        ),
      );
      expect(find.text('2.5'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('value-dialog-field')), 'x');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancel dismisses without a value', (tester) async {
      final captured = await openDialog(
        tester,
        const Tracker(tag: 'a', label: 'A', type: TrackerType.value),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(captured.single, isNull);
    });

    testWidgets('range shows a slider that can be moved', (tester) async {
      await openDialog(
        tester,
        const Tracker(
          tag: 'mood',
          label: 'Mood',
          type: TrackerType.range,
          defaultValue: 5,
        ),
      );
      expect(find.byKey(const Key('value-dialog-slider')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('value-dialog-slider')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('value-dialog-save')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a range with no step has no divisions', (tester) async {
      await openDialog(
        tester,
        const Tracker(
          tag: 'mood',
          label: 'Mood',
          type: TrackerType.range,
          step: 0,
        ),
      );
      final slider = tester.widget<Slider>(
        find.byKey(const Key('value-dialog-slider')),
      );
      expect(slider.divisions, isNull);
    });

    testWidgets('picker offers each option', (tester) async {
      final captured = await openDialog(
        tester,
        const Tracker(
          tag: 'meal',
          label: 'Meal',
          type: TrackerType.picker,
          options: <String>['breakfast', 'lunch'],
        ),
      );
      expect(find.text('breakfast'), findsOneWidget);
      await tester.tap(find.byKey(const Key('value-dialog-option-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('value-dialog-save')));
      await tester.pumpAndSettle();
      expect(captured.single, 0);
    });

    testWidgets('a timer uses the numeric field', (tester) async {
      await openDialog(
        tester,
        const Tracker(tag: 't', label: 'T', type: TrackerType.timer),
      );
      expect(find.byKey(const Key('value-dialog-field')), findsOneWidget);
    });
  });
}
