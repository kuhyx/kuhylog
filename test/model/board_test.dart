import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/board.dart';

void main() {
  group('Board', () {
    test('round trips through JSON', () {
      const board = Board(
        id: 'health',
        label: 'Health',
        trackerTags: <String>['gym', 'sleep'],
      );
      expect(Board.fromJson(board.toJson()), board);
    });

    test('fills a missing id from the label and back', () {
      expect(
        Board.fromJson(const <String, dynamic>{'label': 'Work'}).id,
        'work',
      );
      expect(
        Board.fromJson(const <String, dynamic>{'id': 'work'}).label,
        'work',
      );
    });

    test('the implicit board knows itself', () {
      expect(Board.all.isAll, isTrue);
      expect(const Board(id: 'x', label: 'X').isAll, isFalse);
    });

    test('copyWith replaces every field', () {
      const base = Board(id: 'a', label: 'A');
      final copy = base.copyWith(
        id: 'b',
        label: 'B',
        trackerTags: <String>['t'],
      );
      expect(copy.id, 'b');
      expect(copy.label, 'B');
      expect(copy.trackerTags, <String>['t']);
      expect(base.copyWith(), base);
    });

    test('equality, hashCode and toString', () {
      const a = Board(id: 'a', label: 'A', trackerTags: <String>['x']);
      const b = Board(id: 'a', label: 'A', trackerTags: <String>['x']);
      const c = Board(id: 'a', label: 'A', trackerTags: <String>['y']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == Object(), isFalse);
      expect(a.toString(), 'Board(a)');
    });
  });
}
