import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/store/file_store.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('kuhylog_store_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  group('FileStore', () {
    test('persists and reloads everything', () {
      FileStore(root)
        ..putTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 4))
        ..putBoard(
          const Board(
            id: 'health',
            label: 'Health',
            trackerTags: <String>['gym'],
          ),
        )
        ..putEntry(
          LogEntry(id: '1', end: DateTime(2026, 8, 8, 9), note: '#gym'),
        );

      final reopened = FileStore(root);
      expect(reopened.trackers.single.positivity, 4);
      expect(reopened.boards.single.trackerTags, <String>['gym']);
      expect(reopened.allEntries.single.note, '#gym');
      expect(reopened.bookKeys, <String>['2026-08']);
    });

    test('creates its directories on first write', () {
      final nested = Directory('${root.path}/a/b');
      FileStore(nested).putTracker(const Tracker(tag: 'a', label: 'A'));
      expect(nested.existsSync(), isTrue);
      expect(FileStore(nested).booksDirectory.existsSync(), isTrue);
    });

    test('opening a directory that does not exist yields an empty store', () {
      final missing = Directory('${root.path}/nope');
      final store = FileStore(missing);
      expect(store.trackers, isEmpty);
      expect(store.allEntries, isEmpty);
    });

    test('deletes the file of a month that became empty', () {
      final store = FileStore(root)
        ..putEntry(LogEntry(id: '1', end: DateTime(2026, 8, 8), note: '#a'));
      expect(store.bookFile('2026-08').existsSync(), isTrue);
      store.removeEntry('1');
      expect(store.bookFile('2026-08').existsSync(), isFalse);
    });

    test('reads across several month files', () {
      FileStore(root)
        ..putEntry(LogEntry(id: '1', end: DateTime(2026, 7), note: '#a'))
        ..putEntry(LogEntry(id: '2', end: DateTime(2026, 8), note: '#b'));
      expect(FileStore(root).allEntries, hasLength(2));
    });

    test('a corrupt file is skipped rather than fatal', () {
      FileStore(root)
        ..putTracker(const Tracker(tag: 'a', label: 'A'))
        ..putEntry(LogEntry(id: '1', end: DateTime(2026, 8, 8), note: '#a'));
      File('${root.path}/trackers.json').writeAsStringSync('{not json');
      final store = FileStore(root);
      expect(store.trackers, isEmpty);
      expect(store.allEntries, hasLength(1));
    });

    test('a JSON file that is not a list of objects is skipped', () {
      FileStore(root).putTracker(const Tracker(tag: 'a', label: 'A'));
      File('${root.path}/trackers.json').writeAsStringSync('{"a": 1}');
      expect(FileStore(root).trackers, isEmpty);
    });

    test('exposes the paths it uses', () {
      final store = FileStore(root);
      expect(store.trackersFile.path, '${root.path}/trackers.json');
      expect(store.boardsFile.path, '${root.path}/boards.json');
      expect(store.booksDirectory.path, '${root.path}/books');
      expect(store.bookFile('2026-08').path, '${root.path}/books/2026-08.json');
    });
  });
}
