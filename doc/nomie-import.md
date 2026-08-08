# Nomie import: what is assumed, and how to check it

The importer in `lib/src/importer/backup_importer.dart` was written from
published documentation about Nomie's storage, **not** from a
byte-verified specification. Two source files that would settle the
remaining questions could not be fetched while this was written:

- `src/modules/tracker/tracker.ts`
- `src/modules/nomie-log/nomie-log.ts`

Read those in `open-nomie/nomie5` (branch `v5-develop`) before trusting
a large import.

## Shapes the importer recognises

| Shape | Detected by | Contents |
| --- | --- | --- |
| native | `logs`, `trackers`, `boards` | this app's own export |
| Nomie 5/6 dump | a key containing `/books/`, or ending `/trackers.json`, `/boards.json` | one array of logs per period; trackers as a map keyed by tag; boards as an array |
| legacy flat | `events` or `notes`; `meta` | logs in `events`/`notes`; boards in the `meta` record whose `_id` is `hyperStorage-groups`, under `groups` |

Records inside any shape are read by `LogEntry.fromJson` and
`Tracker.fromJson`, which accept both naming conventions.

## Field mapping

| Concept | Accepted keys | Notes |
| --- | --- | --- |
| entry id | `_id`, `id` | Nomie wrote `<epoch-millis>-<6 hex>` |
| moment | `end`, `date`, `created` | ISO 8601 or epoch milliseconds; Nomie's REST API used `date` while the stored field was `end` |
| timer start | `start` | |
| payload | `note` | every tracker, person and context lives here |
| position | `lat`, `lng` | |
| place | `location` | |
| tracker id | `tag`, `_id`, `label` | in that order; slugged |
| tracker type | `type` | `tick`→tally, `value`/`numeric`→value, `range`/`slider`→range, `timer`, `picker`/`pick` |
| positivity | `score` | |
| bare-mention value | `default` | |
| aggregation | `math` | `avg`/`average`/`mean`→mean, else sum |
| skip zeroes | `ignore_zero` | |
| picker options | `picks` | |
| appended text | `include` | |
| colour | `color` | `#rgb` or `#rrggbb`; anything else falls back |

Unknown tracker types degrade to `tally` rather than throwing: an
approximate tracker beats an unimportable one.

## How to validate against a real export

1. In Nomie 6 (`open-nomie.github.io` or a self-hosted build), export a
   **Backup JSON** and both CSV layouts.
2. Paste the JSON into the Data screen and press **Import JSON**.
3. Read every warning. `N trackers were not configured in the backup`
   is normal for tags used only in notes; `Skipped "<key>"` is not, and
   means a section had an unexpected type.
4. Compare counts against the source. In Nomie, the entry count is
   visible per book; here, export a **Tag CSV** and total the uses.
5. Spot-check the oldest and newest entries for the correct local time.
   A whole-history offset means a timezone assumption is wrong.
6. Check a tracker that used a duration (`#sleep(6:43:99)`) and one that
   used a calculation (`#alcohol(3*0.06)`), since those are the two
   value notations most likely to differ.

If a shape is missing, the fix is a new branch in
`BackupImporter.importJson` plus a fixture test in
`test/importer/backup_importer_test.dart` — the existing tests show the
pattern for all three shapes.
