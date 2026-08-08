import 'package:flutter/material.dart';

/// The single theme definition, kept out of the widgets that use it.
abstract final class KuhylogTheme {
  /// Seed colour the palette is derived from.
  static const Color seed = Color(0xFF3B82F6);

  /// Builds the theme for a given [brightness].
  static ThemeData of(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Colour used for a score, green when positive and red when not.
  static Color scoreColor(ColorScheme scheme, int score) {
    if (score > 0) {
      return scheme.primary;
    }
    if (score < 0) {
      return scheme.error;
    }
    return scheme.outline;
  }
}
