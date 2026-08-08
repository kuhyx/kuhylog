import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/bootstrap.dart';
import 'package:kuhylog/src/ui/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('kuhylog_boot_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => root.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    root.deleteSync(recursive: true);
  });

  test('resolveStoreDirectory nests under the documents directory', () async {
    final directory = await resolveStoreDirectory();
    expect(directory.path, '${root.path}/kuhylog');
  });

  test('bootstrap seeds an empty store and builds the app', () async {
    Widget? built;
    await bootstrap(run: (app) => built = app);
    expect(built, isA<KuhylogApp>());
    expect(Directory('${root.path}/kuhylog').existsSync(), isTrue);
    expect((built! as KuhylogApp).state.trackers, isNotEmpty);
  });

  test('bootstrap accepts an injected directory', () async {
    final directory = Directory('${root.path}/custom');
    Widget? built;
    await bootstrap(
      resolve: () async => directory,
      run: (app) => built = app,
    );
    expect(built, isNotNull);
    expect(directory.existsSync(), isTrue);
  });
}
