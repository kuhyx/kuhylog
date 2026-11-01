import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';
import 'package:kuhylog/src/stats/streaks.dart';

/// One tracker's total and streak over the stats window.
class StatTile extends StatelessWidget {
  /// Creates a tile for [tracker] over [entries] up to [to].
  const StatTile({
    required this.tracker,
    required this.entries,
    required this.to,
    super.key,
  });

  /// The tracker summarised.
  final Tracker tracker;

  /// Entries inside the window.
  final List<LogEntry> entries;

  /// The last day of the window, where the streak is counted back from.
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final byDay = Aggregate.byDay(tracker, entries);
    final streak = Streaks.of(tracker, entries, to);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(tracker.color).withValues(alpha: 0.12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${tracker.glyph} ${tracker.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${tracker.uom.format(Aggregate.total(byDay))} total',
            key: Key('stats-total-${tracker.tag}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium,
          ),
          Text(
            '${streak.current}/${streak.longest}',
            key: Key('stats-streak-${tracker.tag}'),
            style: text.labelLarge?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
