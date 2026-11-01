import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:kuhylog/src/stats/insight_scan.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/theme.dart';
import 'package:kuhylog/src/ui/widgets/stat_tile.dart';

/// Totals and streaks per tracker, with the correlation scan in a sheet.
class StatsView extends StatefulWidget {
  /// Creates the stats view.
  const StatsView({super.key});

  /// How many days back the summary and the scan look by default.
  static const int windowDays = 90;

  /// The windows the range chips offer.
  static const List<int> ranges = <int>[7, 30, windowDays];

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  int _days = StatsView.windowDays;

  Future<void> _openInsights(DateTime from, DateTime to) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final to = state.now;
    final widest = DateTime(to.year, to.month, to.day - StatsView.windowDays);
    if (state.store.entriesBetween(widest, to).isEmpty) {
      return const Center(child: Text('No data in the last 90 days.'));
    }
    final from = DateTime(to.year, to.month, to.day - _days);
    final entries = state.store.entriesBetween(from, to);
    final split = state.scoring.split(entries);
    final trackers = state.trackers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              for (final days in StatsView.ranges)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    key: Key('stats-range-$days'),
                    label: Text('$days'),
                    selected: days == _days,
                    onSelected: (_) => setState(() => _days = days),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${split.total} entries, '
                  '${(split.positiveShare * 100).round()}% positive',
                  key: const Key('stats-summary'),
                ),
              ),
              IconButton(
                key: const Key('stats-insights-tile'),
                icon: const Icon(
                  Icons.insights_outlined,
                  semanticLabel: 'Insights',
                ),
                onPressed: () => _openInsights(from, to),
              ),
            ],
          ),
        ),
        Expanded(
          child: FitGrid(
            key: ValueKey<int>(_days),
            itemCount: trackers.length,
            columns: 2,
            minSquare: 0.6,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (context, index) => StatTile(
              tracker: trackers[index],
              entries: entries,
              to: to,
            ),
          ),
        ),
      ],
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
