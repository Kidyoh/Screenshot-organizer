import 'package:flutter/material.dart';

import '../data/library.dart';
import '../data/shot.dart';
import 'scope.dart';
import 'shot_grid.dart';
import 'shots_scaffold.dart';

/// Screenshots grouped by the app they were taken in.
class AppsTab extends StatelessWidget {
  const AppsTab({super.key});

  static void openApp(BuildContext context, String app) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShotListPage(
        title: app,
        sections: (lib) => _byMonth(lib, app),
      ),
    ));
  }

  static List<Section> _byMonth(Library lib, String app) {
    final shots = lib.shots.where((s) => s.app == app).toList();
    final out = <Section>[];
    for (final s in shots) {
      final title = monthYear(s.date);
      if (out.isEmpty || out.last.title != title) out.add(Section(title, []));
      out.last.shots.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final apps = lib.apps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        actions: [
          if (apps.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(formatCount(apps.length, 'app')),
              ),
            ),
        ],
      ),
      body: apps.isEmpty
          ? (lib.loadedOnce
              ? const EmptyState(
                  icon: Icons.apps,
                  title: 'No apps yet',
                  message: 'Screenshots will be grouped here by the app they were taken in.',
                )
              : const Center(child: CircularProgressIndicator()))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.78,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: apps.length,
              itemBuilder: (context, i) => _AppCard(group: apps[i]),
            ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.group});
  final AppGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = group.shots.take(3).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppsTab.openApp(context, group.name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          child: i < preview.length
                              ? ShotThumb(preview[i])
                              : ColoredBox(
                                  color: theme.colorScheme.surfaceContainerHighest),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${group.shots.length} · ${formatBytes(group.totalSize)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
