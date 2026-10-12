import 'package:flutter/material.dart';

import 'data/library.dart';
import 'ui/home.dart';
import 'ui/scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final library = Library()..start();
  runApp(SnapSortApp(library: library));
}

class SnapSortApp extends StatelessWidget {
  const SnapSortApp({super.key, required this.library});
  final Library library;

  static ThemeData theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B5CFF),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LibraryScope(
      library: library,
      child: MaterialApp(
        title: 'SnapSort',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        home: const Root(),
      ),
    );
  }
}
