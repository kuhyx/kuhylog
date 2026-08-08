import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/ui/theme.dart';

void main() {
  group('KuhylogTheme', () {
    test('builds a theme for both brightnesses', () {
      for (final brightness in Brightness.values) {
        final theme = KuhylogTheme.of(brightness);
        expect(theme.colorScheme.brightness, brightness);
        expect(theme.useMaterial3, isTrue);
      }
    });

    test('score colours are distinct', () {
      final scheme = KuhylogTheme.of(Brightness.light).colorScheme;
      expect(KuhylogTheme.scoreColor(scheme, 1), scheme.primary);
      expect(KuhylogTheme.scoreColor(scheme, -1), scheme.error);
      expect(KuhylogTheme.scoreColor(scheme, 0), scheme.outline);
    });
  });
}
