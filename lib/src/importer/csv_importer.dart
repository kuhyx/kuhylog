import 'package:kuhylog/src/importer/csv_codec.dart';
import 'package:kuhylog/src/importer/import_result.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';

/// Reads the two CSV layouts a tracker export can take.
///
/// * **Journal** - one row per entry, with a date column and a note
///   column. Optional `lat`, `lng` and `location` columns are used when
///   present. This is lossless because the note carries the structure.
/// * **Time** - one row per day, one column per tracker. A note is
///   synthesised from the non-empty numeric cells, so `sleep=7.5`
///   becomes `#sleep(7.5)`.
///
/// The layout is detected from the header, which must exist.
abstract final class CsvImporter {
  /// Column names accepted as the moment of the entry.
  static const List<String> dateColumns = <String>[
    'date',
    'end',
    'created',
    'day',
    'time',
    'timestamp',
  ];

  /// Column names accepted as the note text.
  static const List<String> noteColumns = <String>['note', 'text', 'notes'];

  /// Imports [source], detecting the layout from its header row.
  static ImportResult importText(String source) {
    final rows = CsvCodec.decode(source);
    if (rows.isEmpty) {
      return const ImportResult(warnings: <String>['CSV was empty']);
    }
    final header = <String>[
      for (final cell in rows.first) cell.trim().toLowerCase(),
    ];
    final dateIndex = _indexOfAny(header, dateColumns);
    if (dateIndex < 0) {
      return ImportResult(
        warnings: <String>[
          'No date column found; expected one of ${dateColumns.join(", ")}',
        ],
      );
    }
    final noteIndex = _indexOfAny(header, noteColumns);
    final body = rows.sublist(1);
    return noteIndex < 0
        ? _importTimeShaped(header, body, dateIndex)
        : _importJournal(header, body, dateIndex, noteIndex);
  }

  static ImportResult _importJournal(
    List<String> header,
    List<List<String>> rows,
    int dateIndex,
    int noteIndex,
  ) {
    final latIndex = _indexOfAny(header, <String>['lat', 'latitude']);
    final lngIndex = _indexOfAny(header, <String>['lng', 'longitude']);
    final placeIndex = _indexOfAny(header, <String>['location', 'place']);
    final entries = <LogEntry>[];
    final warnings = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final raw = _cell(row, dateIndex);
      final moment = LogEntry.parseMoment(raw);
      if (moment.millisecondsSinceEpoch == 0) {
        warnings.add('Row ${i + 2}: could not read the date "$raw"');
        continue;
      }
      entries.add(
        LogEntry(
          id: '${moment.millisecondsSinceEpoch}-${i.toRadixString(16)}',
          end: moment,
          note: _cell(row, noteIndex),
          latitude: double.tryParse(_cell(row, latIndex)),
          longitude: double.tryParse(_cell(row, lngIndex)),
          location: _cell(row, placeIndex),
          source: 'csv',
        ),
      );
    }
    entries.sort((a, b) => a.end.compareTo(b.end));
    return ImportResult(
      entries: entries,
      trackers: _trackersIn(entries),
      warnings: warnings,
    );
  }

  static ImportResult _importTimeShaped(
    List<String> header,
    List<List<String>> rows,
    int dateIndex,
  ) {
    final entries = <LogEntry>[];
    final warnings = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final raw = _cell(row, dateIndex);
      final moment = LogEntry.parseMoment(raw);
      if (moment.millisecondsSinceEpoch == 0) {
        warnings.add('Row ${i + 2}: could not read the date "$raw"');
        continue;
      }
      final buffer = StringBuffer();
      for (var column = 0; column < header.length; column++) {
        if (column == dateIndex) {
          continue;
        }
        final value = _cell(row, column).trim();
        if (value.isEmpty) {
          continue;
        }
        final number = double.tryParse(value);
        if (number == null) {
          warnings.add(
            'Row ${i + 2}, column "${header[column]}": '
            'skipped non-numeric value "$value"',
          );
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.write(' ');
        }
        buffer.write('#${Tracker.slug(header[column])}($value)');
      }
      if (buffer.isEmpty) {
        continue;
      }
      entries.add(
        LogEntry(
          id: '${moment.millisecondsSinceEpoch}-${i.toRadixString(16)}',
          end: moment,
          note: buffer.toString(),
          source: 'csv',
        ),
      );
    }
    entries.sort((a, b) => a.end.compareTo(b.end));
    return ImportResult(
      entries: entries,
      trackers: _trackersIn(entries),
      warnings: warnings,
    );
  }

  static List<Tracker> _trackersIn(List<LogEntry> entries) {
    final tags = <String>{};
    for (final entry in entries) {
      for (final ref in NoteTokenizer.parseOfType(
        entry.note,
        TrackableType.tracker,
      )) {
        tags.add(ref.id);
      }
    }
    final sorted = tags.toList()..sort();
    return <Tracker>[
      for (final tag in sorted) Tracker(tag: tag, label: tag),
    ];
  }

  static String _cell(List<String> row, int index) =>
      index >= 0 && index < row.length ? row[index] : '';

  static int _indexOfAny(List<String> header, List<String> candidates) {
    for (var i = 0; i < header.length; i++) {
      if (candidates.contains(header[i])) {
        return i;
      }
    }
    return -1;
  }
}
