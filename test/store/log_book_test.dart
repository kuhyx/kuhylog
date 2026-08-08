import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/store/log_book.dart';

void main() {
  group('LogBook', () {
    test('keys are zero padded months', () {
      expect(LogBook.keyFor(DateTime(2026, 8, 8)), '2026-08');
      expect(LogBook.keyFor(DateTime(2026, 11)), '2026-11');
    });

    test('startOf reverses keyFor', () {
      expect(LogBook.startOf('2026-08'), DateTime(2026, 8));
    });

    test('startOf rejects anything that is not a key', () {
      expect(() => LogBook.startOf('2026'), throwsFormatException);
      expect(() => LogBook.startOf('20x6-08'), throwsFormatException);
      expect(() => LogBook.startOf('2026-xx'), throwsFormatException);
      expect(() => LogBook.startOf('2026-13'), throwsFormatException);
      expect(() => LogBook.startOf('2026-00'), throwsFormatException);
    });

    test('keysBetween spans a year boundary', () {
      expect(
        LogBook.keysBetween(DateTime(2025, 11, 20), DateTime(2026, 2, 3)),
        <String>['2025-11', '2025-12', '2026-01', '2026-02'],
      );
    });

    test('keysBetween of a reversed range is empty', () {
      expect(
        LogBook.keysBetween(DateTime(2026, 5), DateTime(2026, 4)),
        isEmpty,
      );
    });
  });
}
