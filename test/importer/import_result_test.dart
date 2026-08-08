import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/importer/import_result.dart';
import 'package:kuhylog/src/model/tracker.dart';

void main() {
  group('ImportResult', () {
    test('an empty result knows it', () {
      expect(const ImportResult().isEmpty, isTrue);
    });

    test('summary counts everything', () {
      const result = ImportResult(
        trackers: <Tracker>[Tracker(tag: 'a', label: 'A')],
        warnings: <String>['w'],
      );
      expect(result.isEmpty, isFalse);
      expect(
        result.summary,
        '0 entries, 1 trackers, 0 boards, 1 warnings',
      );
      expect(result.toString(), contains('ImportResult('));
    });
  });
}
