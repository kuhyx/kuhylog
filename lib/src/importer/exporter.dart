import 'dart:convert';

import 'package:kuhylog/src/importer/csv_codec.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';
import 'package:kuhylog/src/stats/aggregate.dart';

/// Writes the three export formats.
///
/// The JSON backup is the lossless one and is what the backup importer
/// reads back. The two CSVs are for spreadsheets and for feeding other
/// tools; the time-shaped one is lossy by construction because it
/// discards note text.
abstract final class Exporter {
  /// The format version written into every backup.
  static const int formatVersion = 1;

  /// Renders a complete, importable backup.
  static String toBackupJson({
    required List<Tracker> trackers,
    required List<Board> boards,
    required List<LogEntry> entries,
    DateTime? createdAt,
  }) {
    final moment = createdAt ?? DateTime.now();
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'kuhylog': <String, dynamic>{
        'version': formatVersion,
        'created': moment.toIso8601String(),
      },
      'trackers': <Map<String, dynamic>>[
        for (final tracker in trackers) tracker.toJson(),
      ],
      'boards': <Map<String, dynamic>>[
        for (final board in boards) board.toJson(),
      ],
      'logs': <Map<String, dynamic>>[
        for (final entry in entries) entry.toJson(),
      ],
    });
  }

  /// Renders one row per entry, preserving the note verbatim.
  static String toJournalCsv(List<LogEntry> entries) {
    final rows = <List<String>>[
      <String>['date', 'note', 'lat', 'lng', 'location'],
    ];
    for (final entry in entries) {
      rows.add(<String>[
        entry.end.toIso8601String(),
        entry.note,
        entry.latitude?.toString() ?? '',
        entry.longitude?.toString() ?? '',
        entry.location,
      ]);
    }
    return CsvCodec.encode(rows);
  }

  /// Renders one row per day and one column per tracker.
  ///
  /// Days on which nothing was tracked are omitted rather than written
  /// as a row of zeroes, so the file stays small over years of history.
  static String toTimeCsv(List<Tracker> trackers, List<LogEntry> entries) {
    final series = <String, Map<DateTime, double>>{
      for (final tracker in trackers)
        tracker.tag: Aggregate.byDay(tracker, entries),
    };
    final days = <DateTime>{};
    for (final values in series.values) {
      days.addAll(values.keys);
    }
    final sorted = days.toList()..sort((a, b) => a.compareTo(b));
    final rows = <List<String>>[
      <String>['date', for (final tracker in trackers) tracker.tag],
    ];
    for (final day in sorted) {
      rows.add(<String>[
        day.toIso8601String().substring(0, 10),
        for (final tracker in trackers)
          series[tracker.tag]![day]?.toString() ?? '',
      ]);
    }
    return CsvCodec.encode(rows);
  }

  /// Renders the distinct tags actually used across [entries].
  ///
  /// Useful for spotting typo tags such as `#coffe` before they become
  /// permanent.
  static String toTagCsv(List<LogEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final ref in NoteTokenizer.parse(entry.note)) {
        counts[ref.tag] = (counts[ref.tag] ?? 0) + 1;
      }
    }
    final tags = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return CsvCodec.encode(<List<String>>[
      <String>['tag', 'uses'],
      for (final tag in tags) <String>[tag, '${counts[tag]}'],
    ]);
  }
}
