import 'dart:convert';
import 'dart:io';

import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/json_read.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/store/memory_store.dart';

/// A store backed by one JSON file per month plus two index files.
///
/// The on-disk layout mirrors the logical model, so the directory can be
/// inspected, diffed and synced by any file-level tool the user already
/// runs:
///
/// ```text
/// <root>/trackers.json
/// <root>/boards.json
/// <root>/books/2026-08.json
/// ```
///
/// All IO is synchronous; see [MemoryStore] for why.
class FileStore extends MemoryStore {
  /// Opens, and if necessary creates, a store rooted at [directory].
  FileStore(this.directory) {
    _load();
    _loaded = true;
  }

  /// Where the store keeps its files.
  final Directory directory;

  bool _loaded = false;

  /// The file holding tracker configuration.
  File get trackersFile => File('${directory.path}/trackers.json');

  /// The file holding board configuration.
  File get boardsFile => File('${directory.path}/boards.json');

  /// The directory holding one file per month of entries.
  Directory get booksDirectory => Directory('${directory.path}/books');

  /// The file holding the entries for the book [key].
  File bookFile(String key) => File('${booksDirectory.path}/$key.json');

  @override
  void flush() {
    if (!_loaded) {
      return;
    }
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    if (!booksDirectory.existsSync()) {
      booksDirectory.createSync(recursive: true);
    }
    trackersFile.writeAsStringSync(
      _encode(<Map<String, dynamic>>[
        for (final tracker in trackers) tracker.toJson(),
      ]),
      flush: true,
    );
    boardsFile.writeAsStringSync(
      _encode(<Map<String, dynamic>>[
        for (final board in boards) board.toJson(),
      ]),
      flush: true,
    );
    final live = bookKeys.toSet();
    for (final key in live) {
      bookFile(key).writeAsStringSync(
        _encode(<Map<String, dynamic>>[
          for (final entry in entriesIn(key)) entry.toJson(),
        ]),
        flush: true,
      );
    }
    for (final file in booksDirectory.listSync().whereType<File>()) {
      final key = file.uri.pathSegments.last.replaceAll('.json', '');
      if (!live.contains(key)) {
        file.deleteSync();
      }
    }
  }

  void _load() {
    if (!directory.existsSync()) {
      return;
    }
    final trackers = <Tracker>[];
    for (final json in _readList(trackersFile)) {
      trackers.add(Tracker.fromJson(json));
    }
    final boards = <Board>[];
    for (final json in _readList(boardsFile)) {
      boards.add(Board.fromJson(json));
    }
    final entries = <LogEntry>[];
    if (booksDirectory.existsSync()) {
      final files = booksDirectory.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        for (final json in _readList(file)) {
          entries.add(LogEntry.fromJson(json));
        }
      }
    }
    replaceAll(trackers: trackers, boards: boards, entries: entries);
  }

  static String _encode(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);

  /// Reads a JSON array of objects, tolerating a missing or broken file.
  ///
  /// A corrupt file is skipped rather than fatal: losing one month of
  /// history is bad, but refusing to start is worse.
  static List<Map<String, dynamic>> _readList(File file) {
    if (!file.existsSync()) {
      return <Map<String, dynamic>>[];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
    return JsonRead.objectList(<String, dynamic>{'v': decoded}, 'v');
  }
}
