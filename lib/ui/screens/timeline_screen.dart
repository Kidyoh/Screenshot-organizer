import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/routes.dart';
import '../../data/shot.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/pressable.dart';
import '../widgets/selectable_shots.dart';
import '../widgets/shots.dart';
import 'settings_sheet.dart';
import 'viewer.dart';

/// Every screenshot, newest first: a "Latest" rail, app filters and a
/// sectioned grid.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;
  String? _app;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      _search.clear();
    });
    if (_searching) {
      _searchFocus.requestFocus();
    } else {
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final t = context.tokens;
    final pad = MediaQuery.paddingOf(context);
    var shots = _searching ? lib.search(_search.text) : lib.shots;
    if (_app != null) shots = shots.where((s) => s.app == _app).toList();
    final showRail = !_searching && _app == null && lib.shots.length >= 4;
    final latest = showRail ? lib.shots.take(8).toList() : const <Shot>[];
    final gridShots = shots;

    final header = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Insets.page, pad.top + 10, Insets.page, 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _searching
                ? _SearchField(
                    key: const ValueKey('search'),
                    controller: _search,
                    focus: _searchFocus,
                    onChanged: () => setState(() {}),
                    onClose: _toggleSearch,
                  )
                : Row(
                    key: const ValueKey('buttons'),
                    children: [
                      Expanded(
                        child: Text('snapsort',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: serifAccent(26, t.ink)),
                      ),
                      CircleButton(icon: Icons.search_rounded, tooltip: 'Search', onTap: _toggleSearch),
                      const SizedBox(width: 10),
                      CircleButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Settings',
                        onTap: () => showSettings(context),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      if (!_searching)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.page + 2, 26, Insets.page, 4),
            child: PageTitle(
              overline: lib.loadedOnce
                  ? '${greeting(DateTime.now())} · ${formatCount(lib.shots.length, 'screenshot')}'
                  : 'Reading your screenshots…',
              lead: 'Your',
              accent: 'screenshots.',
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
        ),
    ];

    final leading = <Widget>[
      if (lib.isLimited)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.page, 18, Insets.page, 0),
            child: Panel(
              onTap: PhotoManager.openSetting,
              child: Row(children: [
                IconBadge(Icons.lock_outline_rounded, color: Brand.amber),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SnapSort sees only some photos', style: context.text.titleSmall),
                    Text('Tap to allow all of them', style: context.text.bodySmall),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: t.faint),
              ]),
            ),
          ),
        ),
      if (latest.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: SectionLabel('Latest', padding: EdgeInsets.fromLTRB(Insets.page + 2, 28, 0, 14)),
        ),
        SliverToBoxAdapter(child: _LatestRail(shots: latest)),
      ],
      if (lib.apps.length > 1 && !_searching)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: PillFilters<String>(
              options: [
                (null, 'All', null),
                for (final g in lib.apps.take(12)) (g.name, g.name, g.shots.length),
              ],
              selected: _app,
              onChanged: (v) => setState(() => _app = v),
            ),
          ),
        ),
    ];

    return SelectableShots(
      inTab: true,
      header: header,
      leading: leading,
      sections: sectionsByDate(gridShots),
      heroPrefix: 'grid',
      empty: !lib.loadedOnce
          ? const Center(child: CircularProgressIndicator())
          : (latest.isNotEmpty
              ? const SizedBox.shrink()
              : EmptyState(
                  icon: _searching || _app != null
                      ? Icons.search_off_rounded
                      : Icons.screenshot_monitor_rounded,
                  title: _searching || _app != null ? 'No matches' : 'No screenshots yet',
                  message: _searching || _app != null
                      ? 'Try another app name, file name or month.'
                      : 'SnapSort reads your phone\'s Screenshots folder. Take one and it shows up here.',
                )),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(children: [
      Expanded(
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: t.raised,
          ),
          child: Row(children: [
            const SizedBox(width: 18),
            Icon(Icons.search_rounded, color: t.muted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                style: context.text.titleSmall,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'App, file name or month',
                  hintStyle: context.text.titleSmall?.copyWith(color: t.faint),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      CircleButton(icon: Icons.close_rounded, tooltip: 'Close search', onTap: onClose),
    ]);
  }
}

/// Big swipeable cards for the newest screenshots.
class _LatestRail extends StatefulWidget {
  const _LatestRail({required this.shots});
  final List<Shot> shots;

  @override
  State<_LatestRail> createState() => _LatestRailState();
}

class _LatestRailState extends State<_LatestRail> {
  PageController? _controller;
  double _cardW = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cardW = (w * 0.4).clamp(140.0, 200.0);
    if (_controller == null || _cardW != cardW) {
      _controller?.dispose();
      _cardW = cardW;
      _controller = PageController(viewportFraction: (cardW + 14) / w);
    }
    final controller = _controller!;
    final shots = widget.shots;
    return SizedBox(
      height: cardW * 1.72,
      child: PageView.builder(
        controller: controller,
        padEnds: false,
        clipBehavior: Clip.none,
        itemCount: shots.length,
        itemBuilder: (context, i) {
          final s = shots[i];
          final card = _LatestCard(
            shot: s,
            onTap: () => Navigator.of(context).push(viewerRoute(
              (_) => ViewerPage(shots: shots, initialIndex: i, heroPrefix: 'rail'),
            )),
          );
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.hasClients && controller.position.haveDimensions
                  ? controller.page ?? 0.0
                  : 0.0;
              final d = (page - i).abs().clamp(0.0, 1.0);
              return Transform.scale(
                scale: 1 - 0.06 * d,
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: Insets.page),
              child: card
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (90 * i).ms)
                  .slideX(begin: 0.1, end: 0, duration: 600.ms, delay: (90 * i).ms, curve: Curves.easeOutCubic),
            ),
          );
        },
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.shot, required this.onTap});
  final Shot shot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(fit: StackFit.expand, children: [
          Hero(tag: 'rail-${shot.id}', child: RoundedShot(shot, radius: 26)),
          Positioned(
            left: 10,
            top: 10,
            child: Glass(
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: colorFor(shot.app), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(shot.app,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: Colors.white)),
                ),
              ]),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Glass(
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Text(_when(shot.date),
                  style: context.text.labelMedium?.copyWith(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  static String _when(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!d.isBefore(today)) return 'Today, ${timeOfDay(d)}';
    if (!d.isBefore(today.subtract(const Duration(days: 1)))) return 'Yesterday';
    return shortDate(d);
  }
}
