import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';

/// What an import produced, and what it could not make sense of.
///
/// Warnings are first-class rather than logged and forgotten: an import
/// that silently drops a year of history is worse than one that refuses.
class ImportResult {
  /// Creates a result.
  const ImportResult({
    this.trackers = const <Tracker>[],
    this.boards = const <Board>[],
    this.entries = const <LogEntry>[],
    this.warnings = const <String>[],
  });

  /// Tracker configuration that was read or inferred.
  final List<Tracker> trackers;

  /// Boards that were read.
  final List<Board> boards;

  /// Entries that were read, oldest first.
  final List<LogEntry> entries;

  /// Human readable notes about anything skipped or guessed.
  final List<String> warnings;

  /// Whether anything at all was recovered.
  bool get isEmpty => trackers.isEmpty && boards.isEmpty && entries.isEmpty;

  /// A one line summary suitable for a snack bar.
  String get summary =>
      '${entries.length} entries, ${trackers.length} trackers, '
      '${boards.length} boards, ${warnings.length} warnings';

  @override
  String toString() => 'ImportResult($summary)';
}
