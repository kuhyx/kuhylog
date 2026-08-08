import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/widgets/entry_tile.dart';

/// Every entry, newest first, with a search box.
class TimelineView extends StatelessWidget {
  /// Creates the timeline view.
  const TimelineView({super.key});

  /// Formats a day as `YYYY-MM-DD`, which sorts and never ambiguates.
  static String formatDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final entries = state.timeline;
    final scorer = state.scoring;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const Key('timeline-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search notes',
              border: OutlineInputBorder(),
            ),
            onChanged: state.search,
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Nothing recorded yet.'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final previous = index == 0 ? null : entries[index - 1];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (previous == null || previous.day != entry.day)
                          _dayHeader(context, entry),
                        EntryTile(
                          entry: entry,
                          score: scorer.scoreOf(entry),
                          onDelete: () => state.deleteEntry(entry.id),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _dayHeader(BuildContext context, LogEntry entry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        formatDay(entry.day),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
