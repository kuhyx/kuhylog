import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/store/memory_store.dart';

LogEntry entry(String id, DateTime end, [String note = '#a']) =>
    LogEntry(id: id, end: end, note: note);

void main() {
  group('MemoryStore', () {
    test('starts empty', () {
      final store = MemoryStore();
      expect(store.trackers, isEmpty);
      expect(store.boards, isEmpty);
      expect(store.bookKeys, isEmpty);
      expect(store.allEntries, isEmpty);
      expect(store.entriesIn('2026-08'), isEmpty);
    });

    test('seeds from the constructor', () {
      final store = MemoryStore(
        trackers: const <Tracker>[Tracker(tag: 'a', label: 'A')],
        boards: const <Board>[Board(id: 'b', label: 'B')],
        entries: <LogEntry>[entry('1', DateTime(2026, 8))],
      );
      expect(store.trackers, hasLength(1));
      expect(store.boards, hasLength(1));
      expect(store.allEntries, hasLength(1));
    });

    test('files entries into month books and sorts them', () {
      final store = MemoryStore()
        ..putEntry(entry('2', DateTime(2026, 8, 5)))
        ..putEntry(entry('1', DateTime(2026, 8)))
        ..putEntry(entry('3', DateTime(2026, 9)));
      expect(store.bookKeys, <String>['2026-08', '2026-09']);
      expect(
        store.entriesIn('2026-08').map((e) => e.id),
        <String>['1', '2'],
      );
    });

    test('putEntry replaces an existing identifier', () {
      final store = MemoryStore()
        ..putEntry(entry('1', DateTime(2026, 8)))
        ..putEntry(entry('1', DateTime(2026, 8, 2), '#b'));
      expect(store.allEntries, hasLength(1));
      expect(store.allEntries.single.note, '#b');
    });

    test('removing the last entry of a month drops the book', () {
      final store = MemoryStore()
        ..putEntry(entry('1', DateTime(2026, 8)))
        ..removeEntry('1');
      expect(store.bookKeys, isEmpty);
      store.removeEntry('missing');
      expect(store.bookKeys, isEmpty);
    });

    test('entriesBetween filters within the boundary months', () {
      final store = MemoryStore()
        ..putEntry(entry('1', DateTime(2026, 7, 31)))
        ..putEntry(entry('2', DateTime(2026, 8, 15)))
        ..putEntry(entry('3', DateTime(2026, 9, 2)));
      final found = store.entriesBetween(
        DateTime(2026, 8),
        DateTime(2026, 9),
      );
      expect(found.map((e) => e.id), <String>['2']);
    });

    test('trackers are added, replaced and removed', () {
      final store = MemoryStore()
        ..putTracker(const Tracker(tag: 'a', label: 'A'))
        ..putTracker(const Tracker(tag: 'a', label: 'A2'))
        ..putTracker(const Tracker(tag: 'b', label: 'B'));
      expect(store.trackers, hasLength(2));
      expect(store.trackerFor('a')!.label, 'A2');
      expect(store.trackerFor('missing'), isNull);
      store
        ..removeTracker('a')
        ..removeTracker('missing');
      expect(store.trackers.single.tag, 'b');
    });

    test('boards are added, replaced and removed', () {
      final store = MemoryStore()
        ..putBoard(const Board(id: 'a', label: 'A'))
        ..putBoard(const Board(id: 'a', label: 'A2'))
        ..putBoard(const Board(id: 'b', label: 'B'));
      expect(store.boards, hasLength(2));
      expect(store.boards.first.label, 'A2');
      store
        ..removeBoard('a')
        ..removeBoard('missing');
      expect(store.boards.single.id, 'b');
    });

    test('replaceAll swaps the whole contents', () {
      final store = MemoryStore()
        ..putEntry(entry('1', DateTime(2026, 8)))
        ..replaceAll(
          trackers: const <Tracker>[Tracker(tag: 'z', label: 'Z')],
          boards: const <Board>[Board(id: 'z', label: 'Z')],
          entries: <LogEntry>[entry('9', DateTime(2026))],
        );
      expect(store.trackers.single.tag, 'z');
      expect(store.boards.single.id, 'z');
      expect(store.allEntries.single.id, '9');
      expect(store.bookKeys, <String>['2026-01']);
    });

    test('returned collections are unmodifiable', () {
      final store = MemoryStore(
        trackers: const <Tracker>[Tracker(tag: 'a', label: 'A')],
        boards: const <Board>[Board(id: 'b', label: 'B')],
        entries: <LogEntry>[entry('1', DateTime(2026, 8))],
      );
      expect(
        () => store.trackers.add(const Tracker(tag: 'x', label: 'X')),
        throwsUnsupportedError,
      );
      expect(
        () => store.boards.add(const Board(id: 'x', label: 'X')),
        throwsUnsupportedError,
      );
      expect(() => store.bookKeys.add('x'), throwsUnsupportedError);
      expect(
        () => store.entriesIn('2026-08').add(entry('2', DateTime(2026, 8, 2))),
        throwsUnsupportedError,
      );
    });
  });
}
