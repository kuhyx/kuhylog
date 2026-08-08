# kuhylog

A local-first life tracker for Android. Arbitrary trackers, people and
context are captured as **one plain-text note per event** — the same
capture model Nomie 5 used — with an importer for Nomie backups.

Not affiliated with Nomie. "Nomie" and its logo are registered
trademarks of Happy Data, LLC; this is a clean-room reimplementation of
the *idea*, sharing no code, and deliberately named otherwise.

## Why the note is the data

Everything structured about an entry lives inside its note:

```
Slept badly #sleep(5:30) too much #coffee(4) with @ola +deadline /wola
```

Trackers, people, context, places and values are all recovered by
parsing that string. This means:

- there is exactly one source of truth per event;
- renaming a tracker is a string operation, not a migration;
- a backup is readable and greppable without this app;
- a note can be typed faster than a form can be filled.

The cost is that the parser is load-bearing. It has 100% coverage.

### Grammar

| Sigil | Meaning | Example |
| --- | --- | --- |
| `#` | tracker | `#sleep`, `#sleep(7.5)` |
| `@` | person | `@ola` |
| `+` | context | `+deadline` |
| `^` | pointer | `^review` |
| `/` | place | `/wola` |

Values accept a number (`7.5`), a duration (`1:06:43` → seconds), or a
small calculation (`3*0.5`). Identifiers accept any Unicode letter, so
`#ćwiczenia` works. A tracker mentioned with no value contributes its
configured default, which is what makes `#coffee #coffee` add up to two.

## Trackers

| Type | Capture | Notes |
| --- | --- | --- |
| `tally` | one tap | records the default value |
| `value` | numeric keypad | |
| `range` | slider | bounded by min/max/step |
| `timer` | duration entry | stored as seconds |
| `picker` | list | stored as the option index |

Each carries a unit, a **positivity** from -5 to 5, sum-or-mean
aggregation, an ignore-zero flag, and optional extra text appended on
every capture (`#beer` can also log `+pub`).

## Stats, and why they are hedged

The stats screen shows daily score, per-tracker totals and streaks, then
runs a lagged correlation scan across every tracker pair. Three guards
stop that from being a random-finding generator:

1. **Ranks, not raw values** — self-tracked scales are ordinal and full
   of outliers, so the scan uses Spearman.
2. **Benjamini-Hochberg correction** — scanning twenty pairs at p<0.05
   is expected to produce a spurious hit; results that do not survive
   correction are labelled "noise level".
3. **A 21-day minimum** — pairs with less overlap are dropped silently.

Even so, daily self-tracking is autocorrelated, which inflates
significance beyond what the correction handles. Output is a hypothesis
worth testing, never evidence. The interface says so on screen.

## Data in and out

No cloud, no account, no file picker: the Data screen is text in, text
out. Paste a backup to import; press an export button to read one.

Importers accept:

- this app's own backup JSON;
- a **Nomie 5/6 key-value dump** — keys like `/v5/data/books/2019-24`,
  `/v5/data/trackers.json`, `/v5/data/boards.json`;
- the **legacy flat shape** — `events`/`notes`/`trackers` plus a `meta`
  record keyed `hyperStorage-groups` holding the boards;
- **journal CSV** (a date column and a note column, lossless) and
  **time CSV** (a date column plus one column per tracker, lossy —
  note text is discarded).

Trackers referenced only inside notes are created automatically with
default settings, and the import reports that in its warnings.

> **Validate before you trust it.** The Nomie shapes above are
> reconstructed from published documentation, not from a byte-verified
> specification. Import a real export, read every warning, and compare
> counts before deleting anything.

On disk the store is one file per month plus two index files:

```
<app documents>/kuhylog/
  trackers.json
  boards.json
  books/2026-08.json
```

## Two decisions that look wrong and are not

**Store IO is synchronous.** Real asynchronous file IO never completes
inside the fake-async zone `testWidgets` runs in, which makes an async
store untestable at the widget level. The data set is a few hundred
kilobytes. Do not "modernise" this without also solving the test
problem; the reasoning is repeated in `MemoryStore`'s doc comment so it
survives a future refactor.

**`main` does almost nothing.** `runApp` attaches a root widget to the
binding for the remainder of a test file, so the entry point is one line
delegating to `bootstrap`, and it is exercised in its own isolated
`test/main_test.dart`.

## Running it

```bash
flutter pub get
flutter run                 # needs an Android SDK
./tool/verify.sh            # format, analyze, test, coverage gate
```

## Quality gates

`tool/verify.sh` runs all four and CI runs the same script:

| Gate | Setting |
| --- | --- |
| Format | `dart format --set-exit-if-changed` |
| Lints | `very_good_analysis` 10.3.0 + `strict-casts`, `strict-inference`, `strict-raw-types`, 9 rules promoted to errors, 12 extra rules |
| Analyzer | `flutter analyze --fatal-infos --fatal-warnings` |
| Coverage | `tool/coverage.sh` — fails on a single uncovered line, and on any `lib/` file missing from the report entirely |

Verified on Flutter 3.44.9 / Dart 3.12.2: **266 tests, 1614/1614 lines
(100.00%) across 40 files**, analyzer clean.

The coverage gate was confirmed to bite: adding one unreachable branch
made it exit 1 and name the file and line numbers.

## What is not verified

`flutter build apk` has **never been run** against this tree — the
sandbox it was written in had no Android SDK. The `android` job in CI is
the first place that happens. Until it goes green, treat the Android
build as unproven.

## Roadmap, in value order

1. **Home-screen widget** (`home_widget`) and a **quick-settings tile**
   for one-tap capture without opening the app. Friction is what kills
   habit trackers, and this is the whole reason to be native rather than
   a PWA.
2. **Notification actions** (`flutter_local_notifications`) so a
   reminder can be answered from the shade.
3. Validate the Nomie importer against a real export.
4. Optional CouchDB-shaped sync, matching what Nomie 6 does, so the
   phone and a self-hosted server can share history.

## Licence

MIT. See `LICENSE`.
