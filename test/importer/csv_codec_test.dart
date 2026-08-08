import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/csv_codec.dart';

void main() {
  group('CsvCodec.decode', () {
    test('splits plain rows', () {
      expect(
        CsvCodec.decode('a,b\n1,2\n'),
        <List<String>>[
          <String>['a', 'b'],
          <String>['1', '2'],
        ],
      );
    });

    test('handles a missing trailing newline', () {
      expect(CsvCodec.decode('a,b'), <List<String>>[
        <String>['a', 'b'],
      ]);
    });

    test('handles quoted fields with commas and newlines', () {
      expect(
        CsvCodec.decode('a,"b,c"\n"line\nbreak",d\n'),
        <List<String>>[
          <String>['a', 'b,c'],
          <String>['line\nbreak', 'd'],
        ],
      );
    });

    test('unescapes doubled quotes', () {
      expect(CsvCodec.decode('"say ""hi"""'), <List<String>>[
        <String>['say "hi"'],
      ]);
    });

    test('handles carriage returns', () {
      expect(
        CsvCodec.decode('a,b\r\n1,2\r\n'),
        <List<String>>[
          <String>['a', 'b'],
          <String>['1', '2'],
        ],
      );
      expect(CsvCodec.decode('a\r'), <List<String>>[
        <String>['a'],
      ]);
    });

    test('keeps empty fields', () {
      expect(CsvCodec.decode('a,,b'), <List<String>>[
        <String>['a', '', 'b'],
      ]);
      expect(CsvCodec.decode('""'), <List<String>>[
        <String>[''],
      ]);
    });

    test('skips blank lines', () {
      expect(CsvCodec.decode('a\n\n\nb'), <List<String>>[
        <String>['a'],
        <String>['b'],
      ]);
    });

    test('an empty source has no rows', () {
      expect(CsvCodec.decode(''), isEmpty);
    });
  });

  group('CsvCodec.encode', () {
    test('quotes only what needs quoting', () {
      expect(
        CsvCodec.encode(<List<String>>[
          <String>['a', 'b,c', 'say "hi"', 'line\nbreak', 'cr\r'],
        ]),
        'a,"b,c","say ""hi""","line\nbreak","cr\r"\n',
      );
    });

    test('round trips through decode', () {
      final rows = <List<String>>[
        <String>['date', 'note'],
        <String>['2026-08-08', 'coffee, black #coffee(1)'],
      ];
      expect(CsvCodec.decode(CsvCodec.encode(rows)), rows);
    });

    test('escape leaves plain text alone', () {
      expect(CsvCodec.escape('plain'), 'plain');
    });
  });
}
