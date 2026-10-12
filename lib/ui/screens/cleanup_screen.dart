import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/routes.dart';
import '../../data/library.dart';
import '../../data/shot.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import 'apps_screen.dart';
import 'group_screen.dart';

/// Storage overview plus tools for duplicates, old and big screenshots.
class CleanupScreen extends StatefulWidget {
  const CleanupScreen({super.key});

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  int _ageDays = 90;
  static const _ages = {30: '30 days', 90: '3 months', 365: '1 year'};
  static const _biggestCount = 40;

  void _review({
    required String title,
    required List<Section> Function(Library lib) sections,
    Set<int> preselect = const {},
    String? hint,
    String empty = 'Nothing left to clean up here.',
  }) {
    Navigator.of(context).push(pageRoute((_) => GroupScreen(
          title: title,
          overline: 'Review',
          sections: sections,
          initialSelection: preselect,
          hint: hint,
          emptyMessage: empty,
        )));
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final old = lib.olderThan(Duration(days: _ageDays));
    final oldSize = old.fold<int>(0, (n, s) => n + s.size);
    final biggest = lib.largerThan(0).take(_biggestCount).toList();
    final biggestSize = biggest.fold<int>(0, (n, s) => n + s.size);
    final dupes = lib.duplicateGroups;
    final extra = dupes?.fold<int>(0, (n, g) => n + g.length - 1) ?? 0;
    final extraSize =
        dupes?.fold<int>(0, (n, g) => n + g.skip(1).fold<int>(0, (m, s) => m + s.size)) ?? 0;

    final cards = <Widget>[
      _StorageHero(lib: lib),
      _ToolCard(
        icon: Icons.copy_all_rounded,
        color: Brand.violet,
        title: 'Exact duplicates',
        figure: dupes == null || dupes.isEmpty ? null : formatBytes(extraSize),
        caption: lib.scanningDuplicates
            ? 'Comparing files…'
            : dupes == null
                ? 'Find screenshots saved more than once, byte for byte.'
                : dupes.isEmpty
                    ? 'No duplicates. Nice and tidy!'
                    : '$extra extra ${extra == 1 ? 'copy' : 'copies'} you can let go',
        progress: lib.scanningDuplicates ? lib.duplicateProgress : null,
        action: lib.scanningDuplicates
            ? null
            : dupes == null || dupes.isEmpty
                ? PillButton(
                    label: dupes == null ? 'Scan' : 'Scan again',
                    style: PillStyle.ink,
                    height: 42,
                    expand: false,
                    onTap: lib.shots.isEmpty ? null : lib.scanDuplicates,
                  )
                : PillButton(
                    label: 'Review',
                    height: 42,
                    expand: false,
                    onTap: () => _review(
                      title: 'Duplicates',
                      sections: (lib) => [
                        for (final g in lib.duplicateGroups ?? <List<Shot>>[])
                          Section('${g.length} copies', g, subtitle: formatBytes(g.first.size)),
                      ],
                      preselect: {for (final g in dupes) ...g.skip(1).map((s) => s.id)},
                      hint: 'The oldest copy of each is kept. The extra copies are already selected.',
                      empty: 'No duplicates left.',
                    ),
                  ),
      ),
      _ToolCard(
        icon: Icons.history_rounded,
        color: Brand.amber,
        title: 'Old screenshots',
        figure: old.isEmpty ? null : formatBytes(oldSize),
        caption: old.isEmpty
            ? 'Nothing older than ${_ages[_ageDays]}.'
            : '${formatCount(old.length, 'screenshot')} older than ${_ages[_ageDays]}',
        extra: PillTabs<int>(
          values: _ages.keys.toList(),
          labelOf: (d) => _ages[d]!,
          selected: _ageDays,
          height: 42,
          onChanged: (d) => setState(() => _ageDays = d),
        ),
        action: old.isEmpty
            ? null
            : PillButton(
                label: 'Review',
                height: 42,
                expand: false,
                onTap: () {
                  final age = Duration(days: _ageDays);
                  _review(
                    title: 'Older than ${_ages[_ageDays]}',
                    sections: (lib) => sectionsByDate(lib.olderThan(age)),
                    preselect: old.map((s) => s.id).toSet(),
                    hint: 'All selected. Untick anything you want to keep.',
                  );
                },
              ),
      ),
      _ToolCard(
        icon: Icons.photo_size_select_large_rounded,
        color: Brand.coral,
        title: 'Biggest files',
        figure: biggest.isEmpty ? null : formatBytes(biggestSize),
        caption: biggest.isEmpty
            ? 'No screenshots yet.'
            : 'taken up by your ${biggest.length} largest',
        action: biggest.isEmpty
            ? null
            : PillButton(
                label: 'Review',
                height: 42,
                expand: false,
                onTap: () => _review(
                  title: 'Biggest files',
                  sections: (lib) {
                    final list = lib.largerThan(0).take(_biggestCount).toList();
                    return [if (list.isNotEmpty) Section('Largest first', list)];
                  },
                ),
              ),
      ),
    ];

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Insets.page + 2, pad.top + 30, Insets.page, 22),
          child: PageTitle(
            overline: 'Free up space',
            lead: 'Clean',
            accent: 'up.',
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, Insets.navClearance + pad.bottom),
        sliver: SliverList.separated(
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: Insets.gap),
          itemBuilder: (context, i) => cards[i]
              .animate()
              .fadeIn(duration: 450.ms, delay: (70 * i).ms)
              .slideY(begin: 0.06, end: 0, duration: 500.ms, delay: (70 * i).ms, curve: Curves.easeOutCubic),
        ),
      ),
    ]);
  }
}

