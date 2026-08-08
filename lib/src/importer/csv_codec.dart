/// A minimal RFC 4180 CSV reader and writer.
///
/// Exports from other trackers routinely contain commas, quotes and
/// newlines inside a note, so splitting on commas loses data. This is
/// small enough to own rather than depend on.
abstract final class CsvCodec {
  /// Parses [source] into rows of fields.
  ///
  /// Handles quoted fields, doubled quotes inside them, embedded
  /// newlines, and both `\n` and `\r\n` line endings. A trailing newline
  /// does not produce an empty final row.
  static List<List<String>> decode(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var index = 0;
    var pending = false;
    while (index < source.length) {
      final character = source[index];
      if (quoted) {
        if (character == '"') {
          if (index + 1 < source.length && source[index + 1] == '"') {
            field.write('"');
            index += 2;
            continue;
          }
          quoted = false;
          index++;
          continue;
        }
        field.write(character);
        index++;
        continue;
      }
      if (character == '"') {
        quoted = true;
        pending = true;
        index++;
        continue;
      }
      if (character == ',') {
        row.add(field.toString());
        field.clear();
        pending = true;
        index++;
        continue;
      }
      if (character == '\n' || character == '\r') {
        if (pending || field.isNotEmpty) {
          row.add(field.toString());
          field.clear();
          rows.add(row);
          row = <String>[];
          pending = false;
        }
        index +=
            character == '\r' &&
                index + 1 < source.length &&
                source[index + 1] == '\n'
            ? 2
            : 1;
        continue;
      }
      field.write(character);
      pending = true;
      index++;
    }
    if (pending || field.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  /// Renders [rows] as CSV text with `\n` line endings.
  static String encode(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (i > 0) {
          buffer.write(',');
        }
        buffer.write(escape(row[i]));
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }

  /// Quotes [field] if it contains a comma, quote or line break.
  static String escape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
