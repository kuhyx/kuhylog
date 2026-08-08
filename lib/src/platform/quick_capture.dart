import 'package:flutter/services.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/stats/aggregate.dart';

/// The bridge between the app and Android's zero-friction surfaces.
///
/// A habit tracker lives or dies on how long a capture takes, so the
/// home-screen widget and the quick-settings tile must be able to record
/// something without the app being opened. Both talk to Dart over one
/// method channel:
///
/// * platform to Dart - `logTracker` with a tag, `logNote` with text;
///   both answer with the new day summary so the caller can repaint.
/// * Dart to platform - `render` with the same summary, sent whenever
///   the state changes so a widget on the home screen stays current.
///
/// The Dart half is fully tested. The Android half that answers `render`
/// and originates `logTracker` is **not** - see `doc/quick-capture.md`.
class QuickCapture {
  /// Creates a bridge over [state].
  ///
  /// The channel is injectable so tests can drive both directions.
  QuickCapture(this.state, {this.channel = defaultChannel});

  /// The channel both halves agree on.
  static const MethodChannel defaultChannel = MethodChannel(
    'dev.kuhy.kuhylog/quick_capture',
  );

  /// How many trackers the summary carries.
  static const int summarySize = 4;

  /// The state entries are recorded into.
  final AppState state;

  /// The channel this bridge talks over.
  final MethodChannel channel;

  /// Starts answering platform calls and pushing updates.
  void attach() {
    channel.setMethodCallHandler(handle);
    state.addListener(publish);
  }

  /// Stops answering platform calls and pushing updates.
  void detach() {
    channel.setMethodCallHandler(null);
    state.removeListener(publish);
  }

  /// Handles one call from the platform.
  ///
  /// An unknown tracker tag is an error rather than a silent no-op: a
  /// widget pinned to a tracker the user has since deleted should say
  /// so, not pretend it recorded something.
  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'logTracker':
        final tag = _stringArgument(call, 'tag');
        final tracker = state.store.trackerFor(tag);
        if (tracker == null) {
          throw PlatformException(
            code: 'unknown-tracker',
            message: 'No tracker is configured for #$tag',
          );
        }
        state.recordTracker(tracker, value: _numberArgument(call, 'value'));
        return summary();
      case 'logNote':
        final note = _stringArgument(call, 'note');
        if (state.record(note) == null) {
          throw PlatformException(
            code: 'empty-note',
            message: 'Refusing to record an empty note',
          );
        }
        return summary();
      case 'summary':
        return summary();
      default:
        throw MissingPluginException(
          'kuhylog does not implement ${call.method}',
        );
    }
  }

  /// Pushes the current summary to the platform.
  ///
  /// A missing implementation is expected and ignored: on a desktop, in
  /// a test without a mock, or before the widget is ever added, nothing
  /// is listening and that is not an error.
  Future<void> publish() async {
    try {
      await channel.invokeMethod<void>('render', summary());
    } on MissingPluginException {
      return;
    }
  }

  /// The payload both directions exchange.
  ///
  /// Deliberately primitive-only so the Android side needs no model
  /// classes and no code generation to read it.
  Map<String, Object?> summary() {
    final today = state.today;
    final trackers = <Map<String, Object?>>[];
    for (final tracker in state.visibleTrackers.take(summarySize)) {
      final values = Aggregate.byDay(tracker, today);
      final value = values.isEmpty ? 0.0 : values.values.first;
      trackers.add(<String, Object?>{
        'tag': tracker.tag,
        'label': tracker.label,
        'glyph': tracker.glyph,
        'color': tracker.color,
        'value': value,
        'display': tracker.uom.format(value),
      });
    }
    return <String, Object?>{
      'score': state.todayScore,
      'entries': today.length,
      'trackers': trackers,
    };
  }

  static String _stringArgument(MethodCall call, String name) {
    final arguments = call.arguments;
    if (arguments is Map) {
      final value = arguments[name];
      if (value is String) {
        return value;
      }
    }
    if (arguments is String) {
      return arguments;
    }
    throw PlatformException(
      code: 'bad-arguments',
      message: 'Expected a string "$name" for ${call.method}',
    );
  }

  static double? _numberArgument(MethodCall call, String name) {
    final arguments = call.arguments;
    if (arguments is Map) {
      final value = arguments[name];
      if (value is num) {
        return value.toDouble();
      }
    }
    return null;
  }
}