/// Dark card: total size, split by app.
class _StorageHero extends StatelessWidget {
  const _StorageHero({required this.lib});
  final Library lib;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = lib.totalSize;
    final top = ([...lib.apps]..sort((a, b) => b.totalSize.compareTo(a.totalSize)))
        .where((g) => g.name != Shot.otherApp)
        .take(4)
        .toList();
    final rest = total - top.fold<int>(0, (n, g) => n + g.totalSize);
    final (value, unit) = _split(total);
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: t.hero,
        borderRadius: BorderRadius.circular(Insets.radius),
        border: context.isDark ? Border.all(color: t.border) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SCREENSHOTS TAKE UP',
            style: context.text.labelSmall?.copyWith(color: white.withValues(alpha: 0.55))),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          CountUp(
            value: value,
            format: (v) => v.toStringAsFixed(value >= 100 ? 0 : 1),
            style: context.text.displaySmall?.copyWith(color: white, fontSize: 54, letterSpacing: -2.4),
          ),
          const SizedBox(width: 8),
          Text(unit, style: serifAccent(30, white.withValues(alpha: 0.75))),
        ]),
        const SizedBox(height: 4),
        Text(
          lib.shots.isEmpty
              ? 'No screenshots yet'
              : '${formatCount(lib.shots.length, 'screenshot')} since ${shortDate(lib.shots.last.date)}',
          style: context.text.bodyMedium?.copyWith(color: white.withValues(alpha: 0.65)),
        ),
        if (total > 0) ...[
          const SizedBox(height: 20),
          SegmentBar(
            height: 14,
            track: white.withValues(alpha: 0.1),
            parts: [
              for (final g in top) (g.totalSize / total, colorFor(g.name)),
              if (rest > 0) (rest / total, white.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 14, runSpacing: 8, children: [
            for (final g in top)
              _Legend(color: colorFor(g.name), label: g.name, value: formatBytes(g.totalSize),
                  onTap: () => openApp(context, g.name)),
            if (rest > 0)
              _Legend(color: white.withValues(alpha: 0.3), label: 'Everything else', value: formatBytes(rest)),
          ]),
        ],
      ]),
    );
  }

  static (double, String) _split(int bytes) {
    if (bytes < 1024 * 1024) return (bytes / 1024, 'KB');
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024), 'MB');
    return (bytes / (1024 * 1024 * 1024), 'GB');
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value, this.onTap});
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 5),
          Text(value,
              style: context.text.labelMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    this.figure,
    this.action,
    this.extra,
    this.progress,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String caption;
  final String? figure;
  final Widget? action;
  final Widget? extra;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBadge(icon, color: color),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: context.text.titleMedium)),
        ]),
        if (extra != null) ...[const SizedBox(height: 16), extra!],
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (figure != null)
                Text(figure!, style: context.text.headlineMedium?.copyWith(fontSize: 34)),
              Text(caption, style: context.text.bodyMedium?.copyWith(color: t.muted)),
            ]),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ]),
        if (progress != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 8, color: color),
          ),
        ],
      ]),
    );
  }
}
