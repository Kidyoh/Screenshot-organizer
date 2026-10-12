import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/library.dart';
import '../data/shot.dart';
import 'apps_tab.dart';
import 'scope.dart';
import 'shots_scaffold.dart';

/// Storage overview plus tools to find duplicates, old and big screenshots.
class CleanupTab extends StatefulWidget {
  const CleanupTab({super.key});

  @override
  State<CleanupTab> createState() => _CleanupTabState();
}

class _CleanupTabState extends State<CleanupTab> {
  int _ageDays = 90;

  static const _ages = {30: '30 days', 90: '3 months', 365: '1 year'};
  static const _biggestCount = 60;

  void _review({
    required String title,
    required List<Section> Function(Library lib) sections,
    Set<int> preselect = const {},
    String? hint,
    String empty = 'Nothing left to clean up here.',
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShotListPage(
        title: title,
        sections: (lib) => sections(lib),
        initialSelection: preselect,
        hint: hint,
        emptyMessage: empty,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final theme = Theme.of(context);
    final old = lib.olderThan(Duration(days: _ageDays));
    final oldSize = old.fold<int>(0, (n, s) => n + s.size);
    final biggest = lib.largerThan(0).take(_biggestCount).toList();
    final biggestSize = biggest.fold<int>(0, (n, s) => n + s.size);
    final dupes = lib.duplicateGroups;
    final extraCopies = dupes?.fold<int>(0, (n, g) => n + g.length - 1) ?? 0;
    final extraSize = dupes?.fold<int>(
            0, (n, g) => n + g.skip(1).fold<int>(0, (m, s) => m + s.size)) ??
        0;
    final topApps = [...lib.apps]..sort((a, b) => b.totalSize.compareTo(a.totalSize));
    final maxAppSize = topApps.isEmpty ? 1 : math.max(1, topApps.first.totalSize);

    return Scaffold(
      appBar: AppBar(title: const Text('Clean up')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatBytes(lib.totalSize),
                      style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${formatCount(lib.shots.length, 'screenshot')} from ${formatCount(lib.apps.length, 'app')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (lib.shots.isNotEmpty)
                    Text('Oldest from ${shortDate(lib.shots.last.date)}',
                        style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Duplicates
          _ToolCard(
            icon: Icons.copy_all_outlined,
            title: 'Exact duplicates',
            body: lib.scanningDuplicates
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comparing files…'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: lib.duplicateProgress),
                    ],
                  )
                : Text(dupes == null
                    ? 'Find screenshots that are byte-for-byte identical copies.'
                    : dupes.isEmpty
                        ? 'No duplicates found. Nice and tidy!'
                        : '${formatCount(extraCopies, 'extra copy')} in ${formatCount(dupes.length, 'group')} · ${formatBytes(extraSize)} to free'),
            action: lib.scanningDuplicates
                ? null
                : dupes == null || dupes.isEmpty
                    ? FilledButton.tonal(
                        onPressed: lib.shots.isEmpty ? null : lib.scanDuplicates,
                        child: Text(dupes == null ? 'Scan' : 'Scan again'),
                      )
                    : FilledButton(
                        onPressed: () => _review(
                          title: 'Duplicates',
                          sections: (lib) => [
                            for (final g in lib.duplicateGroups ?? <List<Shot>>[])
                              Section('${g.length} copies', g,
                                  subtitle: '${g.length} × ${formatBytes(g.first.size)}'),
                          ],
                          preselect: {
                            for (final g in dupes) ...g.skip(1).map((s) => s.id),
                          },
                          hint: 'The oldest copy in each group is kept; the extra copies are selected.',
                          empty: 'No duplicates left.',
                        ),
                        child: const Text('Review'),
                      ),
          ),

          // Old
          _ToolCard(
            icon: Icons.history,
            title: 'Old screenshots',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in _ages.entries)
                      ButtonSegment(value: e.key, label: Text(e.value)),
                  ],
                  selected: {_ageDays},
                  onSelectionChanged: (v) => setState(() => _ageDays = v.first),
                ),
                const SizedBox(height: 8),
                Text(old.isEmpty
                    ? 'Nothing older than ${_ages[_ageDays]}.'
                    : '${formatCount(old.length, 'screenshot')} older than ${_ages[_ageDays]} · ${formatBytes(oldSize)}'),
              ],
            ),
            action: old.isEmpty
                ? null
                : FilledButton.tonal(
                    onPressed: () {
                      final age = Duration(days: _ageDays);
                      _review(
                        title: 'Older than ${_ages[_ageDays]}',
                        sections: (lib) => sectionsByDate(lib.olderThan(age)),
                        preselect: old.map((s) => s.id).toSet(),
                        hint: 'All selected. Untick anything you want to keep.',
                      );
                    },
                    child: const Text('Review'),
                  ),
          ),

          // Biggest
          _ToolCard(
            icon: Icons.photo_size_select_large,
            title: 'Biggest files',
            body: Text(biggest.isEmpty
                ? 'No screenshots yet.'
                : 'Your ${biggest.length} largest screenshots take up ${formatBytes(biggestSize)}.'),
            action: biggest.isEmpty
                ? null
                : FilledButton.tonal(
                    onPressed: () => _review(
                      title: 'Biggest files',
                      sections: (lib) {
                        final list = lib.largerThan(0).take(_biggestCount).toList();
                        return [
                          if (list.isNotEmpty)
                            Section('Largest first', list),
                        ];
                      },
                    ),
                    child: const Text('Review'),
                  ),
          ),

          // Storage by app
          if (topApps.isNotEmpty)
            _ToolCard(
              icon: Icons.pie_chart_outline,
              title: 'Space by app',
              body: Column(
                children: [
                  for (final g in topApps.take(6))
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => AppsTab.openApp(context, g.name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(g.name,
                                      overflow: TextOverflow.ellipsis)),
                              Text(formatBytes(g.totalSize),
                                  style: theme.textTheme.bodySmall),
                            ]),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: g.totalSize / maxAppSize,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?action,
            ]),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}
