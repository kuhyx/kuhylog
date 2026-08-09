import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/model/json_read.dart';
import 'package:kuhylog/src/model/uom.dart';

/// How a tracker collects its value.
enum TrackerType {
  /// One tap records [Tracker.defaultValue]. No input surface.
  tally,

  /// A free numeric entry.
  value,

  /// A bounded slider between [Tracker.min] and [Tracker.max].
  range,

  /// A duration entry; the recorded value is a duration in seconds.
  ///
  /// Entered as a number or as `h:mm:ss`, not run as a live stopwatch.
  timer,

  /// A choice from [Tracker.options]; the value is the chosen index.
  picker;

  /// Maps a Nomie tracker type name onto this enum.
  ///
  /// Unknown names degrade to [TrackerType.tally] rather than throwing,
  /// because an unimportable tracker is worse than an approximate one.
  static TrackerType parse(String value) {
    switch (value) {
      case 'tick':
      case 'tally':
        return TrackerType.tally;
      case 'value':
      case 'numeric':
        return TrackerType.value;
      case 'range':
      case 'slider':
        return TrackerType.range;
      case 'timer':
        return TrackerType.timer;
      case 'picker':
      case 'pick':
        return TrackerType.picker;
      default:
        return TrackerType.tally;
    }
  }
}

/// How repeated values of a tracker combine over a period.
enum TrackerMath {
  /// Values are added together.
  sum,

  /// Values are averaged.
  mean;

  /// Maps a stored math name onto this enum, defaulting to [sum].
  static TrackerMath parse(String value) {
    switch (value) {
      case 'mean':
      case 'avg':
      case 'average':
        return TrackerMath.mean;
      default:
        return TrackerMath.sum;
    }
  }
}

/// A user defined thing to track.
///
/// A tracker is configuration only; the values live in log entries and
/// are recovered by parsing their notes.
@immutable
class Tracker {
  /// Creates a tracker.
  const Tracker({
    required this.tag,
    required this.label,
    this.emoji = '',
    this.color = 0xFF3B82F6,
    this.type = TrackerType.tally,
    this.uom = Uom.count,
    this.min = 0,
    this.max = 10,
    this.step = 1,
    this.defaultValue = 1,
    this.math = TrackerMath.sum,
    this.positivity = 0,
    this.hidden = false,
    this.ignoreZero = false,
    this.options = const <String>[],
    this.alsoInclude = '',
  });

  /// Builds a tracker from decoded JSON, tolerating Nomie field names.
  factory Tracker.fromJson(Map<String, dynamic> json) {
    final rawTag = JsonRead.string(json, 'tag');
    final rawId = JsonRead.string(json, '_id');
    final label = JsonRead.string(json, 'label');
    final tag = Tracker.slug(
      rawTag.isNotEmpty ? rawTag : (rawId.isNotEmpty ? rawId : label),
    );
    return Tracker(
      tag: tag,
      label: label.isNotEmpty ? label : tag,
      emoji: JsonRead.string(json, 'emoji'),
      color: _parseColor(JsonRead.string(json, 'color')),
      type: TrackerType.parse(JsonRead.string(json, 'type')),
      uom: Uom.parse(JsonRead.string(json, 'uom')),
      min: JsonRead.number(json, 'min'),
      max: JsonRead.number(json, 'max', fallback: 10),
      step: JsonRead.number(json, 'step', fallback: 1),
      defaultValue: JsonRead.number(json, 'default', fallback: 1),
      math: TrackerMath.parse(JsonRead.string(json, 'math')),
      positivity: JsonRead.number(json, 'score').round(),
      hidden: JsonRead.boolean(json, 'hidden'),
      ignoreZero: JsonRead.boolean(json, 'ignore_zero'),
      options: JsonRead.stringList(json, 'picks'),
      alsoInclude: JsonRead.string(json, 'include'),
    );
  }

  /// The tag used in notes, without the leading `#`.
  final String tag;

