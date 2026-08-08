import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/backup_importer.dart';
import 'package:kuhylog/src/importer/csv_importer.dart';
import 'package:kuhylog/src/importer/exporter.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';

void main() {
  const trackers = <Tracker>[
    Tracker(tag: 'coffee', label: 'Coffee', positivity: -1),
    Tracker(tag: 'gym', label: 'Gym', positivity: 5),
  ];
  const boards = <Board>[
    Board(id: 'daily', label: 'Daily', trackerTags: <String>['coffee']),
  ];
  final entries = <LogEntry>[
    LogEntry(
      id: '1',
      end: DateTime(2026, 8, 8, 9),
      note: 'morning #coffee(2) @ola',
      latitude: 52.2,
      longitude: 21,
      location: 'Wola',
    ),
    LogEntry(id: '2', end: DateTime(2026, 8, 9, 18), note: '#gym'),
  ];

  group('Exporter.toBackupJson', () {
    test('is importable without loss', () {
      final json = Exporter.toBackupJson(
        trackers: trackers,
        boards: boards,
        entries: entries,
        createdAt: DateTime(2026, 8, 10),
      );
      final result = BackupImporter.importText(json);
      expect(result.trackers, trackers);
      expect(result.boards, boards);
      expect(result.entries, entries);
      expect(result.warnings, isEmpty);
    });

    test('stamps a version and a creation moment', () {
      final decoded =
          jsonDecode(
                Exporter.toBackupJson(
                  trackers: const <Tracker>[],
                  boards: const <Board>[],
                  entries: const <LogEntry>[],
                ),
              )
              as Map<String, dynamic>;
      final header = decoded['kuhylog']! as Map<String, dynamic>;
      expect(header['version'], Exporter.formatVersion);
      expect(header['created'], isA<String>());
    });
  });

  group('Exporter.toJournalCsv', () {
    test('round trips through the CSV importer', () {
      final csv = Exporter.toJournalCsv(entries);
      final result = CsvImporter.importText(csv);
      expect(result.entries.map((e) => e.note), entries.map((e) => e.note));
      expect(result.entries.first.latitude, 52.2);
      expect(result.warnings, isEmpty);
    });

    test('writes a header even with no entries', () {
      expect(
        Exporter.toJournalCsv(const <LogEntry>[]),
        'date,note,lat,lng,location\n',
      );
    });
  });

  group('Exporter.toTimeCsv', () {
    test('writes one row per day and one column per tracker', () {
      expect(
        Exporter.toTimeCsv(trackers, entries),
        'date,coffee,gym\n'
        '2026-08-08,2.0,\n'
        '2026-08-09,,1.0\n',
      );
    });

    test('writes only the header when nothing was tracked', () {
      expect(
        Exporter.toTimeCsv(trackers, const <LogEntry>[]),
        'date,coffee,gym\n',
      );
    });
  });

  group('Exporter.toTagCsv', () {
    test('counts every tag, most used first', () {
      expect(
        Exporter.toTagCsv(entries),
        'tag,uses\n#coffee,1\n@ola,1\n#gym,1\n',
      );
    });
  });
}
