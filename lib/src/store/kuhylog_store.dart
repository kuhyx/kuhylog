import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/store/log_book.dart';

/// Everything the application can persist.
///
/// The whole interface is synchronous on purpose. Real asynchronous file
/// IO never completes inside the fake-async zone `testWidgets` runs in,
/// which makes an async store untestable at the widget level; and a
/// personal tracker's data set is small enough that blocking reads are
/// imperceptible. Do not "modernise" this to `Future` without also
/// solving the test problem.
abstract class KuhylogStore {
  /// Every tracker, in insertion order.
  List<Tracker> get trackers;

  /// Every board, in display order.
  List<Board> get boards;

  /// Every book key that holds at least one entry, oldest first.
  List<String> get bookKeys;

  /// Entries in the book [key], oldest first.
  List<LogEntry> entriesIn(String key);

  /// Adds or replaces an entry, filing it into the right book.
  void putEntry(LogEntry entry);

  /// Removes the entry with [id]; does nothing when it is absent.
  void removeEntry(String id);

  /// Adds or replaces a tracker, matched on [Tracker.tag].
  void putTracker(Tracker tracker);

  /// Removes the tracker with [tag]; does nothing when it is absent.
  void removeTracker(String tag);

  /// Adds or replaces a board, matched on [Board.id].
  void putBoard(Board board);

  /// Removes the board with [id]; does nothing when it is absent.
  void removeBoard(String id);

  /// Every entry across every book, oldest first.
  List<LogEntry> get allEntries {
    final entries = <LogEntry>[];
    for (final key in bookKeys) {
      entries.addAll(entriesIn(key));
    }
    return entries;
  }

  /// Entries between [from] and [to] inclusive, oldest first.
  List<LogEntry> entriesBetween(DateTime from, DateTime to) {
    final entries = <LogEntry>[];
    for (final key in LogBook.keysBetween(from, to)) {
      for (final entry in entriesIn(key)) {
        if (!entry.end.isBefore(from) && !entry.end.isAfter(to)) {
          entries.add(entry);
        }
      }
    }
    return entries;
  }

  /// The tracker with [tag], or `null` when it is not configured.
  Tracker? trackerFor(String tag) {
    for (final tracker in trackers) {
      if (tracker.tag == tag) {
        return tracker;
      }
    }
    return null;
  }
}
