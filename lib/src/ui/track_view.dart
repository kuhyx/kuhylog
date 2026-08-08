import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/board.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/tracker_editor_page.dart';
import 'package:kuhylog/src/ui/widgets/tracker_button.dart';
import 'package:kuhylog/src/ui/widgets/value_dialog.dart';

/// The board of tracker buttons: the fastest way to record something.
class TrackView extends StatelessWidget {
  /// Creates the track view.
  const TrackView({super.key});

  Future<void> _record(BuildContext context, Tracker tracker) async {
    final state = AppScope.of(context);
    if (tracker.type == TrackerType.tally) {
      state.recordTracker(tracker);
      return;
    }
    final value = await showDialog<double>(
      context: context,
      builder: (_) => ValueDialog(tracker: tracker),
    );
    if (value != null) {
      state.recordTracker(tracker, value: value);
    }
  }

  void _edit(BuildContext context, Tracker? tracker) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TrackerEditorPage(
            state: AppScope.of(context),
            tracker: tracker,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trackers = state.boardTrackers;
    final today = state.today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              for (final board in state.boards)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    key: Key('board-chip-${board.id}'),
                    label: Text(board.label),
                    selected: board.id == state.selectedBoardId,
                    onSelected: (_) => state.selectBoard(board.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: trackers.isEmpty
              ? _empty(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      for (final tracker in trackers)
                        TrackerButton(
                          key: Key('tracker-button-${tracker.tag}'),
                          tracker: tracker,
                          todayValue: _todayValue(tracker, today),
                          onTap: () => _record(context, tracker),
                          onLongPress: () => _edit(context, tracker),
                        ),
                      _addButton(context),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  static double? _todayValue(Tracker tracker, List<LogEntry> today) {
    final values = Aggregate.byDay(tracker, today);
    if (values.isEmpty) {
      return null;
    }
    return values.values.first;
  }

  Widget _addButton(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: OutlinedButton(
        key: const Key('tracker-add-button'),
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final state = AppScope.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('No trackers on this board yet.'),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('track-seed-button'),
            onPressed: () {
              state
                ..selectBoard(Board.all.id)
                ..seedDefaults();
            },
            child: const Text('Add starter trackers'),
          ),
          TextButton(
            key: const Key('track-empty-add-button'),
            onPressed: () => _edit(context, null),
            child: const Text('Create one myself'),
          ),
        ],
      ),
    );
  }
}
