import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/model/json_read.dart';
import 'package:kuhylog/src/model/trackable_ref.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';

/// One recorded moment.
///
/// The note is the payload: trackers, people, context and places are all
/// written into it and recovered by [NoteTokenizer]. Everything else is
/// metadata about when and where the moment happened.
@immutable
class LogEntry {
  /// Creates a log entry.
  const LogEntry({
    required this.id,
    required this.end,
    required this.note,
    this.start,
    this.latitude,
    this.longitude,
    this.location = '',
    this.source = 'kuhylog',
  });

  /// Builds an entry from decoded JSON, tolerating Nomie field names.
  ///
  /// Nomie stores the moment in `end` and exposes it as `date` through
  /// its API, so both are accepted, as are epoch milliseconds.
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.firstKey(json, <String>['end', 'date', 'created']);
    return LogEntry(
      id: JsonRead.string(json, '_id', fallback: JsonRead.string(json, 'id')),
      end: key == null
          ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
          : parseMoment(json[key]),
      start: json.containsKey('start') ? parseMoment(json['start']) : null,
      note: JsonRead.string(json, 'note'),
      latitude: JsonRead.maybeNumber(json, 'lat'),
      longitude: JsonRead.maybeNumber(json, 'lng'),
      location: JsonRead.string(json, 'location'),
      source: JsonRead.string(json, 'source', fallback: 'import'),
    );
  }

  /// Stable identifier, `<epoch-millis>-<6 hex>` as Nomie wrote them.
  final String id;

  /// When the moment happened, or ended for a timed entry.
  final DateTime end;

  /// When a timed entry started, `null` for instantaneous entries.
  final DateTime? start;

  /// The note text, carrying every trackable mention.
  final String note;

  /// Latitude in degrees, `null` when not recorded.
  final double? latitude;

  /// Longitude in degrees, `null` when not recorded.
  final double? longitude;

  /// A human readable place name.
  final String location;

  /// Which application wrote this entry.
  final String source;

  /// Every trackable mention in [note].
  List<TrackableRef> get refs => NoteTokenizer.parse(note);

  /// Tracker tags mentioned in [note], without duplicates.
  Set<String> get trackerTags => _idsOf(TrackableType.tracker);

  /// People mentioned in [note].
  Set<String> get people => _idsOf(TrackableType.person);

  /// Context tags mentioned in [note].
  Set<String> get contexts => _idsOf(TrackableType.context);

  /// The calendar day this entry belongs to, at local midnight.
  DateTime get day => DateTime(end.year, end.month, end.day);

  /// The duration of a timed entry, `null` when it is instantaneous.
  Duration? get duration {
    final from = start;
    return from == null ? null : end.difference(from);
  }

  /// The note with every trackable mention removed.
  String get text => NoteTokenizer.stripTags(note);

  Set<String> _idsOf(TrackableType type) {
    final ids = <String>{};
    for (final ref in refs) {
      if (ref.type == type) {
        ids.add(ref.id);
      }
    }
    return ids;
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields are replaced only when a value is supplied, so this
  /// cannot clear a location; delete and re-add the entry instead.
  LogEntry copyWith({
    String? id,
    DateTime? end,
    DateTime? start,
    String? note,
    double? latitude,
    double? longitude,
    String? location,
    String? source,
  }) {
    return LogEntry(
      id: id ?? this.id,
      end: end ?? this.end,
      start: start ?? this.start,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      source: source ?? this.source,
    );
  }

  /// Serialises the entry.
  Map<String, dynamic> toJson() => <String, dynamic>{
    '_id': id,
    'end': end.toIso8601String(),
    if (start != null) 'start': start!.toIso8601String(),
    'note': note,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    'location': location,
    'source': source,
  };

  /// Parses a moment written as ISO 8601 text or epoch milliseconds.
  ///
  /// Unparseable input becomes the epoch rather than throwing, so one
  /// corrupt row cannot abort an import of thousands.
  static DateTime parseMoment(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
      final epoch = int.tryParse(value);
      if (epoch != null) {
        return DateTime.fromMillisecondsSinceEpoch(epoch);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Generates an identifier for a moment.
  ///
  /// [random] is injectable so tests get a deterministic identifier.
  static String generateId(DateTime moment, Random random) {
    final suffix = random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${moment.millisecondsSinceEpoch}-$suffix';
  }

  @override
  bool operator ==(Object other) =>
      other is LogEntry &&
      other.id == id &&
      other.end == end &&
      other.start == start &&
      other.note == note &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.location == location &&
      other.source == source;

  @override
  int get hashCode => Object.hash(id, end, note);

  @override
  String toString() => 'LogEntry($id, $note)';
}
