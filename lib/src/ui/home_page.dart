import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/capture_sheet.dart';
import 'package:kuhylog/src/ui/data_page.dart';
import 'package:kuhylog/src/ui/stats_view.dart';
import 'package:kuhylog/src/ui/timeline_view.dart';
import 'package:kuhylog/src/ui/track_view.dart';

/// The shell holding the three top level views.
class HomePage extends StatefulWidget {
  /// Creates the shell.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const List<String> _titles = <String>['Track', 'Timeline', 'Stats'];

  Future<void> _capture() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(state: AppScope.of(context)),
    );
  }

  void _openData() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DataPage(state: AppScope.of(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'today ${state.todayScore >= 0 ? '+' : ''}'
                '${state.todayScore}',
                key: const Key('home-today-score'),
              ),
            ),
          ),
          IconButton(
            key: const Key('home-data-button'),
            icon: const Icon(Icons.storage_outlined),
            onPressed: _openData,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[TrackView(), TimelineView(), StatsView()],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('home-capture-button'),
        onPressed: _capture,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
