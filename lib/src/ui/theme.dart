import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The single theme definition, kept out of the widgets that use it.
abstract final class KuhylogTheme {
  /// Builds the theme for a given [brightness].
  ///
  /// This used to be `ColorScheme.fromSeed(0xFF3B82F6)` — a blue derived
  /// palette, and the only app in the fleet doing so. Every other theme file
  /// explicitly documents *not* using `fromSeed`, because the shared palette
  /// is hand-picked to hit specific contrast ratios and a seeded scheme
  /// silently replaces those values with algorithmically derived ones. It now
  /// comes from `design_system`, so this app is on the same gold palette as
  /// everything else.
  static ThemeData of(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? buildDarkTheme()
        : buildLightTheme();
    return base.copyWith(
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  /// Colour used for a score: the accent when positive, the error colour when
  /// negative, and a muted outline at zero.
  ///
  /// Takes the [ColorScheme] rather than reading colours directly, so it
  /// follows whatever theme is in force instead of pinning its own.
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
