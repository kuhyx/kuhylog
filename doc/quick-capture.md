# Quick capture

Friction is what kills a habit tracker. If recording a coffee costs
unlock → find app → wait for launch → find the button, the log stops
after a fortnight and the data is worthless. This is the whole reason
the app is native rather than a web page saved to the home screen.

Two Android surfaces exist for that: a **home-screen widget** and a
**quick-settings tile**. Both talk to Dart over one method channel,
`dev.kuhy.kuhylog/quick_capture`.

## Wire protocol

Everything crossing the channel is primitives, maps and lists, so the
Kotlin side needs no model classes and no code generation.

### Platform to Dart

| Method | Arguments | Answers |
| --- | --- | --- |
| `logTracker` | `{tag: String, value: double?}`, or a bare tag string | the new summary |
| `logNote` | `{note: String}`, or a bare note string | the new summary |
| `summary` | none | the current summary |

Errors are `PlatformException`s the caller is meant to show:

| Code | Meaning |
| --- | --- |
| `unknown-tracker` | the tag is not configured — likely a widget pinned to a deleted tracker |
| `empty-note` | refusing to record whitespace |
| `bad-arguments` | the argument was not a string or a map holding one |

Anything else answers "not implemented" rather than erroring, which is
the platform-channel convention Flutter enforces on a thrown
`MissingPluginException`.

### Dart to platform

| Method | Arguments |
| --- | --- |
| `render` | the summary |

Sent on **every** state change, because a widget showing yesterday's
count is worse than one showing nothing. A missing implementation on
the other side is expected and silently ignored: on a desktop, in a
test, or before a widget is ever placed, nothing is listening.

### The summary

```json
{
  "score": 4,
  "entries": 7,
  "trackers": [
    {
      "tag": "coffee",
      "label": "Coffee",
      "glyph": "☕",
      "color": 4281545974,
      "value": 2.0,
      "display": "2"
    }
  ]
}
```

At most four trackers, taken from the visible ones in configuration
order. `display` is already formatted with the tracker's unit, so the
Kotlin side never formats a number and the two halves cannot disagree
about rounding.

## What is verified and what is not

**Verified.** The entire Dart half — `lib/src/platform/quick_capture.dart`
— at 100% line coverage, driving the channel in both directions with a
mocked binary messenger: every method, every error code, the
not-implemented path, republishing on change, and detaching.

**Not verified, at all.** Every Kotlin file and every XML resource:

- `MainActivity.kt`, `QuickCaptureStore.kt`, `QuickCaptureWidget.kt`,
  `QuickCaptureTile.kt`
- `res/layout/widget_quick_capture.xml`,
  `res/xml/widget_quick_capture_info.xml`
- the `receiver` and `service` blocks in `AndroidManifest.xml`

They have never been compiled. The sandbox this repository was written
in had no Android SDK, so `flutter build apk` was never run. The XML
files were checked to be well-formed and nothing more — that says
nothing about whether the attributes are valid. The `android` job in CI
is the first place any of it is exercised; until that job is green,
assume it is broken.

## The shortcut currently taken

A widget tap does **not** record headlessly. It fires a `PendingIntent`
at `MainActivity` carrying `EXTRA_TRACKER`, and the activity forwards it
to Dart once the engine is attached. So a capture briefly opens the app.

That is a real compromise against the point of this document, and it is
deliberate: the alternative is a background `FlutterEngine` cached in
`FlutterEngineCache` and driven from the `AppWidgetProvider`, which is
considerably more machinery to get wrong in code that nothing here can
test. Doing the simple thing first, visibly, beats shipping the clever
thing unverified.

## Upgrade path to a truly headless capture

1. Register a second Dart entry point annotated `@pragma('vm:entry-point')`
   that opens the `FileStore` and attaches a `QuickCapture` without any
   widget tree.
2. From `QuickCaptureWidget.onReceive`, start or reuse a cached
   `FlutterEngine` running that entry point and invoke `logTracker` on
   it.
3. Keep `MainActivity`'s intent forwarding as the fallback for when the
   engine cannot start.
4. Add an instrumentation test — the Dart side is already covered, so
   what needs proving is the Android lifecycle, which unit tests cannot
   reach.

Step 1 is the only part testable in Dart, and it should be written
test-first like everything else in `lib/`.
