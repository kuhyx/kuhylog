import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/tracker.dart';

/// The tappable tile representing one tracker on the track screen.
class TrackerButton extends StatelessWidget {
  /// Creates a tracker button.
  const TrackerButton({
    required this.tracker,
    required this.onTap,
    required this.onLongPress,
    this.todayValue,
    super.key,
  });

  /// The tracker this button records.
  final Tracker tracker;

  /// Called on a tap, which records the tracker.
  final VoidCallback onTap;

  /// Called on a long press, which opens the tracker's settings.
  final VoidCallback onLongPress;

  /// Today's aggregated value, or `null` when nothing was recorded.
  final double? todayValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = todayValue;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color(tracker.color).withValues(alpha: 0.12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(tracker.glyph, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              tracker.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (value != null)
              Text(
                tracker.uom.format(value),
                key: const Key('tracker-button-value'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
