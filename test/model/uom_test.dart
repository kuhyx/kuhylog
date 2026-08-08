import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/uom.dart';

void main() {
  group('Uom', () {
    test('every unit has a label and formats a value', () {
      for (final unit in Uom.values) {
        expect(unit.label, isNotEmpty);
        expect(unit.format(3), isNotEmpty);
      }
    });

    test('count omits the symbol', () {
      expect(Uom.count.format(4), '4');
    });

    test('other units append the symbol', () {
      expect(Uom.hour.format(7), '7 h');
      expect(Uom.kilogram.format(80.5), '80.5 kg');
    });

    test('rounds to two decimal places', () {
      expect(Uom.gram.format(1.23456), '1.23 g');
    });

    test('seconds render as a duration', () {
      expect(Uom.second.format(90), '1:30');
      expect(Uom.second.format(3661), '1:01:01');
    });

    test('negative durations keep their sign', () {
      expect(Uom.formatDuration(-90), '-1:30');
    });

    test('parse maps names and falls back to count', () {
      expect(Uom.parse('hour'), Uom.hour);
      expect(Uom.parse('furlong'), Uom.count);
    });
  });
}
