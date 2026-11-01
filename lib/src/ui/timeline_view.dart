import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/widgets/entry_cell.dart';
import 'package:kuhylog/src/ui/widgets/entry_tile.dart';

/// One day of entries at a time, newest day first, with a search box.
///
/// A day strip picks the day and the entries of that day fill a paged grid,
/// so the screen never scrolls vertically. A tap on a tile opens the full
/// note and the delete action.
class TimelineView extends StatefulWidget {
  /// Creates the timeline view.
  const TimelineView({super.key});

  /// Formats a day as `YYYY-MM-DD`, which sorts and never ambiguates.
  static String formatDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  DateTime? _day;

  Future<void> _open(AppState state, LogEntry entry) {
    final score = state.scoring.scoreOf(entry);
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: EntryTile(
          entry: entry,
          score: score,
          onDelete: () {
            Navigator.of(sheet).pop();
            state.deleteEntry(entry.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final entries = state.timeline;
    // Newest first, so insertion order of the set is newest day first.
    final days = <DateTime>{for (final entry in entries) entry.day}.toList();
    final day = days.contains(_day) ? _day : (days.isEmpty ? null : days.first);
    final shown = <LogEntry>[
      for (final entry in entries)
        if (entry.day == day) entry,
    ];
    final scorer = state.scoring;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            key: const Key('timeline-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search notes',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: state.search,
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              for (var i = 0; i < days.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    key: Key('timeline-day-$i'),
                    label: Text(TimelineView.formatDay(days[i])),
                    selected: days[i] == day,
                    onSelected: (_) => setState(() => _day = days[i]),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Nothing recorded yet.'))
              : FitGrid(
                  key: ValueKey<DateTime?>(day),
                  itemCount: shown.length,
                  minSquare: 0.8,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (context, index) {
                    final entry = shown[index];
                    return EntryCell(
                      key: Key('entry-cell-${entry.id}'),
                      entry: entry,
                      score: scorer.scoreOf(entry),
                      onTap: () => _open(state, entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
