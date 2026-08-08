import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/ui/theme.dart';

/// One row of the timeline.
class EntryTile extends StatelessWidget {
  /// Creates a tile for [entry].
  const EntryTile({
    required this.entry,
    required this.score,
    required this.onDelete,
    super.key,
  });

  /// The entry being shown.
  final LogEntry entry;

  /// The entry's score, used for the leading colour.
  final int score;

  /// Called when the delete button is pressed.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minute = entry.end.minute.toString().padLeft(2, '0');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: KuhylogTheme.scoreColor(
          scheme,
          score,
        ).withValues(alpha: 0.18),
        child: Text(
          '${entry.end.hour}:$minute',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      title: Text(entry.note),
      subtitle: entry.text.isEmpty ? null : Text(entry.text),
      trailing: IconButton(
        key: Key('entry-delete-${entry.id}'),
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
