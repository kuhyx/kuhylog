import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/ui/app_scope.dart';

import 'harness.dart';

void main() {
  testWidgets('exposes the state and rebuilds on change', (tester) async {
    final state = buildState();
    var builds = 0;
    await pumpScoped(
      tester,
      state,
      Builder(
        builder: (context) {
          builds++;
          return Text('${AppScope.of(context).trackers.length}');
        },
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(builds, 1);

    state.record('#a');
    await tester.pump();
    expect(builds, 2);
  });

  testWidgets('asserts when there is no scope', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(() => AppScope.of(captured), throwsAssertionError);
  });
}
