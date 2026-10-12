import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/shot.dart';
import 'scope.dart';
import 'shot_grid.dart';
import 'shots_scaffold.dart';

/// Every screenshot, newest first, with quick app filters and search.
class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  final _search = TextEditingController();
  bool _searching = false;
  String? _app;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    var shots = _searching ? lib.search(_search.text) : lib.shots;
    if (_app != null) shots = shots.where((s) => s.app == _app).toList();
    final topApps = lib.apps.take(12).toList();

    return ShotsScaffold(
      sections: sectionsByDate(shots),
      title: 'SnapSort',
      subtitle: lib.loadedOnce
          ? '${formatCount(lib.shots.length, 'screenshot')} · ${formatBytes(lib.totalSize)}'
          : 'Reading your screenshots…',
      titleWidget: _searching
          ? TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by app, file name or month',
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            )
          : null,
      actions: [
        IconButton(
          tooltip: _searching ? 'Close search' : 'Search',
          icon: Icon(_searching ? Icons.close : Icons.search),
          onPressed: () => setState(() {
            _searching = !_searching;
            _search.clear();
          }),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: lib.loading
              ? const SizedBox.square(
                  dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
          onPressed: lib.loading ? null : lib.refresh,
        ),
      ],
      leading: [
        if (lib.isLimited)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('SnapSort can only see some photos'),
                  subtitle: const Text('Tap to allow access to all of them.'),
                  onTap: () async {
                    await PhotoManager.openSetting();
                  },
                ),
              ),
            ),
          ),
        if (topApps.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _chip('All', null, lib.shots.length),
                  for (final g in topApps) _chip(g.name, g.name, g.shots.length),
                ],
              ),
            ),
          ),
      ],
      empty: !lib.loadedOnce
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              icon: _searching || _app != null
                  ? Icons.search_off
                  : Icons.screenshot_monitor_outlined,
              title: _searching || _app != null
                  ? 'No matches'
                  : 'No screenshots yet',
              message: _searching || _app != null
                  ? 'Try a different search or filter.'
                  : 'SnapSort looks in your phone\'s Screenshots folder. '
                      'Take a screenshot and it will show up here.',
            ),
    );
  }

  Widget _chip(String label, String? app, int count) {
    final selected = _app == app;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label  $count'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _app = selected ? null : app),
      ),
    );
  }
}
