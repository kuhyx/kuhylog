import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';

void main() {
  group('NoteTokenizer.parse', () {
    test('finds every sigil', () {
      final refs = NoteTokenizer.parse('#a @b +c ^d /e');
      expect(
        refs.map((r) => r.type),
        <TrackableType>[
          TrackableType.tracker,
          TrackableType.person,
          TrackableType.context,
          TrackableType.pointer,
          TrackableType.place,
        ],
      );
    });

    test('parses a tag at the very start and after punctuation', () {
      expect(NoteTokenizer.parse('#a').single.id, 'a');
      expect(NoteTokenizer.parse('(#a)').single.id, 'a');
      expect(NoteTokenizer.parse('x, #a').single.id, 'a');
      expect(NoteTokenizer.parse('"#a"').single.id, 'a');
    });

    test('lower cases identifiers and keeps Polish letters', () {
      expect(NoteTokenizer.parse('#Ćwiczenia').single.id, 'ćwiczenia');
    });

    test('allows underscores, hyphens and digits inside a tag', () {
      expect(NoteTokenizer.parse('#deep-work_2').single.id, 'deep-work_2');
    });

    test('parses values, durations and arithmetic', () {
      final refs = NoteTokenizer.parse('#a(7.5) #b(1:30) #c(3*2) #d()');
      expect(refs[0].value, 7.5);
      expect(refs[1].value, 90);
      expect(refs[2].value, 6);
      expect(refs[3].value, isNull);
      expect(refs[3].rawValue, '');
    });

    test('keeps the raw source of each reference', () {
      expect(NoteTokenizer.parse('hi #a(2)').single.raw, '#a(2)');
    });

    test('does not treat a URL as a place', () {
      expect(NoteTokenizer.parse('see https://x.dev/page'), isEmpty);
    });

    test('does not match a bare sigil', () {
      expect(NoteTokenizer.parse('# @ + cost 5 + 3'), isEmpty);
    });

    test('an unmatched sigil inside a word is ignored', () {
      expect(NoteTokenizer.parse('e-mail me at a@b.dev'), isEmpty);
    });
  });

  group('NoteTokenizer.parseOfType', () {
    test('filters by type', () {
      final people = NoteTokenizer.parseOfType(
        '#a @b @c',
        TrackableType.person,
      );
      expect(people.map((r) => r.id), <String>['b', 'c']);
    });
  });

  group('NoteTokenizer.trackerValues', () {
    test('sums repeated mentions and applies the fallback', () {
      final values = NoteTokenizer.trackerValues('#w(1) #w #x(4) @y');
      expect(values, <String, double>{'w': 2, 'x': 4});
    });

    test('uses a custom fallback', () {
      expect(
        NoteTokenizer.trackerValues('#w', fallback: 5),
        <String, double>{'w': 5},
      );
    });
  });

  group('NoteTokenizer.stripTags', () {
    test('removes tags and collapses whitespace', () {
      expect(
        NoteTokenizer.stripTags('Slept  well #sleep(7.5) with @ola'),
        'Slept well with',
      );
    });

    test('leaves a note with no tags alone', () {
      expect(NoteTokenizer.stripTags('just words'), 'just words');
    });
  });

  group('NoteTokenizer.rename', () {
    test('renames only the requested type', () {
      expect(
        NoteTokenizer.rename(
          '#work +work',
          TrackableType.tracker,
          'work',
          'job',
        ),
        '#job +work',
      );
    });

    test('keeps the value attached', () {
      expect(
        NoteTokenizer.rename('#a(7)', TrackableType.tracker, 'a', 'b'),
        '#b(7)',
      );
    });

    test('renaming something absent is a no-op', () {
      expect(
        NoteTokenizer.rename('#a', TrackableType.tracker, 'z', 'y'),
        '#a',
      );
    });
  });
}
