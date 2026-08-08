import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:kuhylog/src/platform/quick_capture.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/store/file_store.dart';
import 'package:kuhylog/src/ui/app.dart';
import 'package:path_provider/path_provider.dart';

/// Where the store lives on a real device.
Future<Directory> resolveStoreDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  return Directory('${base.path}/kuhylog');
}

/// Wires the store, the state, the quick-capture bridge and the widget
/// tree together.
///
/// Both collaborators are injectable so the whole start-up path can be
/// exercised in a test without a plugin or a real window.
Future<void> bootstrap({
  Future<Directory> Function() resolve = resolveStoreDirectory,
  void Function(Widget app) run = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await resolve();
  final state = AppState(FileStore(directory))..seedDefaults();
  QuickCapture(state).attach();
  run(KuhylogApp(state: state));
}
