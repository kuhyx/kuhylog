import 'package:flutter/material.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/ui/app_scope.dart';
import 'package:kuhylog/src/ui/home_page.dart';
import 'package:kuhylog/src/ui/theme.dart';

/// The application widget.
class KuhylogApp extends StatelessWidget {
  /// Creates the application over an existing [state].
  const KuhylogApp({required this.state, super.key});

  /// The shared state handed to the whole tree.
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'kuhylog',
        debugShowCheckedModeBanner: false,
        theme: KuhylogTheme.of(Brightness.light),
        darkTheme: KuhylogTheme.of(Brightness.dark),
        home: const HomePage(),
      ),
    );
  }
}
