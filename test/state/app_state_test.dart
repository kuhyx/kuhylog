import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/exporter.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/store/memory_store.dart';

void main() {
  final now = DateTime(2026, 8, 8, 12);
  late MemoryStore store;
  late AppState state;
  late int notifications;

  setUp(() {
    store = MemoryStore();
    state = AppState(store, now: () => now, random: Random(1));
    notifications = 0;
    state.addListener(() => notifications++);
  });

  group('AppState defaults', () {
    test('exposes the injected clock', () {
      expect(state.now, now);
      expect(AppState(MemoryStore()).now, isA<DateTime>());
    });

    test('seedDefaults installs the starter set once', () {
      state.seedDefaults();
      expect(state.trackers, hasLength(AppState.defaultTrackers.length));
      state.seedDefaults();
      expect(state.trackers, hasLength(AppState.defaultTrackers.length));
      expect(notifications, 1);
    });
  });

  group('AppState recording', () {
    test('records a note and returns it', () {
      final entry = state.record('coffee #coffee(2)');
      expect(entry, isNotNull);
      expect(store.allEntries.single.note, 'coffee #coffee(2)');
      expect(entry!.end, now);
      expect(notifications, 1);
    });

    test('ignores a blank note', () {
      expect(state.record('   '), isNull);
      expect(store.allEntries, isEmpty);
      expect(notifications, 0);
    });

    test('records at an explicit moment', () {
      final past = DateTime(2026, 7);
      expect(state.record('#a', at: past)!.end, past);
    });

    test('recordTracker uses the default value', () {
      const tracker = Tracker(tag: 'water', label: 'Water', defaultValue: 250);
      expect(state.recordTracker(tracker)!.note, '#water(250.0)');
    });

    test('recordTracker accepts an explicit value and extra text', () {
      const tracker = Tracker(
        tag: 'beer',
        label: 'Beer',
        alsoInclude: '+pub',
      );
      expect(
        state.recordTracker(tracker, value: 2)!.note,
        '#beer(2.0) +pub',
      );
    });

    test('deletes an entry', () {
      final entry = state.record('#a')!;
      state.deleteEntry(entry.id);
      expect(store.allEntries, isEmpty);
    });
  });

  group('AppState boards and trackers', () {
    test('boards always start with the implicit one', () {
      expect(state.boards.first, Board.all);
      state.saveBoard(const Board(id: 'x', label: 'X'));
      expect(state.boards, hasLength(2));
    });

    test('board trackers fall back to every visible tracker', () {
      state
        ..saveTracker(const Tracker(tag: 'a', label: 'A'))
        ..saveTracker(const Tracker(tag: 'h', label: 'H', hidden: true));
      expect(state.boardTrackers.map((t) => t.tag), <String>['a']);
      expect(state.visibleTrackers.map((t) => t.tag), <String>['a']);
      state.selectBoard('missing');
      expect(state.boardTrackers.map((t) => t.tag), <String>['a']);
    });

    test('a selected board shows only its own trackers', () {
      state
        ..saveTracker(const Tracker(tag: 'a', label: 'A'))
        ..saveTracker(const Tracker(tag: 'b', label: 'B'))
        ..saveBoard(
          const Board(
            id: 'x',
            label: 'X',
            trackerTags: <String>['b', 'gone'],
          ),
        )
        ..selectBoard('x');
      expect(state.selectedBoardId, 'x');
      expect(state.boardTrackers.map((t) => t.tag), <String>['b']);
    });

    test('deleting the selected board reselects the implicit one', () {
      state
        ..saveBoard(const Board(id: 'x', label: 'X'))
        ..selectBoard('x')
        ..deleteBoard('x');
      expect(state.selectedBoardId, Board.all.id);
    });

    test('deleting another board leaves the selection alone', () {
      state
        ..saveBoard(const Board(id: 'x', label: 'X'))
        ..saveBoard(const Board(id: 'y', label: 'Y'))
        ..selectBoard('x')
        ..deleteBoard('y');
      expect(state.selectedBoardId, 'x');
    });

    test('deleting a tracker leaves history untouched', () {
      state
        ..saveTracker(const Tracker(tag: 'a', label: 'A'))
        ..record('#a')
        ..deleteTracker('a');
      expect(state.trackers, isEmpty);
      expect(store.allEntries.single.note, '#a');
    });
  });

  group('AppState views', () {
    test('timeline is newest first and searchable', () {
      state
        ..record('#a apple', at: DateTime(2026, 8))
        ..record('#b banana', at: DateTime(2026, 8, 2));
      expect(state.timeline.first.note, contains('banana'));
      state.search('APPLE');
      expect(state.query, 'APPLE');
      expect(state.timeline.single.note, contains('apple'));
      state.search('');
      expect(state.timeline, hasLength(2));
    });

    test('today covers only the current day', () {
      state
        ..record('#a', at: DateTime(2026, 8, 7, 23, 59))
        ..record('#b', at: DateTime(2026, 8, 8, 0, 1))
        ..record('#c', at: DateTime(2026, 8, 8, 23, 59));
      expect(state.today.map((e) => e.note), <String>['#c', '#b']);
    });

    test('todayScore sums the day', () {
      state
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 5))
        ..saveTracker(
          const Tracker(tag: 'coffee', label: 'Coffee', positivity: -1),
        )
        ..record('#gym #coffee');
      expect(state.todayScore, 4);
    });
  });

  group('AppState import and export', () {
    test('exports and reimports itself', () {
      state
        ..saveTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 5))
        ..saveBoard(const Board(id: 'x', label: 'X'))
        ..record('#gym', at: DateTime(2026, 8));
      final backup = state.exportBackup();

      final other = AppState(MemoryStore(), now: () => now);
      final result = other.importBackup(backup);
      expect(result.warnings, isEmpty);
      expect(other.trackers.single.positivity, 5);
      expect(other.boards, hasLength(2));
      expect(other.store.allEntries.single.note, '#gym');
    });

    test('an import does not overwrite an existing tracker', () {
      state
        ..saveTracker(
          const Tracker(tag: 'gym', label: 'My Gym', positivity: 5),
        )
        ..importBackup(
          Exporter.toBackupJson(
            trackers: const <Tracker>[Tracker(tag: 'gym', label: 'Theirs')],
            boards: const <Board>[],
            entries: const <LogEntry>[],
          ),
        );
      expect(state.trackers.single.label, 'My Gym');
    });

    test('imports CSV', () {
      final result = state.importCsv('date,note\n2026-08-08T09:00:00,#a\n');
      expect(result.entries, hasLength(1));
      expect(state.store.allEntries.single.note, '#a');
    });

    test('renders both CSV exports', () {
      state
        ..saveTracker(const Tracker(tag: 'a', label: 'A'))
        ..record('#a(2)', at: DateTime(2026, 8));
      expect(state.exportJournalCsv(), contains('#a(2)'));
      expect(state.exportTimeCsv(), contains('2026-08-01,2.0'));
    });
  });
}
