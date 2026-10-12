import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/routes.dart';
import '../../data/shot.dart';
import '../actions.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import '../widgets/shots.dart';
import 'apps_screen.dart';
import 'group_screen.dart';

/// Favourites plus the person's own albums.
class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final lib = LibraryScope.read(context);
    final name = await askForName(context, title: 'New', accent: 'album', action: 'Create');
    if (name == null || !context.mounted) return;
    if (!lib.createAlbum(name) && name.trim().isNotEmpty) {
      showSnack(context, 'You already have an album called that', icon: Icons.info_outline_rounded);
    }
  }

  void _openAlbum(BuildContext context, String name) {
    Navigator.of(context).push(pageRoute((_) => GroupScreen(
          title: name,
          overline: 'Album',
          dot: colorFor(name),
          album: name,
          sections: (lib) => [
            if (lib.albumShots(name).isNotEmpty) Section('Newest first', lib.albumShots(name)),
          ],
          emptyMessage: 'Long-press screenshots anywhere in SnapSort, then tap Album to add them here.',
        )));
  }

  Future<void> _albumMenu(BuildContext context, String name) async {
    final lib = LibraryScope.read(context);
    final action = await showAppSheet<String>(context, (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeading(title: name, message: formatCount(lib.albumShots(name).length, 'screenshot')),
            PillButton(
              label: 'Rename',
              icon: Icons.edit_outlined,
              style: PillStyle.soft,
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Delete album',
              icon: Icons.delete_outline_rounded,
              style: PillStyle.danger,
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ));
    if (!context.mounted) return;
    if (action == 'rename') {
      final to = await askForName(context, title: 'Rename', accent: 'album', initial: name);
      if (to != null && context.mounted && to.trim() != name && !lib.renameAlbum(name, to)) {
        showSnack(context, 'Couldn\'t rename to "$to"', icon: Icons.info_outline_rounded);
      }
    } else if (action == 'delete') {
      if (await confirm(context,
          title: 'Delete',
          accent: 'album?',
          message: 'The screenshots in "$name" stay on your phone.',
          action: 'Delete album')) {
        lib.deleteAlbum(name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final names = lib.albums.keys.toList();
    final favorites = lib.favoriteShots;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Insets.page + 2, pad.top + 30, Insets.page, 0),
          child: PageTitle(
            overline: names.isEmpty ? 'Collect what matters' : formatCount(names.length, 'album'),
            lead: 'Your',
            accent: 'albums.',
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.page, 22, Insets.page, 0),
          child: _FavoritesCard(
            shots: favorites,
            onTap: () => Navigator.of(context).push(pageRoute((_) => GroupScreen(
                  title: 'Favorites',
                  overline: 'Album',
                  dot: Brand.coral,
                  sections: (lib) => [
                    if (lib.favoriteShots.isNotEmpty) Section('Newest first', lib.favoriteShots),
                  ],
                  emptyMessage: 'Tap the heart on any screenshot to keep it here.',
                ))),
          ).animate().fadeIn(duration: 450.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
      const SliverToBoxAdapter(
        child: SectionLabel('Your albums', padding: EdgeInsets.fromLTRB(Insets.page + 2, 30, 0, 14)),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, Insets.navClearance + pad.bottom),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.8,
            mainAxisSpacing: Insets.gap,
            crossAxisSpacing: Insets.gap,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == names.length) return _NewAlbumCard(onTap: () => _create(context));
              final name = names[i];
              final shots = lib.albumShots(name);
              return GroupCard(
                key: ValueKey(name),
                name: name,
                shots: shots,
                icon: Icons.photo_album_outlined,
                detail: formatCount(shots.length, 'screenshot'),
                onTap: () => _openAlbum(context, name),
                onLongPress: () => _albumMenu(context, name),
              ).animate().fadeIn(duration: 400.ms, delay: (40 * (i % 10)).ms);
            },
            childCount: names.length + 1,
          ),
        ),
      ),
    ]);
  }
}

class _FavoritesCard extends StatelessWidget {
  const _FavoritesCard({required this.shots, required this.onTap});
  final List<Shot> shots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 176),
        padding: const EdgeInsets.fromLTRB(22, 20, 12, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Brand.coral, Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Insets.radius),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 34),
                Text('Favorites', style: serifAccent(34, Colors.white)),
                const SizedBox(height: 4),
                Text(
                  shots.isEmpty ? 'Tap ♥ on a screenshot' : formatCount(shots.length, 'screenshot'),
                  style: context.text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          if (shots.isNotEmpty) FannedStack(shots: shots, cardWidth: 54),
        ]),
      ),
    );
  }
}

class _NewAlbumCard extends StatelessWidget {
  const _NewAlbumCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: CustomPaint(
        painter: _DashedBorder(color: t.faint, radius: Insets.radius),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(gradient: Brand.gradient, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text('New album', style: context.text.titleSmall),
          ]),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)).deflate(1));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