  /// Human readable name.
  final String label;

  /// A short emoji shown on the tracker button.
  final String emoji;

  /// ARGB colour value of the tracker button.
  final int color;

  /// How the tracker collects its value.
  final TrackerType type;

  /// The unit values are recorded in.
  final Uom uom;

  /// Lower bound for [TrackerType.range].
  final double min;

  /// Upper bound for [TrackerType.range].
  final double max;

  /// Slider increment for [TrackerType.range].
  final double step;

  /// Value recorded when a note mentions the tag with no explicit value.
  final double defaultValue;

  /// How repeated values combine over a period.
  final TrackerMath math;

  /// How good or bad an occurrence is, from -5 to 5.
  final int positivity;

  /// Whether the tracker is hidden from boards.
  final bool hidden;

  /// Whether zero values are excluded from aggregates.
  final bool ignoreZero;

  /// Choices for [TrackerType.picker].
  final List<String> options;

  /// Extra note text appended whenever this tracker is recorded.
  final String alsoInclude;

  /// The tag as it appears in a note, including the sigil.
  String get hashtag => '#$tag';

  /// The emoji if set, otherwise the first character of the label.
  String get glyph {
    if (emoji.isNotEmpty) {
      return emoji;
    }
    return label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '#';
  }

  /// Normalises arbitrary text into a legal tag.
  ///
  /// Letters and digits survive (including Polish diacritics), runs of
  /// anything else collapse to a single underscore, and the result is
  /// lower cased.
  static String slug(String input) {
    final lowered = input.trim().toLowerCase();
    final cleaned = lowered.replaceAll(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
      '_',
    );
    final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed;
  }

  static int _parseColor(String value) {
    if (value.startsWith('#') && (value.length == 7 || value.length == 4)) {
      final body = value.length == 4
          ? value.substring(1).split('').map((c) => '$c$c').join()
          : value.substring(1);
      final parsed = int.tryParse(body, radix: 16);
      if (parsed != null) {
        return 0xFF000000 | parsed;
      }
    }
    return 0xFF3B82F6;
  }

  /// Returns a copy of this tracker with the given fields replaced.
  Tracker copyWith({
    String? tag,
    String? label,
    String? emoji,
    int? color,
    TrackerType? type,
    Uom? uom,
    double? min,
    double? max,
    double? step,
    double? defaultValue,
    TrackerMath? math,
    int? positivity,
    bool? hidden,
    bool? ignoreZero,
    List<String>? options,
    String? alsoInclude,
  }) {
    return Tracker(
      tag: tag ?? this.tag,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      type: type ?? this.type,
      uom: uom ?? this.uom,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      defaultValue: defaultValue ?? this.defaultValue,
      math: math ?? this.math,
      positivity: positivity ?? this.positivity,
      hidden: hidden ?? this.hidden,
      ignoreZero: ignoreZero ?? this.ignoreZero,
      options: options ?? this.options,
      alsoInclude: alsoInclude ?? this.alsoInclude,
    );
  }

  /// Serialises the tracker using the field names it is read back with.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tag': tag,
      'label': label,
      'emoji': emoji,
      'color': '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      'type': type.name,
      'uom': uom.name,
      'min': min,
      'max': max,
      'step': step,
      'default': defaultValue,
      'math': math.name,
      'score': positivity,
      'hidden': hidden,
      'ignore_zero': ignoreZero,
      'picks': options,
      'include': alsoInclude,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Tracker && listEquals(_identity, other._identity);

  List<Object?> get _identity => <Object?>[
    tag,
    label,
    emoji,
    color,
    type,
    uom,
    min,
    max,
    step,
    defaultValue,
    math,
    positivity,
    hidden,
    ignoreZero,
    options.join('\u0000'),
    alsoInclude,
  ];

  @override
  int get hashCode => Object.hash(tag, label, type);

  @override
  String toString() => 'Tracker($hashtag)';
}
