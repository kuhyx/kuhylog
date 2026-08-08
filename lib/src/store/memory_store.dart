import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/store/kuhylog_store.dart';
import 'package:kuhylog/src/store/log_book.dart';

/// An in-memory store, and the base for every persistent one.
///
/// Subclasses persist by overriding [flush], which is called after every
/// mutation.
class MemoryStore extends KuhylogStore {
  /// Creates a store, optionally seeded with existing data.
  MemoryStore({
    List<Tracker> trackers = const <Tracker>[],
    List<Board> boards = const <Board>[],
    List<LogEntry> entries = const <LogEntry>[],
  }) {
    _trackers.addAll(trackers);
    _boards.addAll(boards);
    entries.forEach(_fileEntry);
  }

  final List<Tracker> _trackers = <Tracker>[];
  final List<Board> _boards = <Board>[];
  final Map<String, List<LogEntry>> _books = <String, List<LogEntry>>{};

  @override
  List<Tracker> get trackers => List<Tracker>.unmodifiable(_trackers);

  @override
  List<Board> get boards => List<Board>.unmodifiable(_boards);

  @override
  List<String> get bookKeys {
    final keys = _books.keys.toList()..sort();
    return List<String>.unmodifiable(keys);
  }

  @override
  List<LogEntry> entriesIn(String key) {
    return List<LogEntry>.unmodifiable(_books[key] ?? const <LogEntry>[]);
  }

  @override
  void putEntry(LogEntry entry) {
    _removeEntry(entry.id);
    _fileEntry(entry);
    flush();
  }

  @override
  void removeEntry(String id) {
    _removeEntry(id);
    flush();
  }

  @override
  void putTracker(Tracker tracker) {
    final index = _indexOfTracker(tracker.tag);
    if (index < 0) {
      _trackers.add(tracker);
    } else {
      _trackers[index] = tracker;
    }
    flush();
  }

  @override
  void removeTracker(String tag) {
    final index = _indexOfTracker(tag);
    if (index >= 0) {
      _trackers.removeAt(index);
    }
    flush();
  }

  @override
  void putBoard(Board board) {
    final index = _indexOfBoard(board.id);
    if (index < 0) {
      _boards.add(board);
    } else {
      _boards[index] = board;
    }
    flush();
  }

  @override
  void removeBoard(String id) {
    final index = _indexOfBoard(id);
    if (index >= 0) {
      _boards.removeAt(index);
    }
    flush();
  }

  /// Called after every mutation. The in-memory store does nothing.
  void flush() {}

  /// Replaces the entire contents without calling [flush] per item.
  void replaceAll({
    required List<Tracker> trackers,
    required List<Board> boards,
    required List<LogEntry> entries,
  }) {
    _trackers
      ..clear()
      ..addAll(trackers);
    _boards
      ..clear()
      ..addAll(boards);
    _books.clear();
    entries.forEach(_fileEntry);
    flush();
  }

  void _fileEntry(LogEntry entry) {
    final key = LogBook.keyFor(entry.end);
    _books.putIfAbsent(key, () => <LogEntry>[])
      ..add(entry)
      ..sort((a, b) => a.end.compareTo(b.end));
  }

  void _removeEntry(String id) {
    for (final key in _books.keys.toList()) {
      final book = _books[key]!..removeWhere((entry) => entry.id == id);
      if (book.isEmpty) {
        _books.remove(key);
      }
    }
  }

  int _indexOfTracker(String tag) {
    for (var i = 0; i < _trackers.length; i++) {
      if (_trackers[i].tag == tag) {
        return i;
      }
    }
    return -1;
  }

  int _indexOfBoard(String id) {
    for (var i = 0; i < _boards.length; i++) {
      if (_boards[i].id == id) {
        return i;
      }
    }
    return -1;
  }
}
