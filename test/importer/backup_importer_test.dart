import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/backup_importer.dart';

void main() {
  group('BackupImporter', () {
    test('reads the native shape', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'kuhylog': <String, dynamic>{'version': 1},
          'trackers': <Map<String, dynamic>>[
            <String, dynamic>{'tag': 'gym', 'label': 'Gym', 'score': 4},
          ],
          'boards': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'health',
              'label': 'Health',
              'trackers': <String>['gym'],
            },
          ],
          'logs': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': '1',
              'end': '2026-08-08T09:00:00',
              'note': '#gym',
            },
          ],
        }),
      );
      expect(result.trackers.single.positivity, 4);
      expect(result.boards.single.id, 'health');
      expect(result.entries.single.note, '#gym');
      expect(result.warnings, isEmpty);
      expect(result.isEmpty, isFalse);
    });

    test('reads a Nomie 5 key-value dump', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          '/v5/data/trackers.json': <String, dynamic>{
            'coffee': <String, dynamic>{'label': 'Coffee', 'type': 'tick'},
          },
          '/v5/data/boards.json': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'daily',
              'label': 'Daily',
              'trackers': <String>['coffee'],
            },
          ],
          '/v5/data/books/2019-24': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'a',
              'end': '2019-06-10T08:00:00',
              'note': '#coffee(2) @ola',
              'lat': 52.2,
              'lng': 21.0,
            },
          ],
          '/v5/data/books/2019-25': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'b',
              'end': '2019-06-17T08:00:00',
              'note': '#coffee',
            },
          ],
        }),
      );
      expect(result.trackers.single.tag, 'coffee');
      expect(result.boards.single.label, 'Daily');
      expect(result.entries.map((e) => e.id), <String>['a', 'b']);
      expect(result.entries.first.latitude, 52.2);
    });

    test('reads the legacy shape with meta groups', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'events': <Map<String, dynamic>>[
            <String, dynamic>{'_id': '1', 'end': 1000, 'note': '#a'},
          ],
          'trackers': <Map<String, dynamic>>[
            <String, dynamic>{'_id': 'a', 'label': 'A'},
          ],
          'meta': <dynamic>[
            'not a map',
            <String, dynamic>{'_id': 'hyperStorage-other'},
            <String, dynamic>{
              '_id': 'hyperStorage-groups',
              'groups': <String, dynamic>{
                'Morning Board': <String>['a'],
              },
            },
          ],
        }),
      );
      expect(result.boards.single.id, 'morning_board');
      expect(result.boards.single.label, 'Morning Board');
      expect(result.boards.single.trackerTags, <String>['a']);
      expect(result.entries.single.note, '#a');
    });

    test('meta that is not a list is ignored', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{'meta': 5, 'logs': <dynamic>[]}),
      );
      expect(result.boards, isEmpty);
    });

    test('infers trackers used only in notes', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'logs': <Map<String, dynamic>>[
            <String, dynamic>{'_id': '1', 'end': 1000, 'note': '#water #tea'},
          ],
        }),
      );
      expect(result.trackers.map((t) => t.tag), <String>['tea', 'water']);
      expect(result.warnings.single, contains('2 trackers'));
    });

    test('a bare array is treated as logs', () {
      final result = BackupImporter.importText(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'_id': '1', 'end': 1000, 'note': 'x'},
        ]),
      );
      expect(result.entries, hasLength(1));
    });

    test('warns instead of throwing on malformed JSON', () {
      final result = BackupImporter.importText('{oops');
      expect(result.isEmpty, isTrue);
      expect(result.warnings.single, startsWith('Not valid JSON'));
    });

    test('warns when the root is neither an object nor an array', () {
      final result = BackupImporter.importText('42');
      expect(result.warnings.single, contains('object or array'));
    });

    test('warns when a section has the wrong type', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'logs': 5,
          'trackers': 'nope',
          'boards': 7,
        }),
      );
      expect(result.warnings, hasLength(3));
      expect(result.warnings.first, contains('logs'));
    });

    test('skips records with no identifier', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'trackers': <Map<String, dynamic>>[<String, dynamic>{}],
          'boards': <Map<String, dynamic>>[<String, dynamic>{}],
        }),
      );
      expect(result.trackers, isEmpty);
      expect(result.boards, isEmpty);
      expect(result.warnings, hasLength(2));
    });

    test('sorts entries oldest first', () {
      final result = BackupImporter.importText(
        jsonEncode(<String, dynamic>{
          'logs': <Map<String, dynamic>>[
            <String, dynamic>{'_id': 'b', 'end': 2000, 'note': ''},
            <String, dynamic>{'_id': 'a', 'end': 1000, 'note': ''},
          ],
        }),
      );
      expect(result.entries.map((e) => e.id), <String>['a', 'b']);
    });
  });
}
