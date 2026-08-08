import 'package:flutter/foundation.dart';
import 'package:kuhylog/src/model/json_read.dart';

/// A named group of tracker tags shown as one tab on the track screen.
@immutable
class Board {
  /// Creates a board.
  const Board({
    required this.id,
    required this.label,
    this.trackerTags = const <String>[],
  });

  /// Builds a board from decoded JSON.
  factory Board.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json, 'id');
    final label = JsonRead.string(json, 'label');
    return Board(
      id: id.isNotEmpty ? id : label.toLowerCase(),
      label: label.isNotEmpty ? label : id,
      trackerTags: JsonRead.stringList(json, 'trackers'),
    );
  }

  /// The board every tracker implicitly belongs to.
  static const Board all = Board(id: 'all', label: 'All');

  /// Stable identifier.
  final String id;

  /// Human readable name shown on the tab.
  final String label;

  /// Tags of the trackers on this board, in display order.
  final List<String> trackerTags;

  /// Whether this is the implicit all-trackers board.
  bool get isAll => id == Board.all.id;

  /// Returns a copy with the given fields replaced.
  Board copyWith({String? id, String? label, List<String>? trackerTags}) {
    return Board(
      id: id ?? this.id,
      label: label ?? this.label,
      trackerTags: trackerTags ?? this.trackerTags,
    );
  }

  /// Serialises the board.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'trackers': trackerTags,
  };

  @override
  bool operator ==(Object other) =>
      other is Board &&
      other.id == id &&
      other.label == label &&
      listEquals(other.trackerTags, trackerTags);

  @override
  int get hashCode => Object.hash(id, label, trackerTags.length);

  @override
  String toString() => 'Board($id)';
}
