import 'package:flutter/material.dart';

import '../onboarding/onboarding_screen.dart';
import '../scope.dart';
import '../widgets/nav.dart';
import 'albums_screen.dart';
import 'apps_screen.dart';
import 'cleanup_screen.dart';
import 'timeline_screen.dart';

/// Onboarding until we have photo access, then the tabs.
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up new screenshots, and permission changes made in Settings.
    if (state == AppLifecycleState.resumed) {
      LibraryScope.read(context).checkPermission(ask: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: lib.permission == null
          ? const Scaffold(key: ValueKey('loading'))
          : lib.hasAccess
              ? const Shell(key: ValueKey('shell'))
              : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}

const _destinations = [
  NavDestination(Icons.photo_library_outlined, Icons.photo_library_rounded, 'Timeline'),
  NavDestination(Icons.apps_outlined, Icons.apps_rounded, 'Apps'),
  NavDestination(Icons.photo_album_outlined, Icons.photo_album_rounded, 'Albums'),
  NavDestination(Icons.cleaning_services_outlined, Icons.cleaning_services_rounded, 'Clean up'),
];

/// The four tabs with a floating pill nav over them.
class Shell extends StatefulWidget {
  const Shell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _tab = widget.initialTab;
  final _navHidden = ValueNotifier(false);

  @override
  void dispose() {
    _navHidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ShellScope(
      navHidden: _navHidden,
      child: Scaffold(
        body: Stack(children: [
          IndexedStack(
            index: _tab,
            children: const [TimelineScreen(), AppsScreen(), AlbumsScreen(), CleanupScreen()],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 18,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navHidden,
              builder: (context, hidden, child) => IgnorePointer(
                ignoring: hidden,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  offset: hidden ? const Offset(0, 2) : Offset.zero,
                  child: child,
                ),
              ),
              child: Center(
                child: FloatingNav(
                  destinations: _destinations,
                  selected: _tab,
                  onSelect: (i) => setState(() => _tab = i),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
