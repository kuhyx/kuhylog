/// Defensive readers for decoded JSON maps.
///
/// Backup files come from other people's software, so every read has to
/// survive a missing key, a `null`, or a value of the wrong type without
/// throwing. These helpers centralise that so no call site needs a cast.
abstract final class JsonRead {
  /// Reads [key] as a [String], falling back to [fallback].
  static String string(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return '$value';
    }
    return fallback;
  }

  /// Reads [key] as a [double], falling back to [fallback].
  static double number(
    Map<String, dynamic> json,
    String key, {
    double fallback = 0,
  }) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  /// Reads [key] as a nullable [double], returning `null` when absent.
  static double? maybeNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Reads [key] as a [bool], falling back to [fallback].
  static bool boolean(
    Map<String, dynamic> json,
    String key, {
    bool fallback = false,
  }) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == 'true';
    }
    return fallback;
  }

  /// Reads [key] as a list of strings, skipping entries that are not
  /// strings or numbers.
  static List<String> stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      return <String>[];
    }
    final result = <String>[];
    for (final item in value) {
      if (item is String) {
        result.add(item);
      } else if (item is num) {
        result.add('$item');
      }
    }
    return result;
  }

  /// Reads [key] as a nested JSON object, or an empty map.
  static Map<String, dynamic> object(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  /// Reads [key] as a list of JSON objects, skipping non-objects.
  static List<Map<String, dynamic>> objectList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map) {
        result.add(item.cast<String, dynamic>());
      }
    }
    return result;
  }

  /// Returns the first key of [candidates] present in [json].
  ///
  /// Returns `null` when none of them are present.
  static String? firstKey(
    Map<String, dynamic> json,
    List<String> candidates,
  ) {
    for (final candidate in candidates) {
      if (json.containsKey(candidate)) {
        return candidate;
      }
    }
    return null;
  }
}
