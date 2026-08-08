import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/store/memory_store.dart';
import 'package:kuhylog/src/ui/app_scope.dart';

/// A fixed moment every widget test runs at.
final DateTime testNow = DateTime(2026, 8, 8, 12);

/// Builds a state over an empty in-memory store with a pinned clock.
AppState buildState({MemoryStore? store}) => AppState(
  store ?? MemoryStore(),
  now: () => testNow,
  random: Random(1),
);

/// Pumps [child] inside a scope and a material app.
Future<void> pumpScoped(
  WidgetTester tester,
  AppState state,
  Widget child,
) async {
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(home: child),
    ),
  );
}
