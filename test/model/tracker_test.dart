import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/model/uom.dart';

void main() {
  group('TrackerType', () {
    test('maps every accepted name', () {
      expect(TrackerType.parse('tick'), TrackerType.tally);
      expect(TrackerType.parse('tally'), TrackerType.tally);
      expect(TrackerType.parse('value'), TrackerType.value);
      expect(TrackerType.parse('numeric'), TrackerType.value);
      expect(TrackerType.parse('range'), TrackerType.range);
      expect(TrackerType.parse('slider'), TrackerType.range);
      expect(TrackerType.parse('timer'), TrackerType.timer);
      expect(TrackerType.parse('picker'), TrackerType.picker);
      expect(TrackerType.parse('pick'), TrackerType.picker);
      expect(TrackerType.parse('nonsense'), TrackerType.tally);
    });
  });

  group('TrackerMath', () {
    test('maps every accepted name', () {
      expect(TrackerMath.parse('mean'), TrackerMath.mean);
      expect(TrackerMath.parse('avg'), TrackerMath.mean);
      expect(TrackerMath.parse('average'), TrackerMath.mean);
      expect(TrackerMath.parse('sum'), TrackerMath.sum);
      expect(TrackerMath.parse(''), TrackerMath.sum);
    });
  });

  group('Tracker.slug', () {
    test('lower cases and collapses punctuation', () {
      expect(Tracker.slug('Deep Work!'), 'deep_work');
      expect(Tracker.slug('  --Coffee--  '), 'coffee');
    });

    test('keeps Polish letters', () {
      expect(Tracker.slug('Ćwiczenia'), 'ćwiczenia');
    });

    test('an unusable label yields an empty tag', () {
      expect(Tracker.slug('---'), '');
    });
  });

  group('Tracker', () {
    test('hashtag and glyph', () {
      const withEmoji = Tracker(tag: 'gym', label: 'Gym', emoji: '🏋️');
      const withoutEmoji = Tracker(tag: 'gym', label: 'Gym');
      const withoutLabel = Tracker(tag: 'gym', label: '');
      expect(withEmoji.hashtag, '#gym');
      expect(withEmoji.glyph, '🏋️');
      expect(withoutEmoji.glyph, 'G');
      expect(withoutLabel.glyph, '#');
    });

    test('round trips through JSON', () {
      const tracker = Tracker(
        tag: 'sleep',
        label: 'Sleep',
        emoji: '😴',
        color: 0xFF112233,
        type: TrackerType.value,
        uom: Uom.hour,
        min: 1,
        max: 12,
        step: 0.5,
        defaultValue: 8,
        math: TrackerMath.mean,
        positivity: 3,
        hidden: true,
        ignoreZero: true,
        options: <String>['a', 'b'],
        alsoInclude: '+rested',
      );
      expect(Tracker.fromJson(tracker.toJson()), tracker);
    });

    test('reads Nomie field names and a hex colour', () {
      final tracker = Tracker.fromJson(const <String, dynamic>{
        '_id': 'Water Intake',
        'type': 'tick',
        'color': '#ff0000',
        'score': 2,
        'ignore_zero': true,
        'picks': <String>['x'],
        'include': '#extra',
      });
      expect(tracker.tag, 'water_intake');
      expect(tracker.label, 'water_intake');
      expect(tracker.type, TrackerType.tally);
      expect(tracker.color, 0xFFFF0000);
      expect(tracker.positivity, 2);
      expect(tracker.ignoreZero, isTrue);
      expect(tracker.options, <String>['x']);
      expect(tracker.alsoInclude, '#extra');
    });

    test('accepts a short hex colour and rejects a broken one', () {
      int colorOf(String value) => Tracker.fromJson(<String, dynamic>{
        'tag': 'a',
        'color': value,
      }).color;
      expect(colorOf('#f00'), 0xFFFF0000);
      expect(colorOf('#zzzzzz'), 0xFF3B82F6);
      expect(colorOf('red'), 0xFF3B82F6);
    });

    test('falls back from tag to id to label', () {
      expect(
        Tracker.fromJson(const <String, dynamic>{'label': 'Only Label'}).tag,
        'only_label',
      );
    });

    test('copyWith replaces every field', () {
      const base = Tracker(tag: 'a', label: 'A');
      final copy = base.copyWith(
        tag: 'b',
        label: 'B',
        emoji: 'x',
        color: 1,
        type: TrackerType.timer,
        uom: Uom.second,
        min: 2,
        max: 3,
        step: 4,
        defaultValue: 5,
        math: TrackerMath.mean,
        positivity: -2,
        hidden: true,
        ignoreZero: true,
        options: <String>['o'],
        alsoInclude: 'i',
      );
      expect(copy.tag, 'b');
      expect(copy.label, 'B');
      expect(copy.emoji, 'x');
      expect(copy.color, 1);
      expect(copy.type, TrackerType.timer);
      expect(copy.uom, Uom.second);
      expect(copy.min, 2);
      expect(copy.max, 3);
      expect(copy.step, 4);
      expect(copy.defaultValue, 5);
      expect(copy.math, TrackerMath.mean);
      expect(copy.positivity, -2);
      expect(copy.hidden, isTrue);
      expect(copy.ignoreZero, isTrue);
      expect(copy.options, <String>['o']);
      expect(copy.alsoInclude, 'i');
      expect(base.copyWith(), base);
    });

    test('equality, hashCode and toString', () {
      const a = Tracker(tag: 'a', label: 'A');
      const b = Tracker(tag: 'a', label: 'A');
      const c = Tracker(tag: 'a', label: 'B');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == Object(), isFalse);
      expect(a.toString(), 'Tracker(#a)');
    });
  });
}
