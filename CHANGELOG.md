# Changelog

## 0.1.0 — unreleased

First cut. Everything below is verified by `tool/verify.sh`.

### Added
- Note grammar: `#tracker(value)`, `@person`, `+context`, `^pointer`,
  `/place`, with Unicode identifiers, `h:mm:ss` durations and inline
  arithmetic.
- Five tracker types (tally, value, range, timer, picker) with unit,
  positivity, default value, sum/mean, ignore-zero and also-include.
- Month-bucketed synchronous JSON store, plus an in-memory one.
- Importers for the native backup, Nomie 5/6 key dumps, the legacy
  `hyperStorage-groups` shape, and both CSV layouts.
- Exporters for backup JSON, journal CSV, time CSV and tag CSV.
- Stats: daily scores, aggregation, streaks, and a lagged Spearman scan
  with Benjamini-Hochberg correction and a minimum sample size.
- Three-tab interface: track board, timeline, stats; capture sheet,
  tracker editor and a text-in/text-out data page.
- Quick-capture bridge over one method channel, plus an Android
  home-screen widget and quick-settings tile that use it.
- Linux desktop target, for trying the UI without a phone. It keeps its
  own store and has no quick-capture handler.

### Fixed
- The quick-settings tile no longer crashes on tap. The bare
  `startActivityAndCollapse(Intent)` throws `UnsupportedOperationException`
  from API 34 on; it now passes a `PendingIntent` above that level.

### Known gaps
- The Nomie importer is written against published documentation, not a
  byte-verified specification. Validate it against a real export.
- `flutter build apk` now compiles clean, and the quick-settings tile is
  verified on a real device. The home-screen widget and both method-channel
  directions are still unverified on hardware. See `doc/quick-capture.md`.
- Ships the stock Flutter launcher icon.
- A widget tap forwards through `MainActivity` rather than recording
  headlessly, so it briefly opens the app.
- No notification actions yet.
