import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/stats/correlation.dart';

void main() {
  group('Correlation.pearson', () {
    test('a perfect line is one', () {
      expect(
        Correlation.pearson(<double>[1, 2, 3], <double>[2, 4, 6]),
        closeTo(1, 1e-9),
      );
    });

    test('a perfect inverse line is minus one', () {
      expect(
        Correlation.pearson(<double>[1, 2, 3], <double>[6, 4, 2]),
        closeTo(-1, 1e-9),
      );
    });

    test('is null for short or mismatched series', () {
      expect(Correlation.pearson(<double>[1, 2], <double>[1, 2]), isNull);
      expect(
        Correlation.pearson(<double>[1, 2, 3], <double>[1, 2]),
        isNull,
      );
    });

    test('is null when a series has no variance', () {
      expect(
        Correlation.pearson(<double>[1, 1, 1], <double>[1, 2, 3]),
        isNull,
      );
      expect(
        Correlation.pearson(<double>[1, 2, 3], <double>[1, 1, 1]),
        isNull,
      );
    });
  });

  group('Correlation.rank', () {
    test('ranks ascending from one', () {
      expect(Correlation.rank(<double>[10, 30, 20]), <double>[1, 3, 2]);
    });

    test('averages ties', () {
      expect(Correlation.rank(<double>[5, 5, 9]), <double>[1.5, 1.5, 3]);
    });
  });

  group('Correlation.spearman', () {
    test('finds a monotonic but non-linear relationship', () {
      expect(
        Correlation.spearman(
          <double>[1, 2, 3, 4],
          <double>[1, 8, 27, 64],
        ),
        closeTo(1, 1e-9),
      );
    });

    test('is null for a short series', () {
      expect(Correlation.spearman(<double>[1, 2], <double>[1, 2]), isNull);
    });
  });

  group('Correlation.lagged', () {
    test('finds a one day delayed relationship', () {
      final xs = <double>[1, 2, 3, 4, 5];
      final ys = <double>[0, 1, 2, 3, 4];
      expect(Correlation.lagged(xs, ys, 0), closeTo(1, 1e-9));
      expect(Correlation.lagged(xs, ys, 1), closeTo(1, 1e-9));
    });

    test('rejects impossible lags', () {
      final xs = <double>[1, 2, 3];
      expect(Correlation.lagged(xs, xs, -1), isNull);
      expect(Correlation.lagged(xs, xs, 3), isNull);
      expect(Correlation.lagged(xs, <double>[1, 2], 0), isNull);
    });
  });

  group('Correlation.pValue', () {
    test('a strong correlation over many samples is small', () {
      expect(Correlation.pValue(0.9, 40), lessThan(0.001));
    });

    test('no correlation is close to one', () {
      expect(Correlation.pValue(0, 40), closeTo(1, 1e-6));
    });

    test('the sign of the coefficient does not matter', () {
      expect(Correlation.pValue(-0.5, 30), Correlation.pValue(0.5, 30));
    });

    test('too few samples cannot be significant', () {
      expect(Correlation.pValue(0.99, 3), 1);
    });

    test('a perfect correlation is clamped rather than infinite', () {
      expect(Correlation.pValue(1, 30), isNot(isNaN));
      expect(Correlation.pValue(1, 30), lessThan(0.001));
    });
  });

  group('Correlation.falseDiscoveryCutoff', () {
    test('nothing to correct means no cutoff', () {
      expect(Correlation.falseDiscoveryCutoff(<double>[]), isNull);
    });

    test('a clearly significant p survives', () {
      expect(
        Correlation.falseDiscoveryCutoff(<double>[0.001, 0.9, 0.8]),
        0.001,
      );
    });

    test('twenty borderline p values are all rejected', () {
      expect(
        Correlation.falseDiscoveryCutoff(
          List<double>.filled(20, 0.06),
        ),
        isNull,
      );
    });

    test('the same p values survive a laxer alpha', () {
      expect(
        Correlation.falseDiscoveryCutoff(
          List<double>.filled(20, 0.06),
          alpha: 0.5,
        ),
        0.06,
      );
    });
  });
}
