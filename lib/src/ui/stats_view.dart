import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/stats/aggregate.dart';
import 'package:kuhylog/src/stats/insight_scan.dart';
import 'package:kuhylog/src/stats/streaks.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/theme.dart';

/// Totals, streaks and the correlation scan.
class StatsView extends StatelessWidget {
  /// Creates the stats view.
  const StatsView({super.key});

  /// How many days back the summary and the scan look.
  static const int windowDays = 90;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final to = state.now;
    final from = DateTime(to.year, to.month, to.day - windowDays);
    final entries = state.store.entriesBetween(from, to);
    final split = state.scoring.split(entries);
    final trackers = state.trackers;
    if (entries.isEmpty) {
      return const Center(child: Text('No data in the last 90 days.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Last $windowDays days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${split.total} entries, '
          '${(split.positiveShare * 100).round()}% positive',
          key: const Key('stats-summary'),
        ),
        const SizedBox(height: 16),
        for (final tracker in trackers) _trackerRow(context, tracker, from, to),
        const SizedBox(height: 16),
        Text(
          'Possible relationships',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Ranked by strength and corrected for the number of pairs '
          'tested. Treat anything here as a hypothesis to test, not a '
          'finding: daily self-tracking is autocorrelated, which makes '
          'these look more certain than they are.',
        ),
        const SizedBox(height: 8),
        ..._insights(context, from, to),
      ],
    );
  }

  Widget _trackerRow(
    BuildContext context,
    Tracker tracker,
    DateTime from,
    DateTime to,
  ) {
    final state = AppScope.of(context);
    final entries = state.store.entriesBetween(from, to);
    final byDay = Aggregate.byDay(tracker, entries);
    final streak = Streaks.of(tracker, entries, to);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(width: 32, child: Text(tracker.glyph)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tracker.label),
                Text(
                  '${tracker.uom.format(Aggregate.total(byDay))} total  ',
                  key: Key('stats-total-${tracker.tag}'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            '${streak.current}/${streak.longest}',
            key: Key('stats-streak-${tracker.tag}'),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }

  List<Widget> _insights(BuildContext context, DateTime from, DateTime to) {
    final state = AppScope.of(context);
    const scan = InsightScan();
    final insights = scan.run(
      state.trackers,
      state.store.entriesBetween(from, to),
      from,
      to,
    );
    if (insights.isEmpty) {
      return <Widget>[
        const Text(
          key: Key('stats-no-insights'),
          'Not enough overlapping days yet. The scan needs at least '
          'three weeks of data for a pair of trackers.',
        ),
      ];
    }
    final scheme = Theme.of(context).colorScheme;
    return <Widget>[
      for (final insight in insights.take(10))
        ListTile(
          key: Key(
            'insight-${insight.sourceTag}-${insight.targetTag}'
            '-${insight.lagDays}',
          ),
          dense: true,
          leading: Icon(
            insight.isPositive ? Icons.trending_up : Icons.trending_down,
            color: KuhylogTheme.scoreColor(
              scheme,
              insight.isPositive ? 1 : -1,
            ),
          ),
          title: Text(insight.summary),
          subtitle: Text(
            'r=${insight.coefficient.toStringAsFixed(2)} '
            'n=${insight.sampleSize} '
            '${insight.significant ? 'survives correction' : 'noise level'}',
          ),
        ),
    ];
  }
}
