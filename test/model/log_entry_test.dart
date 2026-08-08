import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/log_entry.dart';

void main() {
  final moment = DateTime(2026, 8, 8, 14, 30);

  group('LogEntry', () {
    test('exposes parsed trackables', () {
      final entry = LogEntry(
        id: '1',
        end: moment,
        note: 'Ran #run(5) with @ola +park /warsaw',
      );
      expect(entry.trackerTags, <String>{'run'});
      expect(entry.people, <String>{'ola'});
      expect(entry.contexts, <String>{'park'});
      expect(entry.refs, hasLength(4));
      expect(entry.text, 'Ran with');
      expect(entry.day, DateTime(2026, 8, 8));
    });

    test('duration is null unless there is a start', () {
      final instant = LogEntry(id: '1', end: moment, note: '');
      final timed = LogEntry(
        id: '2',
        end: moment,
        start: moment.subtract(const Duration(minutes: 25)),
        note: '',
      );
      expect(instant.duration, isNull);
      expect(timed.duration, const Duration(minutes: 25));
    });

    test('round trips through JSON', () {
      final entry = LogEntry(
        id: '1',
        end: moment,
        start: moment.subtract(const Duration(minutes: 5)),
        note: '#a(1)',
        latitude: 52.2,
        longitude: 21,
        location: 'Wola',
        source: 'test',
      );
      expect(LogEntry.fromJson(entry.toJson()), entry);
    });

    test('omits absent optional fields from JSON', () {
      final json = LogEntry(id: '1', end: moment, note: '').toJson();
      expect(json.containsKey('start'), isFalse);
      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('lng'), isFalse);
    });

    test('reads the Nomie date field and an epoch', () {
      expect(
        LogEntry.fromJson(<String, dynamic>{
          'date': moment.toIso8601String(),
        }).end,
        moment,
      );
      expect(
        LogEntry.fromJson(const <String, dynamic>{'created': 1000}).end,
        DateTime.fromMillisecondsSinceEpoch(1000),
      );
    });

    test('a missing date becomes the epoch rather than throwing', () {
      final entry = LogEntry.fromJson(const <String, dynamic>{'note': 'x'});
      expect(entry.end.millisecondsSinceEpoch, 0);
      expect(entry.source, 'import');
    });

    test('falls back from _id to id', () {
      expect(LogEntry.fromJson(const <String, dynamic>{'id': 'x'}).id, 'x');
    });

    test('parseMoment handles every accepted shape', () {
      expect(LogEntry.parseMoment(1000).millisecondsSinceEpoch, 1000);
      expect(LogEntry.parseMoment('1000').millisecondsSinceEpoch, 1000);
      expect(LogEntry.parseMoment('2026-08-08T00:00:00Z').isUtc, isFalse);
      expect(
        LogEntry.parseMoment('2026-08-08T10:00:00'),
        DateTime(2026, 8, 8, 10),
      );
      expect(LogEntry.parseMoment('rubbish').millisecondsSinceEpoch, 0);
      expect(LogEntry.parseMoment(null).millisecondsSinceEpoch, 0);
    });

    test('generateId is deterministic given a seeded random', () {
      final id = LogEntry.generateId(moment, Random(1));
      expect(id, LogEntry.generateId(moment, Random(1)));
      expect(id, startsWith('${moment.millisecondsSinceEpoch}-'));
      expect(id.split('-').last, hasLength(6));
    });

    test('copyWith replaces every field', () {
      final base = LogEntry(id: '1', end: moment, note: 'a');
      final copy = base.copyWith(
        id: '2',
        end: moment.add(const Duration(days: 1)),
        start: moment,
        note: 'b',
        latitude: 1,
        longitude: 2,
        location: 'x',
        source: 'y',
      );
      expect(copy.id, '2');
      expect(copy.end, moment.add(const Duration(days: 1)));
      expect(copy.start, moment);
      expect(copy.note, 'b');
      expect(copy.latitude, 1);
      expect(copy.longitude, 2);
      expect(copy.location, 'x');
      expect(copy.source, 'y');
      expect(base.copyWith(), base);
    });

    test('equality, hashCode and toString', () {
      final a = LogEntry(id: '1', end: moment, note: 'x');
      final b = LogEntry(id: '1', end: moment, note: 'x');
      final c = LogEntry(id: '1', end: moment, note: 'y');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == Object(), isFalse);
      expect(a.toString(), 'LogEntry(1, x)');
    });
  });
}
