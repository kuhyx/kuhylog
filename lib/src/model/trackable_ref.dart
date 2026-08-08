import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/model/trackable_type.dart';

/// One trackable mention found inside a note.
///
/// A reference is the parsed form of `#sleep(7.5)`, `@ola`, `+work` and
/// friends. It records where it came from so a note can be rewritten
/// without re-serialising the whole string.
@immutable
class TrackableRef {
  /// Creates a reference.
  const TrackableRef({
    required this.type,
    required this.id,
    required this.raw,
    this.value,
    this.rawValue = '',
  });

  /// What kind of thing is referenced.
  final TrackableType type;

  /// The identifier, lower cased and without the sigil.
  final String id;

  /// The exact source text this reference was parsed from.
  final String raw;

  /// The parsed numeric value, or `null` when none was written.
  final double? value;

  /// The text inside the parentheses, empty when there was none.
  final String rawValue;

  /// The reference as written, including the sigil but not the value.
  String get tag => '${type.sigil}$id';

  /// Whether an explicit value was written for this reference.
  bool get hasValue => value != null;

  @override
  bool operator ==(Object other) =>
      other is TrackableRef &&
      other.type == type &&
      other.id == id &&
      other.raw == raw &&
      other.value == value &&
      other.rawValue == rawValue;

  @override
  int get hashCode => Object.hash(type, id, raw, value, rawValue);

  @override
  String toString() => hasValue ? '$tag($value)' : tag;
}
