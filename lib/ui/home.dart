import 'package:flutter/material.dart';

import 'albums_tab.dart';
import 'apps_tab.dart';
import 'cleanup_tab.dart';
import 'scope.dart';
import 'timeline_tab.dart';
import 'welcome_page.dart';

/// Shows the welcome screen until we have photo access, then the main tabs.
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with WidgetsBindingObserver {
  int _tab = 0;

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
    // Pick up new screenshots (and permission changes made in Settings).
    if (state == AppLifecycleState.resumed) {
      LibraryScope.read(context).checkPermission(ask: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    if (lib.permission == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!lib.hasAccess) return const WelcomePage();

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [TimelineTab(), AppsTab(), AlbumsTab(), CleanupTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: 'Timeline'),
          NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps),
              label: 'Apps'),
          NavigationDestination(
              icon: Icon(Icons.photo_album_outlined),
              selectedIcon: Icon(Icons.photo_album),
              label: 'Albums'),
          NavigationDestination(
              icon: Icon(Icons.cleaning_services_outlined),
              selectedIcon: Icon(Icons.cleaning_services),
              label: 'Clean up'),
        ],
      ),
    );
  }
}
