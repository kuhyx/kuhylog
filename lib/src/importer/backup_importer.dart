import 'dart:convert';

import 'package:kuhylog/src/importer/import_result.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/json_read.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';

/// Reads a JSON backup, whether it came from this app or from Nomie.
///
/// Three shapes are recognised, because a backup is worthless if it only
/// loads on the version that wrote it:
///
/// * this app's own export, `{trackers, boards, logs}`;
/// * a Nomie 5 or 6 key-value dump, whose keys look like
///   `/v5/data/books/2019-24`, `/v5/data/trackers.json` and
///   `/v5/data/boards.json`;
/// * the older flat shape with `events` or `notes`, `trackers`, and a
///   `meta` entry keyed `hyperStorage-groups` holding the boards.
///
/// Field names inside records are handled by [LogEntry.fromJson] and
/// [Tracker.fromJson], which accept both this app's names and Nomie's.
///
/// The shapes above are reconstructed from published documentation, not
/// from a byte-for-byte specification, so run [importText] against a
/// real export and read the warnings before trusting a large import.
abstract final class BackupImporter {
  /// Parses [source] as JSON and imports it.
  ///
  /// Malformed JSON yields an empty result with one warning rather than
  /// an exception, so the caller can show it in the interface.
  static ImportResult importText(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return ImportResult(
        warnings: <String>['Not valid JSON: ${error.message}'],
      );
    }
    if (decoded is List) {
      return importJson(<String, dynamic>{'logs': decoded});
    }
    if (decoded is Map) {
      return importJson(decoded.cast<String, dynamic>());
    }
    return const ImportResult(
      warnings: <String>['Backup must be a JSON object or array'],
    );
  }

  /// Imports an already decoded backup object.
  static ImportResult importJson(Map<String, dynamic> json) {
    final warnings = <String>[];
    final entries = <LogEntry>[];
    final trackers = <String, Tracker>{};
    final boards = <String, Board>{};

    for (final key in json.keys) {
      final value = json[key];
      if (_isBookKey(key)) {
        _readEntries(value, entries, warnings, key);
      } else if (_isTrackerKey(key)) {
        _readTrackers(value, trackers, warnings, key);
      } else if (_isBoardKey(key)) {
        _readBoards(value, boards, warnings, key);
      } else if (key == 'meta') {
        _readMeta(value, boards);
      }
    }

    entries.sort((a, b) => a.end.compareTo(b.end));
    final inferred = _inferTrackers(entries, trackers.keys.toSet());
    for (final tracker in inferred) {
      trackers[tracker.tag] = tracker;
    }
    if (inferred.isNotEmpty) {
      warnings.add(
        '${inferred.length} trackers were not configured in the backup '
        'and have been created with default settings',
      );
    }
    return ImportResult(
      trackers: trackers.values.toList(),
      boards: boards.values.toList(),
      entries: entries,
      warnings: warnings,
    );
  }

  static bool _isBookKey(String key) =>
      key.contains('/books/') ||
      key == 'logs' ||
      key == 'events' ||
      key == 'notes';

  static bool _isTrackerKey(String key) =>
      key == 'trackers' || key.endsWith('/trackers.json');

  static bool _isBoardKey(String key) =>
      key == 'boards' || key.endsWith('/boards.json');

  static void _readEntries(
    Object? value,
    List<LogEntry> into,
    List<String> warnings,
    String key,
  ) {
    final records = _records(value);
    if (records == null) {
      warnings.add('Skipped "$key": expected a list or map of entries');
      return;
    }
    for (final record in records) {
      into.add(LogEntry.fromJson(record));
    }
  }

  static void _readTrackers(
    Object? value,
    Map<String, Tracker> into,
    List<String> warnings,
    String key,
  ) {
    final records = _records(value);
    if (records == null) {
      warnings.add('Skipped "$key": expected a list or map of trackers');
      return;
    }
    for (final record in records) {
      final tracker = Tracker.fromJson(record);
      if (tracker.tag.isEmpty) {
        warnings.add('Skipped a tracker with no tag');
        continue;
      }
      into[tracker.tag] = tracker;
    }
  }

  static void _readBoards(
    Object? value,
    Map<String, Board> into,
    List<String> warnings,
    String key,
  ) {
    final records = _records(value);
    if (records == null) {
      warnings.add('Skipped "$key": expected a list or map of boards');
      return;
    }
    for (final record in records) {
      final board = Board.fromJson(record);
      if (board.id.isEmpty) {
        warnings.add('Skipped a board with no id');
        continue;
      }
      into[board.id] = board;
    }
  }

  /// Reads boards out of the legacy `hyperStorage-groups` meta record.
  static void _readMeta(Object? value, Map<String, Board> into) {
    if (value is! List) {
      return;
    }
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final record = item.cast<String, dynamic>();
      if (JsonRead.string(record, '_id') != 'hyperStorage-groups') {
        continue;
      }
      final groups = JsonRead.object(record, 'groups');
      for (final name in groups.keys) {
        final id = Tracker.slug(name);
        into[id] = Board(
          id: id,
          label: name,
          trackerTags: JsonRead.stringList(
            groups,
            name,
          ).map(Tracker.slug).toList(),
        );
      }
    }
  }

  /// Normalises a list of records or a map of them into a list.
  ///
  /// Nomie stores trackers as a map keyed by tag and logs as a list, and
  /// different exporters disagree, so both are accepted everywhere.
  static List<Map<String, dynamic>>? _records(Object? value) {
    if (value is List) {
      return JsonRead.objectList(<String, dynamic>{'v': value}, 'v');
    }
    if (value is Map) {
      final result = <Map<String, dynamic>>[];
      final map = value.cast<String, dynamic>();
      for (final key in map.keys) {
        final item = map[key];
        if (item is Map) {
          result.add(
            item.cast<String, dynamic>()..putIfAbsent('tag', () => key),
          );
        }
      }
      return result;
    }
    return null;
  }

  /// Creates default trackers for tags that appear only in notes.
  static List<Tracker> _inferTrackers(
    List<LogEntry> entries,
    Set<String> known,
  ) {
    final seen = <String>{};
    for (final entry in entries) {
      for (final ref in NoteTokenizer.parseOfType(
        entry.note,
        TrackableType.tracker,
      )) {
        if (!known.contains(ref.id)) {
          seen.add(ref.id);
        }
      }
    }
    final sorted = seen.toList()..sort();
    return <Tracker>[
      for (final tag in sorted) Tracker(tag: tag, label: tag),
    ];
  }
}
