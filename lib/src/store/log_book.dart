/// Helpers for the month-sized buckets logs are stored in.
///
/// Keeping one file per month bounds how much has to be read and
/// rewritten for a single entry, which matters on a phone where the
/// whole store is loaded synchronously.
abstract final class LogBook {
  /// Returns the book key a moment belongs to, `YYYY-MM`.
  static String keyFor(DateTime moment) {
    final month = moment.month.toString().padLeft(2, '0');
    return '${moment.year}-$month';
  }

  /// Returns the first instant covered by [key].
  ///
  /// Throws a [FormatException] when [key] is not `YYYY-MM`.
  static DateTime startOf(String key) {
    final parts = key.split('-');
    if (parts.length != 2) {
      throw FormatException('Not a book key', key);
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      throw FormatException('Not a book key', key);
    }
    return DateTime(year, month);
  }

  /// Returns every book key between [from] and [to] inclusive.
  static List<String> keysBetween(DateTime from, DateTime to) {
    if (to.isBefore(from)) {
      return <String>[];
    }
    final keys = <String>[];
    var cursor = DateTime(from.year, from.month);
    final last = DateTime(to.year, to.month);
    while (!cursor.isAfter(last)) {
      keys.add(keyFor(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return keys;
  }
}
