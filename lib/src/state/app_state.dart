import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/importer/backup_importer.dart';
import 'package:kuhylog/src/importer/csv_importer.dart';
import 'package:kuhylog/src/importer/exporter.dart';
import 'package:kuhylog/src/importer/import_result.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/model/uom.dart';
import 'package:kuhylog/src/stats/scoring.dart';
import 'package:kuhylog/src/store/kuhylog_store.dart';

/// The single mutable object the interface listens to.
///
/// Everything the user can do goes through here so the store is never
/// touched directly from a widget, and so the clock and the random
/// source can be pinned in tests. There is no injection framework: the
/// state is handed down the tree by an inherited widget.
class AppState extends ChangeNotifier {
  /// Creates the state over a [store].
  ///
  /// [now] defaults to the wall clock and [random] to a seeded
  /// generator; both exist so tests are deterministic.
  AppState(
    this.store, {
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random();

  /// Where data is persisted.
  final KuhylogStore store;

  final DateTime Function() _now;
  final Random _random;

  String _selectedBoardId = Board.all.id;
  String _query = '';

  /// The current moment, according to the injected clock.
  DateTime get now => _now();

  /// Every configured tracker.
  List<Tracker> get trackers => store.trackers;

  /// Trackers that are not hidden, in configuration order.
  List<Tracker> get visibleTrackers => <Tracker>[
    for (final t in store.trackers)
      if (!t.hidden) t,
  ];

  /// Boards, always led by the implicit all-trackers board.
  List<Board> get boards => <Board>[Board.all, ...store.boards];

  /// The board currently selected on the track screen.
  String get selectedBoardId => _selectedBoardId;

  /// The free text filter applied to the timeline.
  String get query => _query;

  /// A scorer over the current tracker configuration.
  Scoring get scoring => Scoring(store.trackers);

  /// Trackers shown for the selected board.
  List<Tracker> get boardTrackers {
    if (_selectedBoardId == Board.all.id) {
      return visibleTrackers;
    }
    for (final board in store.boards) {
      if (board.id == _selectedBoardId) {
        return <Tracker>[
          for (final tag in board.trackerTags)
            if (store.trackerFor(tag) case final Tracker tracker) tracker,
        ];
      }
    }
    return visibleTrackers;
  }

  /// Every entry, newest first, filtered by [query].
  List<LogEntry> get timeline {
    final entries = store.allEntries.reversed.toList();
    if (_query.isEmpty) {
      return entries;
    }
    final needle = _query.toLowerCase();
    return <LogEntry>[
      for (final entry in entries)
        if (entry.note.toLowerCase().contains(needle)) entry,
    ];
  }

  /// Entries recorded on the current day, newest first.
  List<LogEntry> get today {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return store.entriesBetween(start, end).reversed.toList();
  }

  /// The sum of today's entry scores.
  int get todayScore {
    final scorer = scoring;
    var total = 0;
    for (final entry in today) {
      total += scorer.scoreOf(entry);
    }
    return total;
  }

  /// Selects the board shown on the track screen.
  void selectBoard(String id) {
    _selectedBoardId = id;
    notifyListeners();
  }

  /// Sets the timeline filter.
  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// Records a note exactly as written.
  ///
  /// Blank notes are ignored, because an empty entry is never intended.
  LogEntry? record(String note, {DateTime? at}) {
    if (note.trim().isEmpty) {
      return null;
    }
    final moment = at ?? now;
    final entry = LogEntry(
      id: LogEntry.generateId(moment, _random),
      end: moment,
      note: note.trim(),
    );
    store.putEntry(entry);
    notifyListeners();
    return entry;
  }

  /// Records one occurrence of [tracker].
  ///
  /// [value] defaults to the tracker's own default. Any text configured
  /// in [Tracker.alsoInclude] is appended, which is how one tap can log
  /// a drink and its units at once.
  LogEntry? recordTracker(
    Tracker tracker, {
    double? value,
    DateTime? at,
  }) {
    final amount = value ?? tracker.defaultValue;
    final extra = tracker.alsoInclude.isEmpty ? '' : ' ${tracker.alsoInclude}';
    return record('#${tracker.tag}($amount)$extra', at: at);
  }

  /// Deletes an entry.
  void deleteEntry(String id) {
    store.removeEntry(id);
    notifyListeners();
  }

  /// Adds or replaces a tracker.
  void saveTracker(Tracker tracker) {
    store.putTracker(tracker);
    notifyListeners();
  }

  /// Removes a tracker's configuration.
  ///
  /// History is untouched: the tag stays in every note that used it, so
  /// deleting a tracker by accident cannot destroy data.
  void deleteTracker(String tag) {
    store.removeTracker(tag);
    notifyListeners();
  }

  /// Adds or replaces a board.
  void saveBoard(Board board) {
    store.putBoard(board);
    notifyListeners();
  }

  /// Removes a board.
  void deleteBoard(String id) {
    store.removeBoard(id);
    if (_selectedBoardId == id) {
      _selectedBoardId = Board.all.id;
    }
    notifyListeners();
  }

  /// Imports a JSON backup, merging it into the current data.
  ImportResult importBackup(String source) =>
      _merge(BackupImporter.importText(source));

  /// Imports a CSV export, merging it into the current data.
  ImportResult importCsv(String source) =>
      _merge(CsvImporter.importText(source));

  /// Renders a full backup of the current data.
  String exportBackup() => Exporter.toBackupJson(
    trackers: store.trackers,
    boards: store.boards,
    entries: store.allEntries,
    createdAt: now,
  );

  /// Renders the journal-shaped CSV of the current data.
  String exportJournalCsv() => Exporter.toJournalCsv(store.allEntries);

  /// Renders the day-by-tracker CSV of the current data.
  String exportTimeCsv() =>
      Exporter.toTimeCsv(store.trackers, store.allEntries);

  ImportResult _merge(ImportResult result) {
    for (final tracker in result.trackers) {
      if (store.trackerFor(tracker.tag) == null) {
        store.putTracker(tracker);
      }
    }
    result.boards.forEach(store.putBoard);
    result.entries.forEach(store.putEntry);
    notifyListeners();
    return result;
  }

  /// Installs a small starter set of trackers on an empty store.
  ///
  /// Chosen to demonstrate every tracker type rather than to prescribe
  /// a routine; delete them all and nothing breaks.
  void seedDefaults() {
    if (store.trackers.isNotEmpty) {
      return;
    }
    defaultTrackers.forEach(store.putTracker);
    notifyListeners();
  }

  /// The starter trackers installed by [seedDefaults].
  static const List<Tracker> defaultTrackers = <Tracker>[
    Tracker(
      tag: 'mood',
      label: 'Mood',
      emoji: '🙂',
      type: TrackerType.range,
      defaultValue: 5,
      math: TrackerMath.mean,
    ),
    Tracker(
      tag: 'sleep',
      label: 'Sleep',
      emoji: '😴',
      type: TrackerType.value,
      uom: Uom.hour,
      max: 12,
      defaultValue: 8,
      math: TrackerMath.mean,
      positivity: 3,
    ),
    Tracker(
      tag: 'coffee',
      label: 'Coffee',
      emoji: '☕',
      positivity: -1,
    ),
    Tracker(
      tag: 'focus',
      label: 'Focus',
      emoji: '🎯',
      type: TrackerType.timer,
      uom: Uom.second,
      positivity: 4,
    ),
    Tracker(
      tag: 'gym',
      label: 'Gym',
      emoji: '🏋️',
      positivity: 5,
    ),
  ];
}
