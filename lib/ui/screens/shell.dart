import 'package:flutter/material.dart';

import '../../data/shot.dart';
import '../actions.dart';
import '../design/tokens.dart';
import '../widgets/common.dart';

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
  bool _prompted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lib = LibraryScope.of(context);
    if (_prompted || !lib.loadedOnce || lib.usageAccess || lib.usagePromptShown) return;
    if (lib.unknownCount < 1) return;
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForUsageAccess());
  }

  /// Asked once: the only exact way to know the app when the file name doesn't say.
  Future<void> _askForUsageAccess() async {
    if (!mounted) return;
    final lib = LibraryScope.read(context)..markUsagePromptShown();
    final count = lib.unknownCount;
    final turnOn = await showAppSheet<bool>(context, (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconBadge(Icons.manage_search_rounded, color: Brand.violet, size: 52),
            ]),
            const SizedBox(height: 18),
            SheetHeading(
              title: 'One more',
              accent: 'step.',
              message: "${formatCount(count, 'screenshot')} don't say which app "
                  "${count == 1 ? 'it is' : 'they are'} from. Turn on Usage access and SnapSort "
                  'looks up the app that was open at the exact moment you took each one, '
                  'and keeps doing it for new screenshots. Nothing leaves your phone.',
            ),
            PillButton(
              label: 'Turn on usage access',
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Not now',
              style: PillStyle.soft,
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ));
    if (turnOn == true) await lib.openUsageAccess();
  }

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
