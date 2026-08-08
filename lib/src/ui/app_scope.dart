import 'package:flutter/widgets.dart';
import 'package:kuhylog/src/state/app_state.dart';

/// Makes the [AppState] available to the widget tree below it.
///
/// An inherited notifier rather than a package: the app has exactly one
/// piece of shared state, and a dependency would be more code than this.
class AppScope extends InheritedNotifier<AppState> {
  /// Wraps [child] in a scope backed by [state].
  const AppScope({
    required AppState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  /// Returns the state, subscribing the calling widget to changes.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree');
    return scope!.notifier!;
  }
}
