import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/main.dart' as app;
import 'package:kuhylog/src/ui/app.dart';

/// Isolated because `main` calls `runApp`, which attaches a root widget
/// to the binding for the rest of the file. Any other test sharing this
/// file would inherit that tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main starts the application', (tester) async {
    final root = Directory.systemTemp.createTempSync('kuhylog_main_');
    addTearDown(() => root.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => root.path,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          ),
    );

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(KuhylogApp), findsOneWidget);
  });
}
