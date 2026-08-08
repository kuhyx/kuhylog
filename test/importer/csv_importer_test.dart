import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/csv_importer.dart';

void main() {
  group('CsvImporter journal shape', () {
    test('reads dates, notes and coordinates', () {
      final result = CsvImporter.importText(
        'date,note,lat,lng,location\n'
        '2026-08-08T09:00:00,"coffee, black #coffee(1)",52.2,21.0,Wola\n',
      );
      final entry = result.entries.single;
      expect(entry.end, DateTime(2026, 8, 8, 9));
      expect(entry.note, 'coffee, black #coffee(1)');
      expect(entry.latitude, 52.2);
      expect(entry.longitude, 21.0);
      expect(entry.location, 'Wola');
      expect(entry.source, 'csv');
      expect(result.trackers.single.tag, 'coffee');
    });

    test('accepts alternative column names', () {
      final result = CsvImporter.importText(
        'timestamp,text\n2026-08-08T09:00:00,#a\n',
      );
      expect(result.entries.single.note, '#a');
    });

    test('warns about an unreadable date and keeps going', () {
      final result = CsvImporter.importText(
        'date,note\n'
        'not-a-date,#a\n'
        '2026-08-08T09:00:00,#b\n',
      );
      expect(result.entries.single.note, '#b');
      expect(result.warnings.single, startsWith('Row 2'));
    });

    test('tolerates short rows', () {
      final result = CsvImporter.importText(
        'date,note,lat\n2026-08-08T09:00:00\n',
      );
      expect(result.entries.single.note, '');
      expect(result.entries.single.latitude, isNull);
    });

    test('sorts entries oldest first', () {
      final result = CsvImporter.importText(
        'date,note\n'
        '2026-08-09T09:00:00,#b\n'
        '2026-08-08T09:00:00,#a\n',
      );
      expect(result.entries.map((e) => e.note), <String>['#a', '#b']);
    });
  });

  group('CsvImporter time shape', () {
    test('synthesises a note from numeric columns', () {
      final result = CsvImporter.importText(
        'date,sleep,Deep Work\n'
        '2026-08-08,7.5,120\n',
      );
      expect(result.entries.single.note, '#sleep(7.5) #deep_work(120)');
      expect(
        result.trackers.map((t) => t.tag),
        <String>['deep_work', 'sleep'],
      );
    });

    test('skips empty cells and warns about non-numeric ones', () {
      final result = CsvImporter.importText(
        'date,sleep,mood\n'
        '2026-08-08,,great\n'
        '2026-08-09,8,\n',
      );
      expect(result.entries.single.note, '#sleep(8)');
      expect(result.warnings.single, contains('great'));
    });

    test('warns about an unreadable date', () {
      final result = CsvImporter.importText('date,sleep\nnope,8\n');
      expect(result.entries, isEmpty);
      expect(result.warnings.single, startsWith('Row 2'));
    });
  });

  group('CsvImporter failures', () {
    test('an empty file warns', () {
      expect(CsvImporter.importText('').warnings.single, 'CSV was empty');
    });

    test('a missing date column warns', () {
      final result = CsvImporter.importText('a,b\n1,2\n');
      expect(result.warnings.single, startsWith('No date column'));
      expect(result.isEmpty, isTrue);
    });
  });
}
