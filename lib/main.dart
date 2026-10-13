import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/prefs.dart';
import 'data/demo.dart';
import 'data/library.dart';
import 'ui/design/theme.dart';
import 'ui/scope.dart';
import 'ui/screens/shell.dart';

/// `flutter run --dart-define=DEMO=true` fills the app with sample screenshots.
const demoMode = bool.fromEnvironment('DEMO');

/// Keeps the first error of a session so the next launch can offer to share it.
Future<void> _remember(Object error, StackTrace? stack) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('lastError') != null) return;
    await prefs.setString(
      'lastError',
      'SnapSort error\n${DateTime.now()}\n\n$error\n\n${stack.toString().split('\n').take(40).join('\n')}',
    );
  } catch (_) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _remember(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _remember(error, stack);
    return true;
  };
  if (kReleaseMode) {
    // A calm note instead of a grey box if one part of a screen fails.
    ErrorWidget.builder = (details) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("Couldn't show this part.",
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8A8690))),
          ),
        );
  }
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
