import 'package:kuhylog/src/model/trackable_ref.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/parse/value_parser.dart';

/// Parses the plain-text note that is the only stored form of an entry.
///
/// Everything structured about an entry lives in its note, which means
/// there is exactly one source of truth and no schema migration when a
/// tracker is renamed. The grammar is:
///
/// ```text
/// #tracker  #tracker(7.5)  #tracker(1:30)  #tracker(3*2)
/// @person   +context       +context(30)    ^pointer      /place
/// ```
///
/// Identifiers accept any Unicode letter or digit plus `_` and `-`, so
/// `#kawa`, `#ćwiczenia` and `#deep-work` all parse.
abstract final class NoteTokenizer {
  /// The pattern every trackable mention must match.
  static final RegExp pattern = RegExp(
    r'(^|[\s(\[{)\],;"])([#@+^/])([\p{L}\p{N}][\p{L}\p{N}_-]*)'
    r'(\(([^)]*)\))?',
    unicode: true,
  );

  /// Returns every trackable mention in [note], in order of appearance.
  ///
  /// Duplicates are preserved: `#coffee #coffee` yields two references,
  /// which is what makes a bare tally add up.
  static List<TrackableRef> parse(String note) {
    final refs = <TrackableRef>[];
    for (final match in pattern.allMatches(note)) {
      final sigil = match.group(2)!;
      final type = TrackableType.fromSigil(sigil);
      if (type == null) {
        continue;
      }
      final id = match.group(3)!.toLowerCase();
      final rawValue = match.group(5) ?? '';
      final raw = note.substring(
        match.start + match.group(1)!.length,
        match.end,
      );
      refs.add(
        TrackableRef(
          type: type,
          id: id,
          raw: raw,
          rawValue: rawValue,
          value: rawValue.isEmpty ? null : ValueParser.parse(rawValue),
        ),
      );
    }
    return refs;
  }

  /// Returns only the references of the given [type].
  static List<TrackableRef> parseOfType(String note, TrackableType type) {
    final result = <TrackableRef>[];
    for (final ref in parse(note)) {
      if (ref.type == type) {
        result.add(ref);
      }
    }
    return result;
  }

  /// Returns the tracker values in [note], keyed by tag.
  ///
  /// A tag mentioned without a value contributes [fallback]. Repeated
  /// mentions of the same tag are added together, so `#water(1) #water`
  /// with a fallback of one yields two.
  static Map<String, double> trackerValues(
    String note, {
    double fallback = 1,
  }) {
    final values = <String, double>{};
    for (final ref in parse(note)) {
      if (ref.type != TrackableType.tracker) {
        continue;
      }
      final amount = ref.value ?? fallback;
      values[ref.id] = (values[ref.id] ?? 0) + amount;
    }
    return values;
  }

  /// Returns [note] with every trackable mention removed.
  ///
  /// Used to show the human sentence without the machinery.
  static String stripTags(String note) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in pattern.allMatches(note)) {
      final tagStart = match.start + match.group(1)!.length;
      buffer.write(note.substring(cursor, tagStart));
      cursor = match.end;
    }
    buffer.write(note.substring(cursor));
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Renames every mention of [from] to [to] inside [note].
  ///
  /// Only mentions of [type] are touched, so renaming the tracker
  /// `#work` leaves the context `+work` alone.
  static String rename(
    String note,
    TrackableType type,
    String from,
    String to,
  ) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in pattern.allMatches(note)) {
      final sigil = match.group(2)!;
      final id = match.group(3)!.toLowerCase();
      if (TrackableType.fromSigil(sigil) != type || id != from.toLowerCase()) {
        continue;
      }
      final tagStart = match.start + match.group(1)!.length;
      buffer
        ..write(note.substring(cursor, tagStart))
        ..write('${type.sigil}$to')
        ..write(match.group(4) ?? '');
      cursor = match.end;
    }
    buffer.write(note.substring(cursor));
    return buffer.toString();
  }
}
