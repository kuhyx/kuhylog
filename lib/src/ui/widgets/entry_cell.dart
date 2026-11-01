import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/log_entry.dart';
import 'package:kuhylog/src/ui/theme.dart';

/// One entry as a compact grid tile; the full detail lives behind a tap.
class EntryCell extends StatelessWidget {
  /// Creates a tile for [entry].
  const EntryCell({
    required this.entry,
    required this.score,
    required this.onTap,
    super.key,
  });

  /// The entry being shown.
  final LogEntry entry;

  /// The entry's score, used for the tint.
  final int score;

  /// Called on a tap, which opens the entry's detail sheet.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final minute = entry.end.minute.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: KuhylogTheme.scoreColor(
            scheme,
            score,
          ).withValues(alpha: 0.12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${entry.end.hour}:$minute', style: text.labelMedium),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                entry.note,
                overflow: TextOverflow.fade,
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
