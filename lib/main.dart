import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import 'app/prefs.dart';
import 'data/demo.dart';
import 'data/library.dart';
import 'ui/design/theme.dart';
import 'ui/scope.dart';
import 'ui/screens/shell.dart';

/// `flutter run --dart-define=DEMO=true` fills the app with sample screenshots.
const demoMode = bool.fromEnvironment('DEMO');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = Prefs()..load();
  final library = demoMode
      ? Library(
          channel: DemoMediaChannel(),
          permission: ({required bool ask}) async => PermissionState.authorized,
        )
      : Library();
  library.start();
  runApp(SnapSortApp(library: library, prefs: prefs));
}

class SnapSortApp extends StatelessWidget {
  const SnapSortApp({super.key, required this.library, required this.prefs, this.home});

  final Library library;
  final Prefs prefs;

  /// Overrides the root screen (used by screenshot tests).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return PrefsScope(
      prefs: prefs,
      child: LibraryScope(
        library: library,
        child: ListenableBuilder(
          listenable: prefs,
          builder: (context, _) => MaterialApp(
            title: 'SnapSort',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: prefs.themeMode,
            scrollBehavior: const AppScrollBehavior(),
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: child!,
              );
            },
            home: home ?? const Root(),
          ),
        ),
      ),
    );
  }
}
