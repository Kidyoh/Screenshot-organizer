import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/routes.dart';
import '../../data/shot.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/shots.dart';
import 'group_screen.dart';

enum AppSort { most, size, name }

void openApp(BuildContext context, String app) {
  Navigator.of(context).push(pageRoute((_) => GroupScreen(
        title: app,
        overline: 'App',
        dot: colorFor(app),
        sections: (lib) => _byMonth(lib.shots.where((s) => s.app == app)),
      )));
}

List<Section> _byMonth(Iterable<Shot> shots) {
  final out = <Section>[];
  for (final s in shots) {
    final title = monthYear(s.date);
    if (out.isEmpty || out.last.title != title) out.add(Section(title, []));
    out.last.shots.add(s);
  }
  return out;
}

/// Screenshots grouped by the app they were taken in.
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  AppSort _sort = AppSort.most;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final apps = [...lib.apps];
    switch (_sort) {
      case AppSort.most:
        break; // library order: most screenshots first, "Other" last
      case AppSort.size:
        apps.sort((a, b) => b.totalSize.compareTo(a.totalSize));
      case AppSort.name:
        apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Insets.page + 2, pad.top + 30, Insets.page, 0),
          child: PageTitle(
            overline: lib.loadedOnce ? formatCount(apps.length, 'app') : null,
            lead: 'Sorted by',
            accent: 'app.',
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      ),
      if (apps.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.page, 22, Insets.page, 6),
            child: PillTabs<AppSort>(
              values: AppSort.values,
              labelOf: (s) => switch (s) {
                AppSort.most => 'Most',
                AppSort.size => 'Biggest',
                AppSort.name => 'A–Z',
              },
              selected: _sort,
              onChanged: (s) => setState(() => _sort = s),
            ),
          ),
        ),
      if (apps.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: lib.loadedOnce
              ? const EmptyState(
                  icon: Icons.apps_rounded,
                  title: 'No apps yet',
                  message: 'Your screenshots get grouped here by the app you took them in.',
                )
              : const Center(child: CircularProgressIndicator()),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Insets.page, 14, Insets.page, Insets.navClearance + pad.bottom),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.8,
              mainAxisSpacing: Insets.gap,
              crossAxisSpacing: Insets.gap,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GroupCard(
                key: ValueKey(apps[i].name),
                name: apps[i].name,
                shots: apps[i].shots,
                detail: '${apps[i].shots.length} · ${formatBytes(apps[i].totalSize)}',
                onTap: () => openApp(context, apps[i].name),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (40 * (i % 10)).ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              childCount: apps.length,
            ),
          ),
        ),
    ]);
  }
}

/// A tinted card with a fanned stack of screenshots, for apps and albums.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.name,
    required this.shots,
    required this.detail,
    required this.onTap,
    this.onLongPress,
    this.icon,
  });

  final String name;
  final List<Shot> shots;
  final String detail;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(name);
    final t = context.tokens;
    return Panel(
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: wash(color, context),
              borderRadius: BorderRadius.circular(Insets.radius - 8),
            ),
            child: Center(
              child: shots.isEmpty && icon != null
                  ? Icon(icon, size: 40, color: color)
                  : FittedBox(child: FannedStack(shots: shots)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: t.muted)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
